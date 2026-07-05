---@class Boss_2_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
---@field MonsterID int32
--Edit Below--
local Boss_2 = {}

local DROP_SCATTER_RANGE = 300

local function GetDropBaseLoc(monster)
    local BaseLoc = monster:K2_GetActorLocation()
    if monster.CapsuleComponent ~= nil and monster.CapsuleComponent.K2_GetComponentLocation ~= nil and monster.CapsuleComponent.GetScaledCapsuleHalfHeight ~= nil then
        local CapsuleLoc = monster.CapsuleComponent:K2_GetComponentLocation()
        local HalfHeight = monster.CapsuleComponent:GetScaledCapsuleHalfHeight()
        return Vector.New(CapsuleLoc.X, CapsuleLoc.Y, CapsuleLoc.Z - HalfHeight)
    end

    return BaseLoc
end

local function MakeDropLoc(BaseLoc)
    if BaseLoc == nil then
        return nil
    end

    return Vector.New(
        BaseLoc.X + math.random(-DROP_SCATTER_RANGE, DROP_SCATTER_RANGE),
        BaseLoc.Y + math.random(-DROP_SCATTER_RANGE, DROP_SCATTER_RANGE),
        BaseLoc.Z
    )
end

local function SpawnDrop(monster, ItemID, Count)
    local BaseLoc = GetDropBaseLoc(monster)
    local DropLoc = MakeDropLoc(BaseLoc)
    return UGCItemSystemV2.SpawnPickupWrapper(DropLoc, ItemID, Count)
end

local function DisableMonsterCollision(monster)
    if monster.HitBox ~= nil then
        monster.HitBox:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end

    if monster.StaticMesh ~= nil then
        monster.StaticMesh:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end
end

-- function Boss_2:ReceiveBeginPlay()
--     Boss_2.SuperClass.ReceiveBeginPlay(self)
-- end

-- function Boss_2:ReceiveTick(DeltaTime)
--     Boss_2.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function Boss_2:ReceiveEndPlay()
--     Boss_2.SuperClass.ReceiveEndPlay(self) 
-- end

-- function Boss_2:GetReplicatedProperties()
--     return
-- end

-- ---受击前置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Boss_2:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
-- end

-- ---受击后置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Boss_2:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    
-- end

-- ---受击前置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Boss_2:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

-- ---受击后置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Boss_2:PostOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

---角色死亡事件
---生效范围：服务器&客户端
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param FDamageEvent DamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function Boss_2:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    DisableMonsterCollision(self)

    if self:HasAuthority() and self.SpawnWall ~= nil then
        self.SpawnWall:OnMonsterDied(self)
    end

    if self:HasAuthority() then
        -- 只有服务端才可以掉落
        local HasDrop = false

        if math.random(1, 100) <= 60 then
            SpawnDrop(self, 8310037, 1)
            HasDrop = true
        end

        if math.random(1, 100) <= 20 then
            SpawnDrop(self, 8310065, 1)
            HasDrop = true
        end

        if math.random(1, 100) <= 20 then
            SpawnDrop(self, 8310035, math.random(2, 5))
            HasDrop = true
        end

        if math.random(1, 100) <= 5 then
            SpawnDrop(self, 8310036, 1)
        end

        if not HasDrop then
            local GuaranteeIndex = math.random(1, 3)
            if GuaranteeIndex == 1 then
                SpawnDrop(self, 8310037, 1)
            elseif GuaranteeIndex == 2 then
                SpawnDrop(self, 8310065, 1)
            else
                SpawnDrop(self, 8310035, math.random(2, 5))
            end
        end
    end
end

-- ---状态进入事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 进入的状态
-- function Boss_2:OnEnterTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnEnterTagState_BP: ' .. Tag)
-- end

-- ---状态退出事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 退出的状态
-- function Boss_2:OnLeaveTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnLeaveTagState_BP: ' .. Tag)
-- end

-- ---状态打断事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 打断的状态
-- function Boss_2:OnInterruptTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnInterruptTagState_BP' .. Tag)
-- end

-- ---行为树消息
-- ---生效范围：服务器
-- ---@param NotifyMsg string 消息
-- function Boss_2:OnBehaviorNotify_BP(NotifyMsg)
--     ugcprint('OnBehaviorNotify_BP: ' .. NotifyMsg)
-- end

-- ---怪物的目标发生变化事件
-- ---生效范围：服务器&客户端
-- ---@param NewTarget AActor 新目标
-- ---@param OldTarget AActor 旧目标
-- function Boss_2:OnTargetChange_BP(NewTarget, OldTarget)
    
-- end

return Boss_2
