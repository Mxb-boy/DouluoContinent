--[[
    DropCleanupSystem: 掉落物自动清理系统（集中扫描版）
    - 不再为每个掉落物创建独立定时器，改为集中扫描统一清理
    - 每 SCAN_INTERVAL 秒扫描一次 TrackedPickups，超时的统一销毁
    - 超过 MAX_PICKUPS 时强制清理最旧的
    - 这样无论有多少掉落物，始终只有 1 个扫描定时器
    - 安全规则：不在遍历 UE TArray 时调用 K2_DestroyActor，先收集后销毁
]]
local DropCleanupSystem = {}

-- 已追踪的掉落物（weak-keyed，避免阻止 GC）
-- value = 加入时间戳（os.time()）
DropCleanupSystem.TrackedPickups = setmetatable({}, { __mode = "k" })
DropCleanupSystem.MAX_AGE = 180
DropCleanupSystem.SCAN_INTERVAL = 10        -- 集中扫描间隔（秒），替代每对象定时器
DropCleanupSystem.SCAN_RANGE = 1500
DropCleanupSystem.MAX_PICKUPS = 80
DropCleanupSystem.SAFETY_RANGE = 100000

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
function DropCleanupSystem.ScheduleDropCleanup(location)
    if location == nil then
        return
    end

    UGCTimerUtility.CreateLuaTimer(1, function()
        local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(location, DropCleanupSystem.SCAN_RANGE)
        if wrappers == nil then
            return
        end

        -- 先复制到 Lua table 再遍历，避免遍历 UE TArray 时数组变化
        local wrapperCopy = CopyToArray(wrappers)
        for _, wrapper in ipairs(wrapperCopy) do
            if wrapper and UE.IsValid(wrapper) and DropCleanupSystem.TrackedPickups[wrapper] == nil then
                DropCleanupSystem.TrackedPickups[wrapper] = os.time()
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
    DropCleanupSystem.TrackedPickups[pickupActor] = os.time()
end

--- 启动集中式扫描定时器（唯一的循环定时器）
function DropCleanupSystem.StartSafetyValveTimer()
    UGCTimerUtility.CreateLuaTimer(DropCleanupSystem.SCAN_INTERVAL, function()
        DropCleanupSystem.SafetyValveScan()
    end, true, "DropCleanupSafetyValve")
end

--- 集中扫描：超时销毁 + 超阈值强制清理 + 补充发现未追踪的掉落物
--- 安全规则：所有 K2_DestroyActor 调用都在遍历结束后统一执行
function DropCleanupSystem.SafetyValveScan()
    local now = os.time()
    local livePickups = {}
    local toDestroy = {}  -- 先收集要销毁的 Actor，遍历完后再统一销毁

    -- 1. 收集已超时的掉落物（不在此处销毁，只收集到 toDestroy）
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
        end
    end

    -- 2. 扫描玩家附近，补充发现未追踪的掉落物
    -- 先复制 GetAllPlayerPawn 返回的 TArray，防止遍历时数组变化
    local allPawns = UGCGameSystem.GetAllPlayerPawn()
    local pawnCopy = CopyToArray(allPawns)
    for _, pawn in ipairs(pawnCopy) do
        if pawn and UE.IsValid(pawn) then
            local location = pawn:K2_GetActorLocation()
            if location then
                local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(
                    location, DropCleanupSystem.SAFETY_RANGE)
                if wrappers then
                    -- 先复制到 Lua table 再遍历
                    local wrapperCopy = CopyToArray(wrappers)
                    for _, wrapper in ipairs(wrapperCopy) do
                        if wrapper and UE.IsValid(wrapper) then
                            if DropCleanupSystem.TrackedPickups[wrapper] == nil then
                                DropCleanupSystem.TrackPickup(wrapper)
                                livePickups[wrapper] = os.time()
                            end
                        end
                    end
                end
            end
        end
    end

    -- 3. 超阈值强制清理最旧的（也加入 toDestroy，不在此处销毁）
    local count = 0
    for _ in pairs(livePickups) do
        count = count + 1
    end

    if count > DropCleanupSystem.MAX_PICKUPS then
        -- 按 trackTime 从小到大排序，先销毁最旧的
        local sorted = {}
        for pickup, trackTime in pairs(livePickups) do
            table.insert(sorted, { actor = pickup, time = trackTime })
        end
        table.sort(sorted, function(a, b)
            return a.time < b.time
        end)

        local excess = count - DropCleanupSystem.MAX_PICKUPS
        for i = 1, math.min(excess, #sorted) do
            local pickup = sorted[i].actor
            table.insert(toDestroy, pickup)
            DropCleanupSystem.TrackedPickups[pickup] = nil
        end
    end

    -- 4. 统一销毁：在所有遍历结束之后，逐个销毁待清理的 Actor
    for _, pickup in ipairs(toDestroy) do
        if pickup and UE.IsValid(pickup) then
            pickup:K2_DestroyActor()
        end
    end
end

return DropCleanupSystem
