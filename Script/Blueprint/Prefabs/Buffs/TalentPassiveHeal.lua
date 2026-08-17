---@class TalentPassiveHeal_C:PersistEffectBuff
--Edit Below--
local TalentPassiveHeal = {}

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")
local TalentEffectMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentEffectMgr")

local function GetBuffOwnerActor(Buff)
    if Buff.OwnerActor ~= nil then
        return Buff.OwnerActor
    end

    if Buff.GetCauser ~= nil then
        local Success, OwnerActor = pcall(Buff.GetCauser, Buff)
        if Success then
            return OwnerActor
        end
    end

    return nil
end

local function GetHealthValue(OwnerActor, AttributeName)
    if UGCAttributeSystem ~= nil and UGCAttributeSystem.GetGameAttributeValue ~= nil then
        local Success, Value = pcall(UGCAttributeSystem.GetGameAttributeValue, OwnerActor, AttributeName)
        if Success and tonumber(Value) ~= nil then
            return tonumber(Value)
        end
    end

    if UGCPawnAttrSystem ~= nil then
        local Getter = AttributeName == "HealthMax" and UGCPawnAttrSystem.GetHealthMax or UGCPawnAttrSystem.GetHealth
        if Getter ~= nil then
            local Success, Value = pcall(Getter, OwnerActor)
            if Success then
                return tonumber(Value)
            end
        end
    end

    return nil
end

local function SetHealthValue(OwnerActor, Value)
    if UGCAttributeSystem ~= nil and UGCAttributeSystem.SetGameAttributeValue ~= nil then
        local Success = pcall(UGCAttributeSystem.SetGameAttributeValue, OwnerActor, "Health", Value)
        if Success then
            return true
        end
    end

    if UGCPawnAttrSystem ~= nil and UGCPawnAttrSystem.SetHealth ~= nil then
        return pcall(UGCPawnAttrSystem.SetHealth, OwnerActor, Value)
    end
    return false
end
 
-- buff启动条件
--[[
function TalentPassiveHeal:CanApply_BP(OwnerActor)
-- return true
end
--]]

-- buff开始
--[[
function TalentPassiveHeal:OnApply_BP(OwnerActor)

end
--]]

-- buff结束
--[[
function TalentPassiveHeal:OnUnApply_BP(OwnerActor, Reason)

end
--]]

-- buff合并条件，A为当前身上已有buff，B为外来buff，当要挂载外来buff时会判断A.CanMerge(B)
--[[
function TalentPassiveHeal:CanMerge_BP(PersistEffect)
-- return true
end
--]]

-- buff合并，A为当前身上已有buff，B为外来buff，调用A.OnMerge(B)
--[[
function TalentPassiveHeal:OnMerge_BP(PersistEffect)

end
--]]

-- 开启Tick需要SetTickEnable(true)，或buff为间隔触发类型会自动开启
--[[
function TalentPassiveHeal:Tick_BP(OwnerActor, DeltaTime)

end
--]]

--[[
function TalentPassiveHeal:OnInterrupted_BP(OwnerActor)

end
--]]

-- buff总持续时长变化，如修改ApplyTime、修改StackNum
--[[
function TalentPassiveHeal:OnTotalDurationChange_BP(PreTime, CurTime)

end
--]]

-- buff堆叠层数变化
--[[
function TalentPassiveHeal:OnStackChange_BP(PreNum, CurNum)

end
--]]

-- buff触发前条件判断
--[[
function TalentPassiveHeal:CanTrigger_BP()
	return true
end
--]]

-- buff触发效果
--[[
function TalentPassiveHeal:OnTrigger_BP(Delta)

end
--]]

function TalentPassiveHeal:CanApply_BP(OwnerActor)
    return OwnerActor ~= nil and OwnerActor.PlayerState ~= nil
end

function TalentPassiveHeal:OnApply_BP(OwnerActor)
    self.OwnerActor = OwnerActor
end

function TalentPassiveHeal:LuaFunction()
    if UGCGameSystem.IsServer ~= nil and not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    local PlayerState = OwnerActor ~= nil and OwnerActor.PlayerState or nil
    if OwnerActor == nil or PlayerState == nil then
        ugcprint("[TalentPassiveHeal] apply skipped: owner actor or player state is nil")
        return
    end

    local CurrentHealth = GetHealthValue(OwnerActor, "Health")
    local MaxHealth = GetHealthValue(OwnerActor, "HealthMax")
    if CurrentHealth == nil or MaxHealth == nil or CurrentHealth <= 0 or MaxHealth <= 0 then
        ugcprint("[TalentPassiveHeal] apply skipped: invalid health values")
        return
    end

    local Config = TalentConfig.PassiveBuffs ~= nil and TalentConfig.PassiveBuffs.Heal or nil
    local BasePercent = tonumber(Config ~= nil and Config.HealMaxHealthPercent or nil) or 0
    local TalentBonus = TalentEffectMgr:GetPassiveBuffStatBonus(PlayerState, "Heal", "HealMaxHealthPercent")
    local HealPercent = math.max(0, BasePercent + TalentBonus)
    local TargetHealth = math.min(MaxHealth, CurrentHealth + MaxHealth * HealPercent)
    local ActualHeal = math.max(0, TargetHealth - CurrentHealth)
    if ActualHeal <= 0 then
        return
    end

    if SetHealthValue(OwnerActor, TargetHealth) then
        ugcprint("[TalentPassiveHeal] heal=" .. tostring(ActualHeal) .. ", percent=" .. tostring(HealPercent))
    else
        ugcprint("[TalentPassiveHeal] heal failed")
    end
end

return TalentPassiveHeal
