---@class LCSL_02_C:PESkillTemplate_Base_C
--Edit Below--
local LCSL_02 = {}
 
function LCSL_02:OnEnableSkill_BP()
    LCSL_02.SuperClass.OnEnableSkill_BP(self)
end

function LCSL_02:OnDisableSkill_BP()
    LCSL_02.SuperClass.OnDisableSkill_BP(self)
end

function LCSL_02:OnActivateSkill_BP()
    LCSL_02.SuperClass.OnActivateSkill_BP(self)
end

function LCSL_02:OnDeActivateSkill_BP()
    LCSL_02.SuperClass.OnDeActivateSkill_BP(self)
end

function LCSL_02:CanActivateSkill_BP()
    return LCSL_02.SuperClass.CanActivateSkill_BP(self)
end

return LCSL_02