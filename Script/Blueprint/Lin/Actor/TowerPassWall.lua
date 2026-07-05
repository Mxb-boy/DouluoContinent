---@class TowerPassWall_C:AActor
---@field WallCollision UBoxComponent
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
-- Edit Below--
local TowerPassWall = {}

local PASS_ITEM_ID = 8310063
local TARGET_SPAWN_POINT = 301

--[[
function TowerPassWall:ReceiveBeginPlay()
    TowerPassWall.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function TowerPassWall:ReceiveTick(DeltaTime)
    TowerPassWall.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function TowerPassWall:ReceiveEndPlay()
    TowerPassWall.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function TowerPassWall:GetReplicatedProperties()
    return
end
--]]

--[[
function TowerPassWall:GetAvailableServerRPCs()
    return
end
--]]

-- [Editor Generated Lua] function define Begin:
function TowerPassWall:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:
    -- [Editor Generated Lua] BindingEvent End;
end

function TowerPassWall:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self);
    if self:HasAuthority() then
        self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);

    end
end

function TowerPassWall:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex,
    bFromSweep, SweepResult)
    if not self:HasAuthority() then
        return nil;
    end

    local pc = OtherActor:GetPlayerControllerSafety()
    if pc == nil then
        return nil;
    end

    local count = UGCBackpackSystemV2.GetItemCountV2(OtherActor, PASS_ITEM_ID) or 0
    if count > 0 then
        pc:Server_TeleportToSpawn(TARGET_SPAWN_POINT)
    end

    return nil;
end

-- [Editor Generated Lua] function define End;

return TowerPassWall
