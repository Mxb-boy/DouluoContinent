---@class PESkill_UGC_Commander_Skill_Atk_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_UGC_Commander_Skill_Atk = {}
 
function PESkill_UGC_Commander_Skill_Atk:OnEnableSkill_BP()
    PESkill_UGC_Commander_Skill_Atk.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_UGC_Commander_Skill_Atk:OnDisableSkill_BP()
    PESkill_UGC_Commander_Skill_Atk.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_UGC_Commander_Skill_Atk:OnActivateSkill_BP()
    PESkill_UGC_Commander_Skill_Atk.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_UGC_Commander_Skill_Atk:OnDeActivateSkill_BP()
    PESkill_UGC_Commander_Skill_Atk.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_UGC_Commander_Skill_Atk:CanActivateSkill_BP()
    return PESkill_UGC_Commander_Skill_Atk.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_UGC_Commander_Skill_Atk