---@class HWSCJ_2_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_2 = {}
 
function HWSCJ_2:OnEnableSkill_BP()
    HWSCJ_2.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_2:OnDisableSkill_BP()
    HWSCJ_2.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_2:OnActivateSkill_BP()
    HWSCJ_2.SuperClass.OnActivateSkill_BP(self)
end

function HWSCJ_2:OnDeActivateSkill_BP()
    HWSCJ_2.SuperClass.OnDeActivateSkill_BP(self)
end

function HWSCJ_2:CanActivateSkill_BP()
    return HWSCJ_2.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_2