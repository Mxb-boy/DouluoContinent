---@class HWSCJ_1_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_1 = {}
 
function HWSCJ_1:OnEnableSkill_BP()
    HWSCJ_1.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_1:OnDisableSkill_BP()
    HWSCJ_1.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_1:OnActivateSkill_BP()
    HWSCJ_1.SuperClass.OnActivateSkill_BP(self)
end

function HWSCJ_1:OnDeActivateSkill_BP()
    HWSCJ_1.SuperClass.OnDeActivateSkill_BP(self)
end

function HWSCJ_1:CanActivateSkill_BP()
    return HWSCJ_1.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_1