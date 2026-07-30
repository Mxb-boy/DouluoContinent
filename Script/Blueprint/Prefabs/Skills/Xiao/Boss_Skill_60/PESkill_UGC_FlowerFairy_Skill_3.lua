---@class PESkill_UGC_FlowerFairy_Skill_3_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_UGC_FlowerFairy_Skill_3 = {}
 
function PESkill_UGC_FlowerFairy_Skill_3:OnEnableSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_3.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_3:OnDisableSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_3.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_3:OnActivateSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_3.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_3:OnDeActivateSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_3.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_3:CanActivateSkill_BP()
    return PESkill_UGC_FlowerFairy_Skill_3.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_UGC_FlowerFairy_Skill_3