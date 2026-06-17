---@class TSSJ_01_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_01 = {}
 
function HWSCJ_01:OnEnableSkill_BP()
    HWSCJ_01.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_01:OnDisableSkill_BP()
    HWSCJ_01.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_01:OnActivateSkill_BP()
    HWSCJ_01.SuperClass.OnActivateSkill_BP(self)
end

function HWSCJ_01:OnDeActivateSkill_BP()
    HWSCJ_01.SuperClass.OnDeActivateSkill_BP(self)
end

function HWSCJ_01:CanActivateSkill_BP()
    return HWSCJ_01.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_01