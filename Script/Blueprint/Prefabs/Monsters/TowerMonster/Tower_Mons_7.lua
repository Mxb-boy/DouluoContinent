---@class Tower_Mons_7_C:Tower_Mons_1_C
--Edit Below--
local Tower_Mons_7 = {}

local SHAKE_TYPE_RANDOM = 0 -- EPESkillCameraShakeType::Random
local SHAKE_SCALE = 0.3
local SHAKE_DURATION = 0

function Tower_Mons_7:ReceiveBeginPlay()
    Tower_Mons_7.SuperClass.ReceiveBeginPlay(self)
    self.ShakingPlayers = {}
    self.OutBox.OnComponentHit:Add(self.OutBox_OnComponentHit, self);
    self.InBox.OnComponentBeginOverlap:Add(self.InBox_OnComponentBeginOverlap, self);
    self.InBox.OnComponentEndOverlap:Add(self.InBox_OnComponentEndOverlap, self);
    self.OutBox.OnComponentBeginOverlap:Add(self.OutBox_OnComponentBeginOverlap, self);
    self.OutBox.OnComponentEndOverlap:Add(self.OutBox_OnComponentEndOverlap, self);
end
-- function Tower_Mons_7:ReceiveBeginPlay()
--     Tower_Mons_7.SuperClass.ReceiveBeginPlay(self)
-- end

-- function Tower_Mons_7:ReceiveTick(DeltaTime)
--     Tower_Mons_7.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function Tower_Mons_7:ReceiveEndPlay()
--     Tower_Mons_7.SuperClass.ReceiveEndPlay(self) 
-- end

-- function Tower_Mons_7:GetReplicatedProperties()
--     return
-- end

-- ---受击前置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Tower_Mons_7:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
-- end

-- ---受击后置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Tower_Mons_7:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    
-- end

-- ---受击前置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Tower_Mons_7:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

-- ---受击后置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Tower_Mons_7:PostOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

---角色死亡事件
---生效范围：服务器&客户端
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param FDamageEvent DamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function Tower_Mons_7:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    Tower_Mons_7.SuperClass.BPDie(self, KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)

    if self:HasAuthority() then
        -- 只有服务端才可以掉落
        self.UGCPresetCommonDropItemComponent:StartDrop(self, EventInstigator, {})
    end
end

-- ---状态进入事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 进入的状态
-- function Tower_Mons_7:OnEnterTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnEnterTagState_BP: ' .. Tag)
-- end

-- ---状态退出事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 退出的状态
-- function Tower_Mons_7:OnLeaveTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnLeaveTagState_BP: ' .. Tag)
-- end

-- ---状态打断事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 打断的状态
-- function Tower_Mons_7:OnInterruptTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnInterruptTagState_BP' .. Tag)
-- end

-- ---行为树消息
-- ---生效范围：服务器
-- ---@param NotifyMsg string 消息
-- function Tower_Mons_7:OnBehaviorNotify_BP(NotifyMsg)
--     ugcprint('OnBehaviorNotify_BP: ' .. NotifyMsg)
-- end

-- ---怪物的目标发生变化事件
-- ---生效范围：服务器&客户端
-- ---@param NewTarget AActor 新目标
-- ---@param OldTarget AActor 旧目标
-- function Tower_Mons_7:OnTargetChange_BP(NewTarget, OldTarget)
    
-- end

function Tower_Mons_7:OutBox_OnComponentHit(HitComponent, OtherActor, OtherComp, NormalImpulse, Hit)
    return nil;
end

function Tower_Mons_7:InBox_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex,
    bFromSweep, SweepResult)
    if not self:HasAuthority() then
        return
    end

    local pc = UGCGameSystem.GetPlayerControllerByPlayerPawn(OtherActor)
    if pc == nil then
        return
    end

    UGCGameSystem.ApplyDamage(OtherActor, 99999999999999999, pc, self, {})
end

function Tower_Mons_7:InBox_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    return nil;
end

function Tower_Mons_7:OutBox_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex,
    bFromSweep, SweepResult)
    if not self:HasAuthority() then
        return
    end

    local pc = UGCGameSystem.GetPlayerControllerByPlayerPawn(OtherActor)
    if pc == nil then
        return
    end

    if self.ShakingPlayers[pc] then
        return
    end

    UnrealNetwork.CallUnrealRPC(pc, pc, "Client_SetTowerOutBoxVisible", true)
    UGCGameSystem.ClientPlayCameraShake(pc, SHAKE_TYPE_RANDOM, SHAKE_SCALE, SHAKE_DURATION)
    self.ShakingPlayers[pc] = true
end

function Tower_Mons_7:OutBox_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() then
        return
    end

    local pc = UGCGameSystem.GetPlayerControllerByPlayerPawn(OtherActor)
    if pc == nil then
        return
    end

    self.ShakingPlayers[pc] = nil

    UnrealNetwork.CallUnrealRPC(pc, pc, "Client_SetTowerOutBoxVisible", false)
    UGCGameSystem.ClientStopCameraShake(pc, SHAKE_TYPE_RANDOM)
end
return Tower_Mons_7
