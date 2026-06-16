---@class HWSCJ_03_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_03 = {}
 
function HWSCJ_03:OnEnableSkill_BP()
    HWSCJ_03.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_03:OnDisableSkill_BP()
    HWSCJ_03.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_03:OnActivateSkill_BP()
    HWSCJ_03.SuperClass.OnActivateSkill_BP(self)
end

function HWSCJ_03:OnDeActivateSkill_BP()
    HWSCJ_03.SuperClass.OnDeActivateSkill_BP(self)
end

function HWSCJ_03:CanActivateSkill_BP()
    return HWSCJ_03.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_03