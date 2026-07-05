---@class BP_LadderChild_C:ActivityBaseActor
---@field IdleSequence UActorSequenceComponent
---@field CH_Base_SK USkeletalMeshComponent
---@field UpSequence UActorSequenceComponent
---@field DownSequence UActorSequenceComponent
---@field OverlapCheckArea UOverlapCheckAreaComponent
---@field ClickActorComponentBase UClickActorComponentBase
---@field ActivityFakePossess UActivityFakePossessComponent
---@field Box UBoxComponent
---@field CustomActorMove UCustomActorMoveComponent
---@field DefaultSceneRoot USceneComponent
---@field SelfClass UClass
---@field UpSequenceBind FActivityActorSequenceBinding
---@field DownSequenceBind FActivityActorSequenceBinding
---@field IdleSequenceBind FActivityActorSequenceBinding
---@field UpPosition FVector
---@field DownPosition FVector
---@field ClimbSpeed float
---@field UpSphereLocation FVector
---@field DownSphereLocation FVector
--Edit Below--
local BP_LadderChild = {
    DownLocation = nil,
    UpLocation = nil,
    CurrentLocation = nil,
    bUpBlock = false,
    bDownBlock = false,
    PlayerController = nil,
    OwnerLadder = nil,
    DeattachPositionUp = nil,
    DeattachPositionDown = nil,
    CanSwitchState = true,
    bEndOfLadder = false,
    BlockTarget = nil,
    bUpEnd = false,
    bDownEnd = false,
    bDyingTeleportToEndPostion = false,
}
require("common.unrealnetwork")
-- function BP_LadderChild:PrintVector(Vector)
--     print_dev("BP_LadderChild:PrintVector(Vector)--X = "..tostring(Vector.X).." Y = "..tostring(Vector.Y).." Z = "..tostring(Vector.Z))
-- end
function BP_LadderChild:GetAvailableServerRPCs()
    return "ServerRPC_JumpToUpState","ServerRPC_JumpToDownState","ServerRPC_JumpToEndState"
end
--防止玩家调整梯子缩放导致下梯子时无法跳转到正确位置
function BP_LadderChild:ResetUpLocationAndDownLocation()
    local MoveDir = UGCMathUtility.GetDirectionUnitVector(self.DownPosition,self.UpPosition)
    self.UpPosition =  UGCMathUtility.AddVector(self.UpPosition, UGCMathUtility.MultiplyVector(MoveDir, 10000))
    self.DownPosition =  UGCMathUtility.AddVector(self.DownPosition, UGCMathUtility.MultiplyVector(MoveDir, -10000)) 
end
function BP_LadderChild:ReceiveBeginPlay()
    BP_LadderChild.SuperClass.ReceiveBeginPlay(self)
    print_dev("BP_LadderChild:ReceiveBeginPlay")
    self.OverlapCheckArea.OnOverlapCheckChange:Add(self.OverlapCheckArea_OnOverlapCheckChange, self);
    self.ActivityFakePossess.OnPossess:Add(self.ActivityFakePossess_OnPossess, self);
    self.ActivityFakePossess.OnUnPossess:Add(self.ActivityFakePossess_OnUnPossess, self);
    self.UpSequence.PlaybackSettings.PlayRate = self.ClimbSpeed/100
    self.DownSequence.PlaybackSettings.PlayRate = self.ClimbSpeed/100
end
--]]
function BP_LadderChild:PossessWithAttach(PC)
    print_dev("BP_UGC_Ladder:PossessWithAttach")
    self.ActivityFakePossess:FakePossessWithAttach(PC,self.CH_Base_SK,"None")
    self.PlayerController = PC
end
function BP_LadderChild:ClimbUp()
    if self.bUpBlock then
        return
    end
    self.CustomActorMove:StopMove()
    UGCTimerUtility.CreateLuaTimer(0.2, function()
        if self:GetCurrentStateName() == "End" then
            return
        end
        print_dev("BP_LadderChild:ClimbUp--ClimbSpeed = "..tostring(self.ClimbSpeed))
        self.CurrentLocation = self:K2_GetActorLocation()
        self.CustomActorMove:SetPosition(self.CurrentLocation, self.UpPosition)
        self.CustomActorMove:SetMoveSpeed(self.ClimbSpeed)
        self.CustomActorMove:StartMove()
    end,false)
end
function BP_LadderChild:ClimbDown()
    if self.bDownBlock then
        return
    end
    self.CustomActorMove:StopMove()
    UGCTimerUtility.CreateLuaTimer(0.2, function()
        if self:GetCurrentStateName() == "End" then
            return
        end
        self.CurrentLocation = self:K2_GetActorLocation()
        self.CustomActorMove:SetPosition(self.CurrentLocation, self.DownPosition)
        self.CustomActorMove:SetMoveSpeed(self.ClimbSpeed)
        self.CustomActorMove:StartMove()
    end,false)
end
function BP_LadderChild:OnClickExitUI(ClickParams)
    print_dev("BP_LadderChild:OnClickExitUI()")
    if not UGCObjectUtility.IsObjectValid(self.OwnerLadder) then
        print_dev("BP_LadderChild:OnClickExitUI--OwnerLadder is nil")
        return
    end
    self.OwnerLadder:RemoveInterActivePCList(ClickParams.PlayerController)
    self.ActivityFakePossess:FakeUnPossessWithDettach(EUnPossessReason.Finished)
end
function BP_LadderChild:ActivityFakePossess_OnPossess(PC)
    print_dev("BP_UGC_Ladder:OnPossess")
	return nil
end
function BP_LadderChild:OnPlayerAttachedToThisActor_BP(InPlayer)
    print_dev("BP_LadderChild:OnPlayerAttachedToThisActor_BP")
    self.UpSequence:AddBinding(self.UpSequenceBind.Binding, InPlayer,false)
    self.DownSequence:AddBinding(self.DownSequenceBind.Binding, InPlayer,false)
    self.IdleSequence:AddBinding(self.IdleSequenceBind.Binding, InPlayer,false)
    self.UpPosition:Copy()
    self.DownPosition:Copy()
    local MoveForwardTag = STExtraGameplayStatics.RequestGameplayTag("Input.Move.MoveForward", true)
    UGCInputSystem.BindInputMapping(self,MoveForwardTag,ETriggerEvent.Triggered,function(InputValue,ElapsedTime,TriggerTime,InputTag)
        if not self.CanSwitchState then
            return
        end
        if ElapsedTime > 0 then
            if self.bUpBlock or self:GetCurrentStateName() == "Up" then
                return
            end
            UnrealNetwork.CallUnrealRPC(InPlayer:GetPlayerControllerSafety(),self, "ServerRPC_JumpToUpState")
        end
        if ElapsedTime < 0 then
            if self.bDownBlock or self:GetCurrentStateName() == "Down" then
                return
            end
            UnrealNetwork.CallUnrealRPC(InPlayer:GetPlayerControllerSafety(),self, "ServerRPC_JumpToDownState")
        end
    end)
    UGCInputSystem.BindInputMapping(self,MoveForwardTag,ETriggerEvent.Completed,function(InputValue,ElapsedTime,TriggerTime,InputTag)
        UnrealNetwork.CallUnrealRPC(InPlayer:GetPlayerControllerSafety(),self, "ServerRPC_JumpToEndState")
    end)
end
function BP_LadderChild:ServerRPC_JumpToUpState()
    if self.bUpBlock then
        return
    end
    self:JumpToState("Up")
end
function BP_LadderChild:ServerRPC_JumpToDownState()
    if self.bDownBlock then
        return
    end
    self:JumpToState("Down")
end
function BP_LadderChild:ServerRPC_JumpToEndState()
    self:JumpToState("End")
end
function BP_LadderChild:CanShowExitUI(ClickParams)
    if self.PlayerController ~= ClickParams.PlayerController then
        return false
    end
    return true
end
function BP_LadderChild:ActivityFakePossess_OnUnPossess(PC)
    print_dev("BP_UGC_Ladder:OnUnPossess")
    UGCTimerUtility.CreateLuaTimer(0.1, function()
        self:K2_DestroyActor()
    end,false)
    if UGCGameSystem.IsServer() then
        local PlayerCharacter = PC:GetPlayerCharacterSafety()
        if not UGCObjectUtility.IsObjectValid(PlayerCharacter) then
            return
        end
        if self:GetCurrentStateName() == "End" then
            print_dev("BP_LadderChild:OnUnPossess--End")
            if self.bUpBlock and self.bUpEnd then
                if self.bEndOfLadder and self.DeattachPositionUp~=nil then
                    if not self.bDyingTeleportToEndPostion then
                        if not PlayerCharacter:HasState(EPawnState.Dying) then
                            PlayerCharacter:DSTeleportToLocationOrRotation(self.DeattachPositionUp, Rotator.New(0, 0, 0), true, false, false)
                        else
                            self.OwnerLadder:RemoveInterActivePCList(PC)
                        end
                    else
                        PlayerCharacter:DSTeleportToLocationOrRotation(self.DeattachPositionUp, Rotator.New(0, 0, 0), true, false, false)
                        if PlayerCharacter:HasState(EPawnState.Dying) then
                            self.OwnerLadder:RemoveInterActivePCList(PC)
                        end
                    end
                end
            elseif self.bDownBlock and self.bDownEnd then
                if self.bEndOfLadder and self.DeattachPositionDown~=nil then
                    if not self.bDyingTeleportToEndPostion then
                        if not PlayerCharacter:HasState(EPawnState.Dying) then
                            PlayerCharacter:DSTeleportToLocationOrRotation(self.DeattachPositionDown, Rotator.New(0, 0, 0), true, false, false)
                        else
                            self.OwnerLadder:RemoveInterActivePCList(PC)
                        end
                    else
                        PlayerCharacter:DSTeleportToLocationOrRotation(self.DeattachPositionDown, Rotator.New(0, 0, 0), true, false, false)
                        if PlayerCharacter:HasState(EPawnState.Dying) then
                            self.OwnerLadder:RemoveInterActivePCList(PC)
                        end
                    end
                end
            end
        end
        if self.BlockTarget ~= nil then
            self.BlockTarget.bUpBlock = false
            self.BlockTarget.bDownBlock = false
        end
    else
        UGCInputSystem.RemoveBindingToObject(self)
    end
end
function BP_LadderChild:Up_Entry()
    print_dev("BP_LadderChild:Up_Entry()")
    self:ClimbUp()
end
function BP_LadderChild:End_Entry()
    print_dev("BP_LadderChild:End_Entry()")
    self.CustomActorMove:StopMove()
end
function BP_LadderChild:Down_Entry()
    print_dev("BP_LadderChild:Down_Entry()")
    self:ClimbDown()
end

--[[
function BP_LadderChild:ReceiveTick(DeltaTime)
    BP_LadderChild.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function BP_LadderChild:ReceiveEndPlay()
    BP_LadderChild.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function BP_LadderChild:GetReplicatedProperties()
    return
end
--]]

--[[
function BP_LadderChild:GetAvailableServerRPCs()
    return
end
--]]

-- [Editor Generated Lua] function define Begin:
function BP_LadderChild:AttachLadderEndPosition(bUpPostion)
    if bUpPostion then
        print_dev("BP_LadderChild:AttachLadderEndPosition--Up")
        self.CustomActorMove:StopMove()
        self.bUpBlock = true
        self.bUpEnd = true
        self:JumpToState("End")
    end
    if not bUpPostion then
        self.CustomActorMove:StopMove()
        self.bDownBlock = true
        self.bDownEnd = true
        self:JumpToState("End")
    end
    self.bEndOfLadder = true
end
function BP_LadderChild:DeAttachLadderEndPosition(bLeaveUpPostion)
    if bLeaveUpPostion then
        print_dev("BP_LadderChild:DeAttachLadderEndPosition--Up")
        self.bUpBlock = false
    end
    if not bLeaveUpPostion then
        self.bDownBlock = false
    end
    self.bEndOfLadder = false
end

function BP_LadderChild:OverlapCheckArea_OnOverlapCheckChange(CheckActorArray)
    print_dev("BP_LadderChild:OverlapCheckArea_OnOverlapCheckChange(CheckActorArray)")
    for k, CheckActor in pairs(CheckActorArray.InActorList) do
        print_dev("BP_LadderChild:OverlapCheckArea_OnOverlapCheckChange(CheckActorArray)--CheckActor = "..KismetSystemLibrary.GetDisplayName(CheckActor))
        if UGCObjectUtility.IsA(CheckActor,self.SelfClass) then
            print_dev("BP_LadderChild:OverlapCheckArea_OnOverlapCheckChange--Stop")
            if self:K2_GetActorLocation().Z < CheckActor:K2_GetActorLocation().Z then
                self.CustomActorMove:StopMove()
                self.bUpBlock = true
            else
                self.CustomActorMove:StopMove()
                self.bDownBlock = true
            end
            CheckActor.BlockTarget = self
        end
    end
    for k, CheckActor in pairs(CheckActorArray.OutActorList) do
        if UGCObjectUtility.IsA(CheckActor,self.SelfClass) then
            print_dev("BP_LadderChild:OverlapCheckArea_OnOverlapCheckChange--Move--"..tostring(self:GetCurrentStateName()))
            if self:K2_GetActorLocation().Z < CheckActor:K2_GetActorLocation().Z then
                self.bUpBlock = false
            else
                self.bDownBlock = false
            end
            CheckActor.BlockTarget = nil
        end
    end
	return nil;
end

-- [Editor Generated Lua] function define End;

return BP_LadderChild