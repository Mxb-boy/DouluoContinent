---@class RLSZ_C:PESkillTemplate_Base_C
---@field Gravity int32
---@field OriginGravityScale int32
---@field PreviousState FString
--Edit Below--
local RLSZ = {}

--- 将角色传送至目标选点上方十米，遇到阻挡则传送到阻挡位置
function RLSZ:TPToSelectTransform()
    print("TPToSelectTransform")
    local SelectTrans = self:GetSelectTransform().Translation

    -- 目标位置：选点上方十米（10米 = 1000 UE单位）
    local TargetLocation = Vector.New(SelectTrans.X, SelectTrans.Y, SelectTrans.Z + 1000.0)

    -- 从选点位置向目标位置发射射线，检测传送路径上是否有阻挡
    local TraceStart = Vector.New(SelectTrans.X, SelectTrans.Y, SelectTrans.Z+50.0)
    local OwnerActor = self:GetOwnerActor()
    local bHit,HitResult = KismetSystemLibrary.LineTraceSingle(
        self,
        TraceStart,
        TargetLocation,
        ETraceTypeQuery.TraceTypeQuery1,
        false,
        {OwnerActor},
        EDrawDebugTrace.None,
        nil,
        true
    )

    local TPLocation=nil
    if bHit and HitResult then
        -- 遇到阻挡，使用射线命中位置，稍微下移避免卡墙
        TPLocation = HitResult.Location
        TPLocation.Z = TPLocation.Z - 50.0
        print("TPToSelectTransform HitResult.Location", HitResult.Location)
    else
        -- 无阻挡，使用目标位置
        TPLocation = TargetLocation
        print("TPToSelectTransform not HitResult.Location")
    end

    OwnerActor:K2_SetActorLocation(TPLocation)

    return true
end

-- function RLSZ:OnActivateSkill_BP()
--     RLSZ.SuperClass.OnActivateSkill_BP(self)
--     if UGCGameSystem.IsServer() then
--         self:TPToSelectTransform()
--     end
-- end

--- 技能反激活回调
---@param Reason EPESkillDeActivateReason 反激活原因
function RLSZ:OnDeActivateSkill_BP(Reason)
    print("RLSZ:OnDeActivateSkill_BP Reason=" .. tostring(Reason))
    -- 取消释放时恢复所有状态（显示角色、显示武器、取消无敌、恢复重力）
    self:SetOwnerPawnShow()
    self:ShowWeapon()
    self:ClearInvincible()
    -- 仅在之前设置过重力系数时才恢复，避免访问非UGC移动组件
    if self.OriginGravityScale then
        self:RestoreGravityScale()
    end
    RLSZ.SuperClass.OnDeActivateSkill_BP(self)
end

--- 设置玩家Pawn可见性
---@param bVisible boolean 是否可见
function RLSZ:SetOwnerPawnVisible(bVisible)
    print("SetOwnerPawnVisible"..tostring(bVisible))
    local OwnerActor = self:GetOwnerActor()
    if UE.IsValid(OwnerActor) then
        if bVisible then
            OwnerActor:SetActorHiddenInGame(false)
        else
            OwnerActor:SetActorHiddenInGame(true)
        end
    end
end

--- 隐藏玩家Pawn
function RLSZ:SetOwnerPawnHidden()
    self:SetOwnerPawnVisible(false)
end

--- 显示玩家Pawn
function RLSZ:SetOwnerPawnShow()
    self:SetOwnerPawnVisible(true)
end

--- 设置角色武器可见性
---@param bVisible boolean 是否可见
function RLSZ:SetOwnerWeaponVisible(bVisible)
    print("SetOwnerWeaponVisible " .. tostring(bVisible))
    local OwnerActor = self:GetOwnerActor()
    if not UE.IsValid(OwnerActor) then
        return
    end
    local WeaponManager = OwnerActor:GetWeaponManager()
    if WeaponManager then
        for _, Weapon in pairs(WeaponManager:GetAllInventoryWeaponList(false)) do
            Weapon:SetActorHiddenInGame(not bVisible)
        end
    end
end

--- 隐藏角色武器
function RLSZ:HideWeapon()
    self:SetOwnerWeaponVisible(false)
end

--- 显示角色武器
function RLSZ:ShowWeapon()
    self:SetOwnerWeaponVisible(true)
end

--- 设置无敌状态
function RLSZ:SetInvincible()
    if self:HasAuthority() then
        self:GetOwnerActor():SetGenericCharacterIsInvincible(true)
    end
end

--- 取消无敌状态
function RLSZ:ClearInvincible()
    if self:HasAuthority() then
        self:GetOwnerActor():SetGenericCharacterIsInvincible(false)
    end
end

--- 设置重力系数为蓝图配置的 Gravity 属性值
function RLSZ:SetGravityScale()
    local OwnerActor = self:GetOwnerActor()
    local MoveComp = OwnerActor:GetCharacterMovementComponent()
    if MoveComp then
        self.OriginGravityScale = MoveComp.GravityScale
        MoveComp.GravityScale = self.Gravity
    end
end

--- 恢复重力系数
function RLSZ:RestoreGravityScale()
    local OwnerActor = self:GetOwnerActor()
    local MoveComp = OwnerActor:GetCharacterMovementComponent()
    if MoveComp and self.OriginGravityScale then
        MoveComp.GravityScale = self.OriginGravityScale
    end
end

return RLSZ