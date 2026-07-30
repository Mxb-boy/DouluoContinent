---@class BP_UGC_Bookkeeper_Skill_1_C:PESkillTemplate_Base_C
--Edit Below--
local BP_UGC_Bookkeeper_Skill_1 = {}
 
function BP_UGC_Bookkeeper_Skill_1:OnEnableSkill_BP()
    BP_UGC_Bookkeeper_Skill_1.SuperClass.OnEnableSkill_BP(self)
end

function BP_UGC_Bookkeeper_Skill_1:OnDisableSkill_BP()
    BP_UGC_Bookkeeper_Skill_1.SuperClass.OnDisableSkill_BP(self)
end

function BP_UGC_Bookkeeper_Skill_1:OnActivateSkill_BP()
    BP_UGC_Bookkeeper_Skill_1.SuperClass.OnActivateSkill_BP(self)
end

function BP_UGC_Bookkeeper_Skill_1:OnDeActivateSkill_BP()
    BP_UGC_Bookkeeper_Skill_1.SuperClass.OnDeActivateSkill_BP(self)
end

function BP_UGC_Bookkeeper_Skill_1:CanActivateSkill_BP()
    return BP_UGC_Bookkeeper_Skill_1.SuperClass.CanActivateSkill_BP(self)
end

return BP_UGC_Bookkeeper_Skill_1