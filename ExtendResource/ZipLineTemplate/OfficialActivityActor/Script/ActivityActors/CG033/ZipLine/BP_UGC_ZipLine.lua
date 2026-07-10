---@class BP_UGC_ZipLine_C:ActivityBaseActor
---@field ChildAttachScene USceneComponent
---@field Sphere USphereComponent
---@field ClickActorComponentBase UClickActorComponentBase
---@field AttachScene USceneComponent
---@field Cube1 UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field TargetZipLine BP_UGC_ZipLine_C
---@field Rope BP_UGC_Rope_C
---@field RopeClass UClass
---@field ChildClass UClass
---@field ProhibitState ULuaArrayHelper<EPawnState>
---@field DeattachAreaRadius float
--Edit Below--
local BP_UGC_ZipLine = {
    bSpawn = false,
    bCD = false,
}
 
function BP_UGC_ZipLine:PrintVector(Vector)
end
function BP_UGC_ZipLine:ReceiveBeginPlay()
    BP_UGC_ZipLine.SuperClass.ReceiveBeginPlay(self)
    if not UGCObjectUtility.IsObjectValid(self.TargetZipLine) then
        return
    end
    if self.TargetZipLine.TargetZipLine ~= self then
        UGCTimerUtility.CreateLuaTimer(0.5, function()
            self.Rope = UGCActorComponentUtility.SpawnActor(self, self.RopeClass, self.AttachScene:K2_GetComponentLocation(), self.AttachScene:K2_GetComponentRotation(), Vector.New(1, 1, 1), self)
            self.Rope.EndMesh:K2_SetWorldLocation(self.TargetZipLine.AttachScene:K2_GetComponentLocation())
        end,false)
    else
        UGCTimerUtility.CreateLuaTimer(0.5, function()
            self.Rope = UGCActorComponentUtility.SpawnActor(self, self.RopeClass, self.AttachScene:K2_GetComponentLocation(), self.AttachScene:K2_GetComponentRotation(), Vector.New(1, 1, 1), self)
            self:PrintVector(self.Cube1:K2_GetComponentLocation())
            --self.TargetZipLine.Rope = self.Rope
            self.Rope.EndMesh:K2_SetWorldLocation(self.TargetZipLine.AttachScene:K2_GetComponentLocation())
        end,false)
    end
end
function BP_UGC_ZipLine:CanClickZipLineUI(ClickParams)
    if not UGCObjectUtility.IsObjectValid(self.TargetZipLine) then
        return false
    end
    local CheckActor = ClickParams.PlayerController:GetPlayerCharacterSafety()
    for _, State in pairs(self.ProhibitState) do
        if CheckActor:HasState(State) then
            return false
        end
    end
    return true
end
function BP_UGC_ZipLine:OnClickedZipLineUI(ClickParams)
    if not UGCGameSystem.IsServer() then
        return
    end
    if self.bCD then
        return
    else
        Timer.InsertTimer(0.5,function ()
            self.bCD = false
        end,false)
    end
    self.bCD = true
    local EndLocation = self.TargetZipLine.AttachScene:K2_GetComponentLocation()--UGCMathUtility.AddVector(self.TargetZipLine.AttachScene:K2_GetComponentLocation(), UGCMathUtility.MultiplyVector(Direct, 88))
    local Direct = UGCMathUtility.GetDirectionUnitVector(self.AttachScene:K2_GetComponentLocation(), EndLocation)
    local DeattachLocation = UGCMathUtility.AddVector(EndLocation, UGCMathUtility.MultiplyVector(Direct, -150))
    local StartLocation = UGCMathUtility.AddVector(self.AttachScene:K2_GetComponentLocation(), UGCMathUtility.MultiplyVector(Direct, 88))
    local RotationFind_StartLocation = self.ChildAttachScene:K2_GetComponentLocation()
    local RotationFind_EndLocation = self.TargetZipLine.ChildAttachScene:K2_GetComponentLocation()
    local Rotation = KismetMathLibrary.FindLookAtRotation(RotationFind_StartLocation,RotationFind_EndLocation)
    Rotation.Pitch = 0
    Rotation.Roll = 0
    StartLocation.Z = StartLocation.Z - 160
    DeattachLocation.Z = DeattachLocation.Z - 160
    local ZipLineChild = UGCActorComponentUtility.SpawnActor(self, self.ChildClass, StartLocation,Rotation, Vector.New(1, 1, 1), self)
    ZipLineChild.OwnerZipLine = self
    ZipLineChild.TargetZipLine = self.TargetZipLine
    ZipLineChild:PossessWithAttach(ClickParams.PlayerController,StartLocation,DeattachLocation)
end

--]]

--[[
function BP_UGC_ZipLine:ReceiveTick(DeltaTime)
    BP_UGC_ZipLine.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_UGC_ZipLine:ReceiveEndPlay()
    BP_UGC_ZipLine.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_UGC_ZipLine:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_UGC_ZipLine:GetAvailableServerRPCs()
    return
end
--]]

-- [Editor Generated Lua] function define Begin:
function BP_UGC_ZipLine:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:
	self.ChildAttachScene.TransformUpdatedDynamic:Add(self.ChildAttachScene_TransformUpdatedDynamic, self);
	-- [Editor Generated Lua] BindingEvent End;
end

function BP_UGC_ZipLine:ChildAttachScene_TransformUpdatedDynamic()
	return nil;
end

-- [Editor Generated Lua] function define End;

return BP_UGC_ZipLine
