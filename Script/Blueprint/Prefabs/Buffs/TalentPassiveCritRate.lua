---@class TalentPassiveCritRate_C:PersistEffectBuff
---@field EnableMoveSpeed float
--Edit Below--
local TalentPassiveCritRate = {}

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local function GetCritRateBonus()
    local Config = TalentConfig.PassiveBuffs ~= nil and TalentConfig.PassiveBuffs.CritRate or nil
    return math.max(0, tonumber(Config ~= nil and Config.CritRate or nil) or 0)
end

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

function TalentPassiveCritRate:CanApply_BP(OwnerActor)
    return OwnerActor ~= nil and OwnerActor.PlayerState ~= nil
end

function TalentPassiveCritRate:OnApply_BP(OwnerActor)
    self.OwnerActor = OwnerActor
    self:LuaFunction()
end

function TalentPassiveCritRate:OnUnApply_BP(OwnerActor, Reason)
    self.OwnerActor = OwnerActor or self.OwnerActor
end

function TalentPassiveCritRate:LuaFunction()
    if not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    if OwnerActor == nil then
        ugcprint("[TalentPassiveCritRate] apply skipped: owner actor is nil")
        return
    end

    local PlayerState = OwnerActor.PlayerState
    if PlayerState == nil then
        ugcprint("[TalentPassiveCritRate] apply skipped: player state is nil")
        return
    end

    local CritRateBonus = GetCritRateBonus()
    PlayerState.TalentBuff_CritRate = CritRateBonus
    ugcprint("[TalentPassiveCritRate] apply crit rate=" .. tostring(CritRateBonus))
end

function TalentPassiveCritRate:LuaFunction_1()
    if not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    local PlayerState = OwnerActor ~= nil and OwnerActor.PlayerState or nil
    if PlayerState ~= nil then
        PlayerState.TalentBuff_CritRate = 0
        ugcprint("[TalentPassiveCritRate] remove crit rate buff")
    else
        ugcprint("[TalentPassiveCritRate] remove skipped: player state is nil")
    end
end

function TalentPassiveCritRate:LuaFunction_2()
end

function TalentPassiveCritRate:LuaFunction_3()
end

function TalentPassiveCritRate:LuaFunction_4()
end

function TalentPassiveCritRate:LuaFunction_5()
end

function TalentPassiveCritRate:LuaFunction_6()
end

function TalentPassiveCritRate:LuaFunction_7()
end

function TalentPassiveCritRate:LuaFunction_8()
end

function TalentPassiveCritRate:LuaFunction_9()
end

return TalentPassiveCritRate
