---@class Colli_SaveArea_C:AActor
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local Colli_SaveArea = {}

--[[----------------------初始化安全区域------------------------]]
function Colli_SaveArea:ReceiveBeginPlay()
    Colli_SaveArea.SuperClass.ReceiveBeginPlay(self)
    self.Overlapping_Players = {}
    self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
    self.Box.OnComponentEndOverlap:Add(self.Box_OnComponentEndOverlap, self);
end

--[[
function Colli_SaveArea:ReceiveTick(DeltaTime)
    Colli_SaveArea.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function Colli_SaveArea:ReceiveEndPlay()
    Colli_SaveArea.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function Colli_SaveArea:GetReplicatedProperties()
    return
end
--]]

--[[
function Colli_SaveArea:GetAvailableServerRPCs()
    return
end
--]]

-- [Editor Generated Lua] function define Begin:
--[[----------------------初始化蓝图脚本------------------------]]
function Colli_SaveArea:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:

    -- [Editor Generated Lua] BindingEvent End;
end

--[[----------------------玩家进入区域时开启无敌------------------------]]
function Colli_SaveArea:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex,
    bFromSweep, SweepResult)
    if not self:HasAuthority() then
        return nil;
    end

    local Player_Controller = UGCGameSystem.GetPlayerControllerByPlayerPawn(OtherActor)
    if Player_Controller == nil then
        return nil;
    end

    self.Overlapping_Players = self.Overlapping_Players or {}
    local Overlap_Count = self.Overlapping_Players[OtherActor] or 0
    self.Overlapping_Players[OtherActor] = Overlap_Count + 1
    if Overlap_Count > 0 then
        return nil;
    end

    local Safe_Area_Count = tonumber(OtherActor.Safe_Area_Invincible_Count) or 0
    if Safe_Area_Count == 0 then
        OtherActor.Safe_Area_Previous_Invincible = UGCPlayerPawnSystem.GetIsInvincible(OtherActor)
    end
    OtherActor.Safe_Area_Invincible_Count = Safe_Area_Count + 1
    UGCPlayerPawnSystem.SetIsInvincible(OtherActor, true)
    return nil;
end

--[[----------------------玩家离开区域时恢复无敌状态------------------------]]
function Colli_SaveArea:Box_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() or self.Overlapping_Players == nil then
        return nil;
    end

    local Overlap_Count = self.Overlapping_Players[OtherActor]
    if Overlap_Count == nil then
        return nil;
    end

    Overlap_Count = Overlap_Count - 1
    if Overlap_Count > 0 then
        self.Overlapping_Players[OtherActor] = Overlap_Count
        return nil;
    end
    self.Overlapping_Players[OtherActor] = nil

    local Safe_Area_Count = math.max(0, (tonumber(OtherActor.Safe_Area_Invincible_Count) or 0) - 1)
    OtherActor.Safe_Area_Invincible_Count = Safe_Area_Count
    if Safe_Area_Count == 0 then
        UGCPlayerPawnSystem.SetIsInvincible(OtherActor, OtherActor.Safe_Area_Previous_Invincible == true)
        OtherActor.Safe_Area_Previous_Invincible = nil
    end
    return nil;
end

-- [Editor Generated Lua] function define End;

return Colli_SaveArea
