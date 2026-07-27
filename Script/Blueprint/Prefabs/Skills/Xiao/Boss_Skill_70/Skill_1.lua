---@class Skill_1_C:PESkillTemplate_Base_C
---@field SetterActors ULuaArrayHelper<AEmitter>
--Edit Below--
local Skill_1 = {}
 
function Skill_1:OnEnableSkill_BP()
    Skill_1.SuperClass.OnEnableSkill_BP(self)
end

function Skill_1:OnDisableSkill_BP()
    Skill_1.SuperClass.OnDisableSkill_BP(self)
end

function Skill_1:OnActivateSkill_BP()
    Skill_1.SuperClass.OnActivateSkill_BP(self)
end

function Skill_1:OnDeActivateSkill_BP()
    Skill_1.SuperClass.OnDeActivateSkill_BP(self)
end

function Skill_1:CanActivateSkill_BP()
    return Skill_1.SuperClass.CanActivateSkill_BP(self)
end

return Skill_1