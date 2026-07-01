---@class BP_HalfbodyMachinery_Skill_3_C:PESkillTemplate_Base_C
--Edit Below--
local BP_HalfbodyMachinery_Skill_3 = {}
 
function BP_HalfbodyMachinery_Skill_3:OnEnableSkill_BP()
    BP_HalfbodyMachinery_Skill_3.SuperClass.OnEnableSkill_BP(self)
end

function BP_HalfbodyMachinery_Skill_3:OnDisableSkill_BP()
    BP_HalfbodyMachinery_Skill_3.SuperClass.OnDisableSkill_BP(self)
end

function BP_HalfbodyMachinery_Skill_3:OnActivateSkill_BP()
    BP_HalfbodyMachinery_Skill_3.SuperClass.OnActivateSkill_BP(self)
end

function BP_HalfbodyMachinery_Skill_3:OnDeActivateSkill_BP()
    BP_HalfbodyMachinery_Skill_3.SuperClass.OnDeActivateSkill_BP(self)
end

function BP_HalfbodyMachinery_Skill_3:CanActivateSkill_BP()
    return BP_HalfbodyMachinery_Skill_3.SuperClass.CanActivateSkill_BP(self)
end

return BP_HalfbodyMachinery_Skill_3