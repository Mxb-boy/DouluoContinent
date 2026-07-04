---@class BXCollition_C:AActor
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field TowerID int32
-- Edit Below--
local BXCollition = {}
function BXCollition:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self);
    self:LuaInit();
    if self:HasAuthority() then
        self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);

    end
end

function BXCollition:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep,
    SweepResult)

    --[[------------------------通知打开UI----------------------]] --
    local pc = OtherActor:GetPlayerControllerSafety()
    if pc then
        UnrealNetwork.CallUnrealRPC(pc, pc, "Client_OpenTowerTopUI")
    end
end

-- [Editor Generated Lua] function define Begin:
function BXCollition:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:
    self.Box.OnComponentEndOverlap:Add(self.Box_OnComponentEndOverlap, self);
    -- [Editor Generated Lua] BindingEvent End;
end

function BXCollition:Box_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    return nil;
end

-- [Editor Generated Lua] function define End;

return BXCollition
