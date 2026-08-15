---@class TalentPassiveAttack_C:PersistEffectBuff
---@field EnableMoveSpeed float
--Edit Below--
local TalentPassiveAttack = {}

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local function GetAttackBuffPercent()
    local Config = TalentConfig.PassiveBuffs ~= nil and TalentConfig.PassiveBuffs.Attack or nil
    return math.max(0, tonumber(Config ~= nil and Config.AttackPercent or nil) or 0)
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

function TalentPassiveAttack:CanApply_BP(OwnerActor)
    return OwnerActor ~= nil and OwnerActor.PlayerState ~= nil
end

function TalentPassiveAttack:OnApply_BP(OwnerActor)
    self.OwnerActor = OwnerActor
end

function TalentPassiveAttack:OnUnApply_BP(OwnerActor, Reason)
    self.OwnerActor = OwnerActor or self.OwnerActor
end

function TalentPassiveAttack:OnStackChange_BP(PreNum, CurNum)
    if self.RefreshBuff ~= nil then
        self:RefreshBuff()
    end
end

function TalentPassiveAttack:LuaFunction()
    if not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    if OwnerActor == nil then
        ugcprint("[TalentPassiveAttack] apply skipped: owner actor is nil")
        return
    end

    local PlayerState = OwnerActor.PlayerState
    if PlayerState == nil then
        ugcprint("[TalentPassiveAttack] apply skipped: player state is nil")
        return
    end

    local AttackBuffPercent = GetAttackBuffPercent()
    PlayerState.TalentBuff_AttackPercent = AttackBuffPercent
    ugcprint("[TalentPassiveAttack] apply attack percent=" .. tostring(AttackBuffPercent))
end

function TalentPassiveAttack:LuaFunction_1()
    if not UGCGameSystem.IsServer() then
        return
    end

    local OwnerActor = GetBuffOwnerActor(self)
    local PlayerState = OwnerActor ~= nil and OwnerActor.PlayerState or nil
    if PlayerState ~= nil then
        PlayerState.TalentBuff_AttackPercent = 0
        ugcprint("[TalentPassiveAttack] remove attack buff")
    else
        ugcprint("[TalentPassiveAttack] remove skipped: player state is nil")
    end
end

function TalentPassiveAttack:LuaFunction_2()
end

function TalentPassiveAttack:LuaFunction_3()
end

function TalentPassiveAttack:LuaFunction_4()
end

function TalentPassiveAttack:LuaFunction_5()
end

function TalentPassiveAttack:LuaFunction_6()
end

function TalentPassiveAttack:LuaFunction_7()
end

function TalentPassiveAttack:LuaFunction_8()
end

function TalentPassiveAttack:LuaFunction_9()
end

return TalentPassiveAttack
