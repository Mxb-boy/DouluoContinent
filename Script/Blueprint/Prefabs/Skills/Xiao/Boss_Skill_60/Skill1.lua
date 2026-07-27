---@class Skill1_C:PESkillTemplate_Base_C
--Edit Below--
local Skill1 = {}
 
function Skill1:OnEnableSkill_BP()
    Skill1.SuperClass.OnEnableSkill_BP(self)
end

function Skill1:OnDisableSkill_BP()
    Skill1.SuperClass.OnDisableSkill_BP(self)
end

function Skill1:OnActivateSkill_BP()
    Skill1.SuperClass.OnActivateSkill_BP(self)
end

function Skill1:OnDeActivateSkill_BP()
    Skill1.SuperClass.OnDeActivateSkill_BP(self)
end

function Skill1:CanActivateSkill_BP()
    return Skill1.SuperClass.CanActivateSkill_BP(self)
end

return Skill1