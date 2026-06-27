---@class Mons_1_C:PESkillTemplate_Base_C
--Edit Below--
local Mons_1 = {}
 
function Mons_1:OnEnableSkill_BP()
    Mons_1.SuperClass.OnEnableSkill_BP(self)
end

function Mons_1:OnDisableSkill_BP()
    Mons_1.SuperClass.OnDisableSkill_BP(self)
end

function Mons_1:OnActivateSkill_BP()
    Mons_1.SuperClass.OnActivateSkill_BP(self)
end

function Mons_1:OnDeActivateSkill_BP()
    Mons_1.SuperClass.OnDeActivateSkill_BP(self)
end

function Mons_1:CanActivateSkill_BP()
    return Mons_1.SuperClass.CanActivateSkill_BP(self)
end

return Mons_1