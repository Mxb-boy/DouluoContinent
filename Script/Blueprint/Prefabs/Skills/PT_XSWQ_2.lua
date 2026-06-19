---@class PT_XSWQ_2_C:PESkillTemplate_Base_C
--Edit Below--
local PT_XSWQ_2 = {}
 
function PT_XSWQ_2:OnEnableSkill_BP()
    PT_XSWQ_2.SuperClass.OnEnableSkill_BP(self)
end

function PT_XSWQ_2:OnDisableSkill_BP()
    PT_XSWQ_2.SuperClass.OnDisableSkill_BP(self)
end

function PT_XSWQ_2:OnActivateSkill_BP()
    PT_XSWQ_2.SuperClass.OnActivateSkill_BP(self)
end

function PT_XSWQ_2:OnDeActivateSkill_BP()
    PT_XSWQ_2.SuperClass.OnDeActivateSkill_BP(self)
end

function PT_XSWQ_2:CanActivateSkill_BP()
    return PT_XSWQ_2.SuperClass.CanActivateSkill_BP(self)
end

return PT_XSWQ_2