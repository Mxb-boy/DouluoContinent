--[[
    DropCleanupSystem: 掉落物自动清理系统
    - 每个掉落物 180 秒后自动销毁
    - 集中式安全阀：定期扫描，超过 80 个时强制清理最旧的
]]
local DropCleanupSystem = {}

-- 已追踪的掉落物（weak-keyed，避免阻止 GC）
DropCleanupSystem.TrackedPickups = setmetatable({}, { __mode = "k" })
DropCleanupSystem.MAX_AGE = 180
DropCleanupSystem.SCAN_DELAY = 1
DropCleanupSystem.SCAN_RANGE = 1500
DropCleanupSystem.SAFETY_INTERVAL = 30
DropCleanupSystem.MAX_PICKUPS = 80
DropCleanupSystem.SAFETY_RANGE = 100000

--- 在指定位置附近查找掉落物并安排 180 秒后自动销毁
---@param location FVector 掉落位置
function DropCleanupSystem.ScheduleDropCleanup(location)
    if location == nil then
        return
    end

    UGCTimerUtility.CreateLuaTimer(DropCleanupSystem.SCAN_DELAY, function()
        local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(location, DropCleanupSystem.SCAN_RANGE)
        if wrappers == nil then
            return
        end

        for _, wrapper in pairs(wrappers) do
            if wrapper and UE.IsValid(wrapper) and DropCleanupSystem.TrackedPickups[wrapper] == nil then
                DropCleanupSystem.TrackedPickups[wrapper] = true
                local actor = wrapper
                UGCTimerUtility.CreateLuaTimer(DropCleanupSystem.MAX_AGE, function()
                    if actor and UE.IsValid(actor) then
                        actor:K2_DestroyActor()
                    end
                    DropCleanupSystem.TrackedPickups[actor] = nil
                end, false)
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
    DropCleanupSystem.TrackedPickups[pickupActor] = true

    local actor = pickupActor
    UGCTimerUtility.CreateLuaTimer(DropCleanupSystem.MAX_AGE, function()
        if actor and UE.IsValid(actor) then
            actor:K2_DestroyActor()
        end
        DropCleanupSystem.TrackedPickups[actor] = nil
    end, false)
end

--- 启动集中式安全阀定时器（每 30 秒扫描一次，超过上限时强制清理）
function DropCleanupSystem.StartSafetyValveTimer()
    UGCTimerUtility.CreateLuaTimer(DropCleanupSystem.SAFETY_INTERVAL, function()
        DropCleanupSystem.SafetyValveScan()
    end, true, "DropCleanupSafetyValve")
end

function DropCleanupSystem.SafetyValveScan()
    local allPawns = UGCGameSystem.GetAllPlayerPawn()
    if allPawns == nil then
        return
    end

    local foundPickups = {}

    for _, pawn in ipairs(allPawns) do
        if pawn and UE.IsValid(pawn) then
            local location = pawn:K2_GetActorLocation()
            if location then
                local wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(
                    location, DropCleanupSystem.SAFETY_RANGE)
                if wrappers then
                    for _, wrapper in pairs(wrappers) do
                        if wrapper and UE.IsValid(wrapper) then
                            foundPickups[wrapper] = true

                            if DropCleanupSystem.TrackedPickups[wrapper] == nil then
                                DropCleanupSystem.TrackPickup(wrapper)
                            end
                        end
                    end
                end
            end
        end
    end

    local count = 0
    for _ in pairs(foundPickups) do
        count = count + 1
    end

    if count > DropCleanupSystem.MAX_PICKUPS then
        local excess = count - DropCleanupSystem.MAX_PICKUPS
        for pickup, _ in pairs(foundPickups) do
            if excess <= 0 then
                break
            end
            if pickup and UE.IsValid(pickup) then
                pickup:K2_DestroyActor()
                DropCleanupSystem.TrackedPickups[pickup] = nil
                excess = excess - 1
            end
        end
        print(string.format("[DropCleanup] Safety valve: destroyed %d excess pickups", count - DropCleanupSystem.MAX_PICKUPS))
    end
end

return DropCleanupSystem
