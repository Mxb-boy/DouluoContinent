---@class Mons_9_C:PESkillTemplate_Base_C
--Edit Below--
local Mons_01 = {}
 
function Mons_01:OnEnableSkill_BP()
    Mons_01.SuperClass.OnEnableSkill_BP(self)
end

function Mons_01:OnDisableSkill_BP()
    Mons_01.SuperClass.OnDisableSkill_BP(self)
end

function Mons_01:OnActivateSkill_BP()
    Mons_01.SuperClass.OnActivateSkill_BP(self)
end

function Mons_01:OnDeActivateSkill_BP()
    Mons_01.SuperClass.OnDeActivateSkill_BP(self)
end

function Mons_01:CanActivateSkill_BP()
    return Mons_01.SuperClass.CanActivateSkill_BP(self)
end

return Mons_01