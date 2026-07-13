---@class AFKZone_C:AActor
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field Interval float
---@field HPAddFixed int32
---@field ATKAddFixed int32
---@field HPAddPercent float
---@field ATKAddPercent float
--Edit Below--
local AFKZone = {}

function AFKZone:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    print(string.format("[AFKZone] ReceiveBeginPlay: HasAuthority=%s Box=%s",
        tostring(self:HasAuthority()), tostring(self.Box)))
    if self:HasAuthority() then
        if self.Box ~= nil then
            self.Box.OnComponentBeginOverlap:Add(self.OnBeginOverlap, self)
            self.Box.OnComponentEndOverlap:Add(self.OnEndOverlap, self)
            print("[AFKZone] Box overlap events registered")
            -- 检查碰撞设置
            local collisionEnabled = self.Box:GetCollisionEnabled()
            local bOverlap = self.Box.bGenerateOverlapEvents
            print(string.format("[AFKZone] Box collision: enabled=%s overlapEvents=%s",
                tostring(collisionEnabled), tostring(bOverlap)))
        else
            print("[AFKZone] ERROR: Box component is nil!")
        end
    end
end

function AFKZone:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    print(string.format("[AFKZone] OnBeginOverlap: OtherActor=%s class=%s",
        tostring(OtherActor), tostring(OtherActor and OtherActor.get_class and OtherActor:get_class():get_name())))
    local pc = OtherActor:GetPlayerControllerSafety()
    if pc == nil then
        print("[AFKZone] OnBeginOverlap: not a player, skip")
        return
    end

    local timerName = "AFKZone_" .. tostring(pc.PlayerKey)
    UGCTimerUtility.RemoveLuaTimerByName(timerName)
    print(string.format("[AFKZone] Timer started: %s", timerName))

    UGCTimerUtility.CreateLuaTimer(5, function()
        print("[AFKZone] Timer tick: calling Server_AddFixedBaseProperty")
        pc:Server_AddFixedBaseProperty()
    end, true, timerName)
end

function AFKZone:OnEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    local pc = OtherActor:GetPlayerControllerSafety()
    if pc == nil then return end

    local timerName = "AFKZone_" .. tostring(pc.PlayerKey)
    UGCTimerUtility.RemoveLuaTimerByName(timerName)
    print(string.format("[AFKZone] Timer stopped: %s", timerName))
end

return AFKZone
