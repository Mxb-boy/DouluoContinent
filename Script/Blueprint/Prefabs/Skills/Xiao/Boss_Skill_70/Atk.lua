---@class Atk_C:PESkillTemplate_Base_C
--Edit Below--
local Atk = {}
 
function Atk:OnEnableSkill_BP()
    Atk.SuperClass.OnEnableSkill_BP(self)
end

function Atk:OnDisableSkill_BP()
    Atk.SuperClass.OnDisableSkill_BP(self)
end

function Atk:OnActivateSkill_BP()
    Atk.SuperClass.OnActivateSkill_BP(self)
end

function Atk:OnDeActivateSkill_BP()
    Atk.SuperClass.OnDeActivateSkill_BP(self)
end

function Atk:CanActivateSkill_BP()
    return Atk.SuperClass.CanActivateSkill_BP(self)
end

return Atk