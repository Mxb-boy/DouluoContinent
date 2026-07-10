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
    if self:HasAuthority() then
        if self.Box ~= nil then
            self.Box.OnComponentBeginOverlap:Add(self.OnBeginOverlap, self)
            self.Box.OnComponentEndOverlap:Add(self.OnEndOverlap, self)
        end
    end
end

function AFKZone:OnBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local pc = OtherActor:GetPlayerControllerSafety()
    if pc == nil then
        return
    end

    local timerName = "AFKZone_" .. tostring(pc.PlayerKey)
    UGCTimerUtility.RemoveLuaTimerByName(timerName)

    UGCTimerUtility.CreateLuaTimer(5, function()
        pc:Server_AddFixedBaseProperty()
    end, true, timerName)
end

function AFKZone:OnEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    local pc = OtherActor:GetPlayerControllerSafety()
    if pc == nil then return end

    local timerName = "AFKZone_" .. tostring(pc.PlayerKey)
    UGCTimerUtility.RemoveLuaTimerByName(timerName)
end

return AFKZone
