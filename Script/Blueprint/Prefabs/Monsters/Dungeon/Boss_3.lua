---@class Boss_3_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
---@field MonsterID int32
--Edit Below--
local Boss_3 = {}

local function DisableMonsterCollision(monster)
    if monster.HitBox ~= nil then
        monster.HitBox:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end

    if monster.StaticMesh ~= nil then
        monster.StaticMesh:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end
end

-- function Boss_3:ReceiveBeginPlay()
--     Boss_3.SuperClass.ReceiveBeginPlay(self)
-- end

-- function Boss_3:ReceiveTick(DeltaTime)
--     Boss_3.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function Boss_3:ReceiveEndPlay()
--     Boss_3.SuperClass.ReceiveEndPlay(self) 
-- end

-- function Boss_3:GetReplicatedProperties()
--     return
-- end

-- ---受击前置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Boss_3:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
-- end

-- ---受击后置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Boss_3:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    
-- end

-- ---受击前置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Boss_3:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

-- ---受击后置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Boss_3:PostOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

---角色死亡事件
---生效范围：服务器&客户端
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param FDamageEvent DamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function Boss_3:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    DisableMonsterCollision(self)

    if self:HasAuthority() and self.SpawnWall ~= nil then
        self.SpawnWall:OnMonsterDied(self)
    end

    if self:HasAuthority() then
        local DropID = self.MonsterID
        if EventInstigator ~= nil and EventInstigator.PlayerState ~= nil then
            local Probability_Bonus = EventInstigator.PlayerState.Probability_Bonus or 0
            if Probability_Bonus > 100 then
                Probability_Bonus = 100
            end
            DropID = Probability_Bonus * 100 + self.MonsterID
        end

        -- 只有服务端才可以掉落
        if DropID ~= nil then
            self.UGCPresetCommonDropItemComponent:StartDropByProduceID(
                DropID,
                -1,
                EUGCGenerateItemEntityType.GenerateItemEntity_WrapperActor,
                nil
            )
        end
    end
end

-- ---状态进入事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 进入的状态
-- function Boss_3:OnEnterTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnEnterTagState_BP: ' .. Tag)
-- end

-- ---状态退出事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 退出的状态
-- function Boss_3:OnLeaveTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnLeaveTagState_BP: ' .. Tag)
-- end

-- ---状态打断事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 打断的状态
-- function Boss_3:OnInterruptTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnInterruptTagState_BP' .. Tag)
-- end

-- ---行为树消息
-- ---生效范围：服务器
-- ---@param NotifyMsg string 消息
-- function Boss_3:OnBehaviorNotify_BP(NotifyMsg)
--     ugcprint('OnBehaviorNotify_BP: ' .. NotifyMsg)
-- end

-- ---怪物的目标发生变化事件
-- ---生效范围：服务器&客户端
-- ---@param NewTarget AActor 新目标
-- ---@param OldTarget AActor 旧目标
-- function Boss_3:OnTargetChange_BP(NewTarget, OldTarget)
    
-- end

return Boss_3
