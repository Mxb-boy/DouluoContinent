--[[
    DropCleanupSystem: 掉落物自动清理系统（集中扫描版 v2）
    - 始终只有 1 个循环定时器，每 SCAN_INTERVAL 秒扫描 TrackedPickups
    - 扫描只遍历已追踪的掉落物（纯 Lua table 遍历），不做全场景搜索
    - 兜底全场景搜索降频到每 SAFETY_SCAN_RATIO 次常规扫描才执行 1 次
    - 超时统一销毁；超过 MAX_PICKUPS 时强制清理最旧的
    - 安全规则：不在遍历 UE TArray 时调用 K2_DestroyActor，先收集后销毁
    - 优化：用 os.clock() 记录高精度时间戳；维护实时计数避免遍历计数
]]
local DropCleanupSystem = {}

-- 已追踪的掉落物（weak-keyed，避免阻止 GC）
-- value = 加入时间戳（os.clock()，秒级浮点精度）
DropCleanupSystem.TrackedPickups = setmetatable({}, { __mode = "k" })
DropCleanupSystem.MAX_AGE = 180
DropCleanupSystem.SCAN_INTERVAL = 10        -- 集中扫描间隔（秒），替代每对象定时器
DropCleanupSystem.SCAN_RANGE = 1500
DropCleanupSystem.MAX_PICKUPS = 999
DropCleanupSystem.SAFETY_RANGE = 100000
DropCleanupSystem.MAX_PENDING_LOCATIONS = 24
-- 兜底全场景搜索降频：每 SAFETY_SCAN_RATIO 次常规扫描才做 1 次（= 每 60 秒）

-- 实时计数（避免每次扫描都遍历 pairs 计数）

-- 常规扫描计数器（用于触发降频兜底）

-- ScheduleDropCleanup 去抖动：合并短时间内的多次掉落为一次扫描
DropCleanupSystem.SafetyScanPawnIndex = 1

--- 将 UE 返回的 TArray 复制为纯 Lua table，防止遍历时数组被引擎修改
local function CopyToArray(ueArray)
    if ueArray == nil then
        return {}
    end
    local copy = {}
    for _, item in ipairs(ueArray) do
        table.insert(copy, item)
    end
    return copy
end

--- 在指定位置附近查找掉落物并加入追踪列表
---@param location FVector 掉落位置
local function CopyToArrayLimited(ueArray, maxCount)
    if ueArray == nil then
        return {}
    end
    local copy = {}
    local count = 0
    local limit = tonumber(maxCount) or DropCleanupSystem.MAX_WRAPPERS_PER_SCAN
    for _, item in ipairs(ueArray) do
        count = count + 1
        if count > limit then
            break
        end
        table.insert(copy, item)
    end
    return copy
end

local function TrackWrappersNearLocation(location, scanRange)
    if location == nil then
        return
    end

    local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(location, scanRange)
    if wrappers == nil then
        return
    end

    local wrapperCopy = CopyToArrayLimited(wrappers, DropCleanupSystem.MAX_WRAPPERS_PER_SCAN)
    for _, wrapper in ipairs(wrapperCopy) do
        if wrapper and UE.IsValid(wrapper) and DropCleanupSystem.TrackedPickups[wrapper] == nil then
            DropCleanupSystem.TrackedPickups[wrapper] = os.time()
        end
    end
end

function DropCleanupSystem.RunPendingDiscovery()
    DropCleanupSystem.DiscoveryTimerActive = false

    local processed = 0
    while processed < DropCleanupSystem.MAX_LOCATIONS_PER_DISCOVERY and #DropCleanupSystem.PendingLocations > 0 do
        local location = table.remove(DropCleanupSystem.PendingLocations, 1)
        TrackWrappersNearLocation(location, DropCleanupSystem.SCAN_RANGE)
        processed = processed + 1
    end

    if #DropCleanupSystem.PendingLocations > 0 then
        DropCleanupSystem.ScheduleDiscoveryTimer()
    end
end

function DropCleanupSystem.ScheduleDiscoveryTimer()
    if DropCleanupSystem.DiscoveryTimerActive then
        return
    end

    DropCleanupSystem.DiscoveryTimerActive = true
    UGCTimerUtility.RemoveLuaTimerByName(DropCleanupSystem.DiscoveryTimerName)
    UGCTimerUtility.CreateLuaTimer(1, function()
        UGCTimerUtility.RemoveLuaTimerByName(DropCleanupSystem.DiscoveryTimerName)
        DropCleanupSystem.RunPendingDiscovery()
    end, true, DropCleanupSystem.DiscoveryTimerName)
end

function DropCleanupSystem.ScheduleDropCleanup(location)
    if location == nil then
        return
    end

    table.insert(DropCleanupSystem.PendingLocations, location)
    while #DropCleanupSystem.PendingLocations > DropCleanupSystem.MAX_PENDING_LOCATIONS do
        table.remove(DropCleanupSystem.PendingLocations, 1)
    end
    DropCleanupSystem.ScheduleDiscoveryTimer()
    return

    -- 去抖动：合并 1 秒内的多次掉落请求为一次扫描
    if DropCleanupSystem.PendingDropLocations == nil then
        DropCleanupSystem.PendingDropLocations = {}
    end
    table.insert(DropCleanupSystem.PendingDropLocations, location)

    if DropCleanupSystem.DebounceTimerActive then
        return  -- 已有待执行的延迟扫描，不重复创建定时器
    end
    DropCleanupSystem.DebounceTimerActive = true

    UGCTimerUtility.CreateLuaTimer(1, function()
        DropCleanupSystem.DebounceTimerActive = false
        local locations = DropCleanupSystem.PendingDropLocations
        DropCleanupSystem.PendingDropLocations = nil
        if locations == nil then
            return
        end

        for _, loc in ipairs(locations) do
            local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(loc, DropCleanupSystem.SCAN_RANGE)
            if wrappers then
                local wrapperCopy = CopyToArray(wrappers)
                for _, wrapper in ipairs(wrapperCopy) do
                    if wrapper and UE.IsValid(wrapper) and DropCleanupSystem.TrackedPickups[wrapper] == nil then
                        DropCleanupSystem.TrackedPickups[wrapper] = os.clock()
                        DropCleanupSystem.LiveCount = DropCleanupSystem.LiveCount + 1
                    end
                end
            end
        end
    end, false)
end

--- 直接追踪已生成的掉落物 Actor（用于 SpawnPickupWrapper 返回值）
---@param pickupActor userdata 掉落物 Actor
function DropCleanupSystem.TrackPickup(pickupActor)
    if pickupActor == nil or not UE.IsValid(pickupActor) then
        return
    end
    if DropCleanupSystem.TrackedPickups[pickupActor] ~= nil then
        return
    end
    DropCleanupSystem.TrackedPickups[pickupActor] = os.clock()
    DropCleanupSystem.LiveCount = DropCleanupSystem.LiveCount + 1
end

--- 启动集中式扫描定时器（唯一的循环定时器）
function DropCleanupSystem.StartSafetyValveTimer()
    UGCTimerUtility.CreateLuaTimer(DropCleanupSystem.SCAN_INTERVAL, function()
        DropCleanupSystem.SafetyValveScan()
    end, true, "DropCleanupSafetyValve")
end

--- 集中扫描：超时销毁 + 超阈值强制清理 + 降频兜底发现未追踪的掉落物
--- 安全规则：所有 K2_DestroyActor 调用都在遍历结束后统一执行
function DropCleanupSystem.SafetyValveScan()
    local now = os.clock()

    -- 快速路径：场上无掉落物时直接跳过（含兜底扫描）
    if DropCleanupSystem.LiveCount == 0 then
        -- LiveCount 为 0 但 TrackedPickups 可能有已被 GC 的弱引用残留，清理一下
        if next(DropCleanupSystem.TrackedPickups) ~= nil then
            for pickup in pairs(DropCleanupSystem.TrackedPickups) do
                if pickup == nil or not UE.IsValid(pickup) then
                    DropCleanupSystem.TrackedPickups[pickup] = nil
                end
            end
        end
        return
    end

    local livePickups = {}
    local toDestroy = {}  -- 先收集要销毁的 Actor，遍历完后再统一销毁
    local liveCount = 0

    -- 1. 收集已超时的掉落物（纯 Lua table 遍历，不调用引擎搜索）
    for pickup, trackTime in pairs(DropCleanupSystem.TrackedPickups) do
        if pickup == nil or not UE.IsValid(pickup) then
            -- Actor 已被引擎回收，从追踪表中移除
            DropCleanupSystem.TrackedPickups[pickup] = nil
        elseif now - trackTime >= DropCleanupSystem.MAX_AGE then
            -- 超时，加入待销毁列表
            table.insert(toDestroy, pickup)
            DropCleanupSystem.TrackedPickups[pickup] = nil
        else
            livePickups[pickup] = trackTime
            liveCount = liveCount + 1
        end
    end

    -- 2. 降频兜底：每 SAFETY_SCAN_RATIO 次常规扫描才做 1 次全场景搜索
    --    大部分情况下跳过，避免每 10 秒做 N 次全图 FindPickupWrapperActorByRange
    DropCleanupSystem.ScanTickCount = DropCleanupSystem.ScanTickCount + 1
    if DropCleanupSystem.ScanTickCount >= DropCleanupSystem.SAFETY_SCAN_RATIO then
        DropCleanupSystem.ScanTickCount = 0
        DropCleanupSystem.SafetyNetScan(livePickups, liveCount)
        -- 兜底扫描可能新增了掉落物，重新计数
        liveCount = 0
        for _ in pairs(livePickups) do
            liveCount = liveCount + 1
        end
    end

    -- 3. 超阈值强制清理最旧的（也加入 toDestroy，不在此处销毁）
    if liveCount > DropCleanupSystem.MAX_PICKUPS then
        -- 按 trackTime 从小到大排序，先销毁最旧的
        local sorted = {}
        for pickup, trackTime in pairs(livePickups) do
            table.insert(sorted, { actor = pickup, time = trackTime })
        end
        table.sort(sorted, function(a, b)
            return a.time < b.time
        end)

        local excess = liveCount - DropCleanupSystem.MAX_PICKUPS
        for i = 1, math.min(excess, #sorted) do
            local pickup = sorted[i].actor
            table.insert(toDestroy, pickup)
            DropCleanupSystem.TrackedPickups[pickup] = nil
        end
        liveCount = liveCount - math.min(excess, #sorted)
    end

    -- 4. 统一销毁：在所有遍历结束之后，逐个销毁待清理的 Actor
    for _, pickup in ipairs(toDestroy) do
        if pickup and UE.IsValid(pickup) then
            pickup:K2_DestroyActor()
        end
    end

    -- 更新实时计数
    DropCleanupSystem.LiveCount = liveCount
end

--- 兜底扫描：以玩家为中心搜索未追踪的掉落物（降频调用）
function DropCleanupSystem.SafetyNetScan(livePickups, currentCount)
    local allPawns = UGCGameSystem.GetAllPlayerPawn()
    local pawnCopy = CopyToArray(allPawns)
    if #pawnCopy > 0 then
        if DropCleanupSystem.SafetyScanPawnIndex > #pawnCopy then
            DropCleanupSystem.SafetyScanPawnIndex = 1
        end
        local selectedPawn = pawnCopy[DropCleanupSystem.SafetyScanPawnIndex]
        DropCleanupSystem.SafetyScanPawnIndex = DropCleanupSystem.SafetyScanPawnIndex + 1
        pawnCopy = { selectedPawn }
    end
    for _, pawn in ipairs(pawnCopy) do
        if pawn and UE.IsValid(pawn) then
            local location = pawn:K2_GetActorLocation()
            if location then
                local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(
                    location, DropCleanupSystem.SAFETY_RANGE)
                if wrappers then
                    local wrapperCopy = CopyToArrayLimited(wrappers, DropCleanupSystem.MAX_WRAPPERS_PER_SCAN)
                    for _, wrapper in ipairs(wrapperCopy) do
                        if wrapper and UE.IsValid(wrapper) then
                            if DropCleanupSystem.TrackedPickups[wrapper] == nil then
                                DropCleanupSystem.TrackPickup(wrapper)
                                livePickups[wrapper] = os.clock()
                            end
                        end
                    end
                end
            end
        end
    end
end

return DropCleanupSystem
