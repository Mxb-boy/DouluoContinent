---@class BaseMons_2_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
---@field MonsterID int32
--Edit Below--
local test2 = {}
local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
local L_Enum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")
local PlayerLevelMgr = UGCGameSystem.UGCRequire("Script.Lin.PlayerLevelMgr")
local TitleMgr = UGCGameSystem.UGCRequire("Script.Xiao.TitleMgr")
local MonsterSpawnMgr = UGCGameSystem.UGCRequire("Script.Lin.MonsSpawMgr")


-- function test2:ReceiveBeginPlay()
--     test2.SuperClass.ReceiveBeginPlay(self)
-- end

-- function test2:ReceiveTick(DeltaTime)
--     test2.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function test2:ReceiveEndPlay()
--     test2.SuperClass.ReceiveEndPlay(self) 
-- end

-- function test2:GetReplicatedProperties()
--     return
-- end

-- ---受击前置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function test2:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
-- end

-- ---受击后置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function test2:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    
-- end

-- ---受击前置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function test2:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

-- ---受击后置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function test2:PostOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

---角色死亡事件
---生效范围：服务器&客户端
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param FDamageEvent DamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function test2:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    MonsterSpawnMgr.DisableMonsterCollision(self)

    if self:HasAuthority() and self.SpawnWall ~= nil then
        self.SpawnWall:OnMonsterDied(self)
    end

    if self:HasAuthority() then
        local DropID = self.MonsterID
        if EventInstigator ~= nil and EventInstigator.PlayerState ~= nil then
            local Probability_Bonus = (EventInstigator.PlayerState.Probability_Bonus or 100) - 100
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
        --[[----------------------怪物死亡给击杀者加经验------------------------]] --
        local KillExp = PlayerLevelMgr:GetWaveKillExp(self.MonsterID)
        PlayerLevelMgr:AddExp(EventInstigator, KillExp)
    end

    if self:HasAuthority() then
        TaskMgr:AddTeamTaskProgressOnServer(L_Enum.AllTask.KillMonster, 1, EventInstigator)
        TitleMgr:OnDungeonClear(EventInstigator, 2)
    end

end

-- ---状态进入事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 进入的状态
-- function test2:OnEnterTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnEnterTagState_BP: ' .. Tag)
-- end

-- ---状态退出事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 退出的状态
-- function test2:OnLeaveTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnLeaveTagState_BP: ' .. Tag)
-- end

-- ---状态打断事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 打断的状态
-- function test2:OnInterruptTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnInterruptTagState_BP' .. Tag)
-- end

-- ---行为树消息
-- ---生效范围：服务器
-- ---@param NotifyMsg string 消息
-- function test2:OnBehaviorNotify_BP(NotifyMsg)
--     ugcprint('OnBehaviorNotify_BP: ' .. NotifyMsg)
-- end

-- ---怪物的目标发生变化事件
-- ---生效范围：服务器&客户端
-- ---@param NewTarget AActor 新目标
-- ---@param OldTarget AActor 旧目标
-- function test2:OnTargetChange_BP(NewTarget, OldTarget)
    
-- end

return test2
