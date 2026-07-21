---@class CFQ_C:AActor
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CFQ = {}

local function GetPlayerController(Actor)
    if Actor == nil or Actor.GetPlayerControllerSafety == nil then
        return nil
    end

    return Actor:GetPlayerControllerSafety()
end

local function GetSystemInvincible(PlayerPawn)
    if PlayerPawn == nil then
        return false
    end

    if UGCPlayerPawnSystem ~= nil and UGCPlayerPawnSystem.GetIsInvincible ~= nil then
        local Success, Result = pcall(UGCPlayerPawnSystem.GetIsInvincible, PlayerPawn)
        if Success then
            return Result == true or tonumber(Result) == 1
        end
    end

    if PlayerPawn.GetIsInvincible ~= nil then
        local Success, Result = pcall(PlayerPawn.GetIsInvincible, PlayerPawn)
        if Success then
            return Result == true or tonumber(Result) == 1
        end
    end

    return false
end

local function SetSystemInvincible(PlayerPawn, bEnabled)
    if PlayerPawn == nil then
        return false
    end

    local bInvincible = bEnabled == true or tonumber(bEnabled) == 1
    if UGCPlayerPawnSystem ~= nil and UGCPlayerPawnSystem.SetIsInvincible ~= nil then
        local Success = pcall(UGCPlayerPawnSystem.SetIsInvincible, PlayerPawn, bInvincible)
        if Success then
            return true
        end
    end

    if PlayerPawn.SetInvincible ~= nil then
        local Success = pcall(PlayerPawn.SetInvincible, PlayerPawn, bInvincible)
        if Success then
            return true
        end
    end

    return false
end

local function EnableSafeZoneHeroInvincible(PlayerPawn)
    if PlayerPawn == nil then
        return
    end

    local Count = tonumber(PlayerPawn.SafeZoneInvincibleCount) or 0
    if Count <= 0 then
        PlayerPawn.SafeZonePreviousInvincible = GetSystemInvincible(PlayerPawn)
        SetSystemInvincible(PlayerPawn, true)
    end

    PlayerPawn.SafeZoneInvincibleCount = Count + 1
end

local function DisableSafeZoneHeroInvincible(PlayerPawn)
    if PlayerPawn == nil then
        return
    end

    local Count = math.max(0, (tonumber(PlayerPawn.SafeZoneInvincibleCount) or 0) - 1)
    PlayerPawn.SafeZoneInvincibleCount = Count
    if Count <= 0 then
        SetSystemInvincible(PlayerPawn, PlayerPawn.SafeZonePreviousInvincible == true)
        PlayerPawn.SafeZonePreviousInvincible = nil
    end
end

local function BindOverlapEvents(self)
    if self == nil or self.bSafeZoneOverlapEventsBound == true then
        return
    end

    if self.Box == nil then
        ugcprint("[SafeZone] Box is nil, overlap events not registered")
        return
    end

    self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
    self.Box.OnComponentEndOverlap:Add(self.Box_OnComponentEndOverlap, self);
    self.bSafeZoneOverlapEventsBound = true
    ugcprint("[SafeZone] overlap events registered")
end
 
--[[
function CFQ:ReceiveBeginPlay()
    CFQ.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function CFQ:ReceiveTick(DeltaTime)
    CFQ.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function CFQ:ReceiveEndPlay()
    CFQ.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function CFQ:GetReplicatedProperties()
    return
end
--]]

--[[
function CFQ:GetAvailableServerRPCs()
    return
end
--]]

function CFQ:ReceiveBeginPlay()
    if CFQ.SuperClass ~= nil and CFQ.SuperClass.ReceiveBeginPlay ~= nil then
        CFQ.SuperClass.ReceiveBeginPlay(self)
    end

    self.SafeZonePlayers = self.SafeZonePlayers or {}
    BindOverlapEvents(self)
end

-- [Editor Generated Lua] function define Begin:
function CFQ:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
    self.SafeZonePlayers = self.SafeZonePlayers or {}
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	BindOverlapEvents(self)
	-- [Editor Generated Lua] BindingEvent End;
end

function CFQ:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        return nil;
    end

    local pc = GetPlayerController(OtherActor)
    if pc == nil then
        return nil;
    end

    self.SafeZonePlayers = self.SafeZonePlayers or {}
    if self.SafeZonePlayers[OtherActor] then
        return nil;
    end

    self.SafeZonePlayers[OtherActor] = true
    EnableSafeZoneHeroInvincible(OtherActor)
    ugcprint("[SafeZone] enable system invincible key=" .. tostring(pc.PlayerKey) .. " count=" ..
                 tostring(OtherActor.SafeZoneInvincibleCount))
	return nil;
end

function CFQ:Box_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() then
        return nil;
    end

    local pc = GetPlayerController(OtherActor)
    if pc == nil then
        return nil;
    end

    self.SafeZonePlayers = self.SafeZonePlayers or {}
    if not self.SafeZonePlayers[OtherActor] then
        return nil;
    end

    self.SafeZonePlayers[OtherActor] = nil
    DisableSafeZoneHeroInvincible(OtherActor)
    ugcprint("[SafeZone] disable system invincible key=" .. tostring(pc.PlayerKey) .. " count=" ..
                 tostring(OtherActor.SafeZoneInvincibleCount))
	return nil;
end

function CFQ:ReceiveEndPlay()
    if self:HasAuthority() and self.SafeZonePlayers ~= nil then
        for PlayerPawn, _ in pairs(self.SafeZonePlayers) do
            DisableSafeZoneHeroInvincible(PlayerPawn)
        end
        self.SafeZonePlayers = {}
    end

    CFQ.SuperClass.ReceiveEndPlay(self)
end

-- [Editor Generated Lua] function define End;

return CFQ
