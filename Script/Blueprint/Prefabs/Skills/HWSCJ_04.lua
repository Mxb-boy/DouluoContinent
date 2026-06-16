---@class HWSCJ_04_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_04 = {}
 
function HWSCJ_04:OnEnableSkill_BP()
    HWSCJ_04.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_04:OnDisableSkill_BP()
    HWSCJ_04.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_04:OnActivateSkill_BP()
    HWSCJ_04.SuperClass.OnActivateSkill_BP(self)
end

function HWSCJ_04:OnDeActivateSkill_BP()
    HWSCJ_04.SuperClass.OnDeActivateSkill_BP(self)
end

function HWSCJ_04:CanActivateSkill_BP()
    return HWSCJ_04.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_04