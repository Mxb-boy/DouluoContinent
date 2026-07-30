---@class PESkill_UGC_FlowerFairy_Skill_1_C:PESkillTemplate_Base_C
--Edit Below--
local PESkill_UGC_FlowerFairy_Skill_1 = {}
 
function PESkill_UGC_FlowerFairy_Skill_1:OnEnableSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_1.SuperClass.OnEnableSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_1:OnDisableSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_1.SuperClass.OnDisableSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_1:OnActivateSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_1.SuperClass.OnActivateSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_1:OnDeActivateSkill_BP()
    PESkill_UGC_FlowerFairy_Skill_1.SuperClass.OnDeActivateSkill_BP(self)
end

function PESkill_UGC_FlowerFairy_Skill_1:CanActivateSkill_BP()
    return PESkill_UGC_FlowerFairy_Skill_1.SuperClass.CanActivateSkill_BP(self)
end

return PESkill_UGC_FlowerFairy_Skill_1