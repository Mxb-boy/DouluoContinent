---@class HWSCJ_02_C:PESkillTemplate_Base_C
---@field ProjectileList ULuaArrayHelper<AUniversalProjectileCore>
--Edit Below--
local HWSCJ_02 = {}
 
function HWSCJ_02:OnEnableSkill_BP()
    HWSCJ_02.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_02:OnDisableSkill_BP()
    HWSCJ_02.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_02:OnActivateSkill_BP()
    HWSCJ_02.SuperClass.OnActivateSkill_BP(self)
end

function HWSCJ_02:OnDeActivateSkill_BP()
    HWSCJ_02.SuperClass.OnDeActivateSkill_BP(self)
end

function HWSCJ_02:CanActivateSkill_BP()
    return HWSCJ_02.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_02