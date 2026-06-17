---@class TSSJ_02_C:PESkillTemplate_Base_C
---@field CacheSelectTarget AActor
---@field CacheInitPosition FVector
---@field AttachOffset FVector
--Edit Below--

local TSSJ_02 = {
    
}

function TSSJ_02:InitSelectTarget()
    self.CacheInitPosition = self:GetOwnerActor():K2_GetActorLocation()
    local TargetList = self:GetSelectTargetActor(EPESkillSelectTarget.E_PESKILL_PickerType_AllTarget)
    if TargetList[1] ~= nil then
        self.CacheSelectTarget = TargetList[1]
    else
        self.CacheSelectTarget = nil
        self:DeActivateSkill(EPESkillDeActivateReason.E_PESKILL_DeActivateReason_Normal)
    end
end

function TSSJ_02:HiddenWeapon()
    local WeaponManger = self:GetOwnerActor():GetWeaponManager()
    if WeaponManger ~= nil then
        for _, Weapon in pairs(WeaponManger:GetAllInventoryWeaponList(false)) do
            Weapon:SetActorHiddenInGame(true)
        end
    end
end

function TSSJ_02:ShowWeapon()
    local WeaponManger = self:GetOwnerActor():GetWeaponManager()
    if WeaponManger ~= nil then
        for _, Weapon in pairs(WeaponManger:GetAllInventoryWeaponList(false)) do
            Weapon:SetActorHiddenInGame(false)
        end
    end
end


function TSSJ_02:AttachToTarget()
    local SelectTargetLocation = self.CacheSelectTarget:K2_GetActorLocation()
    local Rotation = UGCMathUtility.MakeRotator(0,0,0)
    local Scale = UGCMathUtility.MakeVector(1,1,1)
    local SelectTransform = UGCMathUtility.MakeTransform(SelectTargetLocation, Rotation, Scale)
    self:SetSelectTransform(SelectTransform)

    local ActorForward = UGCMathUtility.SubtractVector(self.CacheInitPosition, SelectTargetLocation)
    ActorForward = UGCMathUtility.Normal(ActorForward)
    local ActorRight = UGCMathUtility.CrossVector(ActorForward, UGCMathUtility.GetUpVector())

    local OffsetX = UGCMathUtility.MultiplyVector(ActorForward, self.AttachOffset.X)
    local OffsetY = UGCMathUtility.MultiplyVector(ActorRight, self.AttachOffset.Y)

    local PlayerLocation = UGCMathUtility.AddVector(SelectTargetLocation, OffsetX)
    PlayerLocation = UGCMathUtility.AddVector(PlayerLocation, OffsetY)
    self:GetOwnerActor():K2_SetActorLocation(PlayerLocation) 
end

function TSSJ_02:ReturnToInitLocation()
    self:GetOwnerActor():K2_SetActorLocation(self.CacheInitPosition)
end

function TSSJ_02:SetCacheTargetLocation()
    local SelectTargetLocation = self.CacheSelectTarget:K2_GetActorLocation()
    local Rotation = UGCMathUtility.MakeRotator(0,0,0)
    local Scale = UGCMathUtility.MakeVector(1,1,1)
    local SelectTransform = UGCMathUtility.MakeTransform(SelectTargetLocation, Rotation, Scale)
    self:SetSelectTransform(SelectTransform)
end

return TSSJ_02