---@class TalentPassiveCritDamage_C:PersistEffectBuff
---@field EnableMoveSpeed float
--Edit Below--
local TalentPassiveCritDamage = {}

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local function GetCritMultiplierBonus()
    local Config = TalentConfig.PassiveBuffs ~= nil and TalentConfig.PassiveBuffs.CritDamage or nil
    return math.max(0, tonumber(Config ~= nil and Config.CritMultiplierFlat or nil) or 0)
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

function TalentPassiveCritDamage:CanApply_BP(OwnerActor)
    return OwnerActor ~= nil and OwnerActor.PlayerState ~= nil
end

function TalentPassiveCritDamage:OnApply_BP(OwnerActor)
    self.OwnerActor = OwnerActor
    self:LuaFunction()
end

function TalentPassiveCritDamage:OnUnApply_BP(OwnerActor, Reason)
    self.OwnerActor = OwnerActor or self.OwnerActor
end

function TalentPassiveCritDamage:LuaFunction()
    if not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    if OwnerActor == nil then
        ugcprint("[TalentPassiveCritDamage] apply skipped: owner actor is nil")
        return
    end

    local PlayerState = OwnerActor.PlayerState
    if PlayerState == nil then
        ugcprint("[TalentPassiveCritDamage] apply skipped: player state is nil")
        return
    end

    local CritMultiplierBonus = GetCritMultiplierBonus()
    PlayerState.TalentBuff_CritMultiplierFlat = CritMultiplierBonus
    ugcprint("[TalentPassiveCritDamage] apply crit multiplier=" .. tostring(CritMultiplierBonus))
end

function TalentPassiveCritDamage:LuaFunction_1()
    if not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    local PlayerState = OwnerActor ~= nil and OwnerActor.PlayerState or nil
    if PlayerState ~= nil then
        PlayerState.TalentBuff_CritMultiplierFlat = 0
        ugcprint("[TalentPassiveCritDamage] remove crit damage buff")
    else
        ugcprint("[TalentPassiveCritDamage] remove skipped: player state is nil")
    end
end

function TalentPassiveCritDamage:LuaFunction_2()
end

function TalentPassiveCritDamage:LuaFunction_3()
end

function TalentPassiveCritDamage:LuaFunction_4()
end

function TalentPassiveCritDamage:LuaFunction_5()
end

function TalentPassiveCritDamage:LuaFunction_6()
end

function TalentPassiveCritDamage:LuaFunction_7()
end

function TalentPassiveCritDamage:LuaFunction_8()
end

function TalentPassiveCritDamage:LuaFunction_9()
end

return TalentPassiveCritDamage
