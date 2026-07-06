---@class BP_UGC_ZipLineChild_C:ActivityBaseActor
---@field Slide UStaticMeshComponent
---@field ActorSequence UActorSequenceComponent
---@field ActivityFakePossess UActivityFakePossessComponent
---@field SkeletalMesh USkeletalMeshComponent
---@field Scene USceneComponent
---@field CustomActorMove UCustomActorMoveComponent
---@field DefaultSceneRoot USceneComponent
---@field ClimbSpeed float
---@field ActiveSeqBind FActivityActorSequenceBinding
---@field DisableState ULuaArrayHelper<EPawnState>
---@field RopeClass UClass
--Edit Below--
local BP_UGC_ZipLineChild = {
    OwnerZipLine = nil,
    TargetZipLine = nil,
}

function BP_UGC_ZipLineChild:AreaBlockadeDetect(BeginLocation,EndLocation)
    local IgnoreActors = {self}

    if UGCObjectUtility.IsObjectValid(self.OwnerZipLine) then
        table.insert(IgnoreActors, self.OwnerZipLine)
    end

    if UGCObjectUtility.IsObjectValid(self.TargetZipLine) then
        table.insert(IgnoreActors, self.TargetZipLine)
    end

    if UGCObjectUtility.IsObjectValid(self.PlayerController) then
        local PlayerCharacter = self.PlayerController:GetPlayerCharacterSafety()
        if UGCObjectUtility.IsObjectValid(PlayerCharacter) then
            table.insert(IgnoreActors, PlayerCharacter)
        end
    end

    local bHit,HitResult = 
    KismetSystemLibrary.SphereTraceSingle(self, 
    BeginLocation,
    EndLocation,
    40, 
    ECollisionChannel.ECC_WorldDynamic, 
    false,
    IgnoreActors
    )
    if not bHit then
        print_dev("BP_UGC_ZipLineChild:AreaBlockadeDetect--true")
        return false
    end
    if UGCObjectUtility.IsA(HitResult.Actor:Get(),self.RopeClass) then
        return false
    end
    print_dev("BP_UGC_ZipLineChild:AreaBlockadeDetect--false--HitResult.Actor:Get() = "..KismetSystemLibrary.GetDisplayName(HitResult.Actor:Get()))
    return true
end

function BP_UGC_ZipLineChild:PossessWithAttach(PC,StartLocation,EndLocation)
    print("BP_UGC_ZipLineChild:PossessWithAttach")
    self.ActivityFakePossess:FakePossessWithAttach(PC,self.Scene,"None")
    self.PlayerController = PC
    self.CustomActorMove:SetPosition(StartLocation, EndLocation)
    --print("BP_LadderChild:OnClickUpUI--ClimbSpeed = "..tostring(self.ClimbSpeed))
    self.CustomActorMove:SetMoveSpeed(self.ClimbSpeed)
    self.CustomActorMove:StartMove()
    self:JumpToState("Active")
    if UGCGameSystem.IsServer() then
        for _, State in ipairs(self.DisableState) do
            UGCPawnSystem.DisabledPawnState(self.PlayerController:GetPlayerCharacterSafety(), State, true)
        end
    end
end
function BP_UGC_ZipLineChild:ActivityFakePossess_OnUnPossess(PC)
    print("BP_UGC_Ladder:OnUnPossess")
    UGCTimerUtility.RemoveLuaTimerByName("CheckBlockTimer")
    if UGCGameSystem.IsServer() then
        local PlayerCharacter = PC:GetPlayerCharacterSafety()
        for _, State in ipairs(self.DisableState) do
            UGCPawnSystem.DisabledPawnState(PlayerCharacter, State, false)
        end
    end
    UGCTimerUtility.CreateLuaTimer(0.1, function()
        self:K2_DestroyActor()
    end,false)
end

function BP_UGC_ZipLineChild:OnPlayerAttachedToThisActor_BP(InPlayer)
    print("BP_LadderChild:OnPlayerAttachedToThisActor_BP")
    self.ActorSequence:AddBinding(self.ActiveSeqBind.Binding, InPlayer, false)
end

function BP_UGC_ZipLineChild:ReceiveBeginPlay()
    BP_UGC_ZipLineChild.SuperClass.ReceiveBeginPlay(self)
    self.CustomActorMove.ActorMoveEvent:Add(self.CustomActorMove_ActorMoveEvent, self);
    self.ActivityFakePossess.OnUnPossess:Add(self.ActivityFakePossess_OnUnPossess, self);
    UGCTimerUtility.CreateLuaTimer(0.2, function()
        local bBlock = self:AreaBlockadeDetect(self.Scene:K2_GetComponentLocation(),self.SkeletalMesh:K2_GetComponentLocation())
        print_dev("BP_UGC_ZipLineChild:ReceiveBeginPlay--bBlock = "..tostring(bBlock))
        if bBlock then
            self.ActivityFakePossess:FakeUnPossessWithDettach(self.PlayerController,EUnPossessReason.Finished)
        end
    end,true,"CheckBlockTimer")
end
--]]

--[[
function BP_UGC_ZipLineChild:ReceiveTick(DeltaTime)
    BP_UGC_ZipLineChild.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_UGC_ZipLineChild:ReceiveEndPlay()
    BP_UGC_ZipLineChild.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_UGC_ZipLineChild:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_UGC_ZipLineChild:GetAvailableServerRPCs()
    return
end
--]]

-- [Editor Generated Lua] function define Begin:
function BP_UGC_ZipLineChild:CustomActorMove_ActorMoveEvent(bIsMove)
    if not bIsMove then
        self.ActivityFakePossess:FakeUnPossessWithDettach(self.PlayerController,EUnPossessReason.Finished)
    end
	return nil;
end

-- [Editor Generated Lua] function define End;

return BP_UGC_ZipLineChild
