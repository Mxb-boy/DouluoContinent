---@class Boss_1_C:BP_UGC_GenericMobPawn_Base_C
---@field HitBox UCapsuleComponent
---@field MonsterID int32
--Edit Below--
local Boss_1 = {}
local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
local L_Enum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")

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

-- function Boss_1:ReceiveBeginPlay()
--     Boss_1.SuperClass.ReceiveBeginPlay(self)
-- end

-- function Boss_1:ReceiveTick(DeltaTime)
--     Boss_1.SuperClass.ReceiveTick(self, DeltaTime)
-- end

-- function Boss_1:ReceiveEndPlay()
--     Boss_1.SuperClass.ReceiveEndPlay(self) 
-- end

-- function Boss_1:GetReplicatedProperties()
--     return
-- end

-- ---受击前置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Boss_1:PreTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
     
-- end

-- ---受击后置事件
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- function Boss_1:PostTakeDamageEvent(Damage, EventInstigator, DamageCauser, DamageContext)
    
-- end

-- ---受击前置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Boss_1:PreOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

-- ---受击后置伤害修改
-- ---生效范围：服务器
-- ---@param Damage float 伤害值
-- ---@param EventInstigator AController 伤害来源的Controller
-- ---@param DamageCauser AActor 伤害来源
-- ---@param DamageContext FGameMagnitudeContext  伤害上下文
-- ---@return float 修改后的伤害值
-- function Boss_1:PostOverrideDamage(Damage, EventInstigator, DamageCauser, DamageContext)
--     return Damage
-- end

---角色死亡事件
---生效范围：服务器&客户端
---@param Damage float 伤害值
---@param EventInstigator AController 伤害来源的Controller
---@param DamageCauser AActor 伤害来源
---@param FDamageEvent DamageEvent 伤害事件
---@param DamageTypeID int32 伤害类型
function Boss_1:BPDie(KillingDamage, EventInstigator, DamageCauser, DamageEvent, DamageTypeID)
    DisableMonsterCollision(self)

    local HasAuthority = self:HasAuthority()

    if HasAuthority and self.SpawnWall ~= nil then
        self.SpawnWall:OnMonsterDied(self)
    end

    if HasAuthority then
        -- 只有服务端才可以掉落
        local HasDrop = false

        local RollSoulRing = math.random(1, 100)
        if RollSoulRing <= 70 then
            SpawnDrop(self, 8310038, 1)
            HasDrop = true
        end

        local RollMaterial = math.random(1, 100)
        if RollMaterial <= 25 then
            local Count = math.random(2, 4)
            SpawnDrop(self, 8310035, Count)
            HasDrop = true
        end

        local RollRare = math.random(1, 100)
        if RollRare <= 5 then
            SpawnDrop(self, 8310041, 1)
            HasDrop = true
        end

        if math.random(1, 100) <= 5 then
            SpawnDrop(self, 8310036, 1)
        end

        if not HasDrop then
            local GuaranteeIndex = math.random(1, 3)
            if GuaranteeIndex == 1 then
                SpawnDrop(self, 8310038, 1)
            elseif GuaranteeIndex == 2 then
                local Count = math.random(2, 4)
                SpawnDrop(self, 8310035, Count)
            else
                SpawnDrop(self, 8310041, 1)
            end
        end

    end

    if self:HasAuthority() then
        TaskMgr:AddTeamTaskProgressOnServer(L_Enum.AllTask.KillMonster, 1, EventInstigator)
    end
end

-- ---状态进入事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 进入的状态
-- function Boss_1:OnEnterTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnEnterTagState_BP: ' .. Tag)
-- end

-- ---状态退出事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 退出的状态
-- function Boss_1:OnLeaveTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnLeaveTagState_BP: ' .. Tag)
-- end

-- ---状态打断事件
-- ---生效范围：服务器&客户端
-- ---@param DynamicState FGameplayTag 打断的状态
-- function Boss_1:OnInterruptTagState_BP(DynamicState)
--     local Tag = BlueprintGameplayTagLibrary.GetTagName(DynamicState)
--     ugcprint('OnInterruptTagState_BP' .. Tag)
-- end

-- ---行为树消息
-- ---生效范围：服务器
-- ---@param NotifyMsg string 消息
-- function Boss_1:OnBehaviorNotify_BP(NotifyMsg)
--     ugcprint('OnBehaviorNotify_BP: ' .. NotifyMsg)
-- end

-- ---怪物的目标发生变化事件
-- ---生效范围：服务器&客户端
-- ---@param NewTarget AActor 新目标
-- ---@param OldTarget AActor 旧目标
-- function Boss_1:OnTargetChange_BP(NewTarget, OldTarget)
    
-- end

return Boss_1
