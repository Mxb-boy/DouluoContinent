---@class BP_UGC_Prophet_Skill_Atk_C:PESkillTemplate_Base_C
--Edit Below--
local BP_UGC_Prophet_Skill_Atk = {}
 
function BP_UGC_Prophet_Skill_Atk:OnEnableSkill_BP()
    BP_UGC_Prophet_Skill_Atk.SuperClass.OnEnableSkill_BP(self)
end

function BP_UGC_Prophet_Skill_Atk:OnDisableSkill_BP()
    BP_UGC_Prophet_Skill_Atk.SuperClass.OnDisableSkill_BP(self)
end

function BP_UGC_Prophet_Skill_Atk:OnActivateSkill_BP()
    BP_UGC_Prophet_Skill_Atk.SuperClass.OnActivateSkill_BP(self)
end

function BP_UGC_Prophet_Skill_Atk:OnDeActivateSkill_BP()
    BP_UGC_Prophet_Skill_Atk.SuperClass.OnDeActivateSkill_BP(self)
end

function BP_UGC_Prophet_Skill_Atk:CanActivateSkill_BP()
    return BP_UGC_Prophet_Skill_Atk.SuperClass.CanActivateSkill_BP(self)
end

return BP_UGC_Prophet_Skill_Atk