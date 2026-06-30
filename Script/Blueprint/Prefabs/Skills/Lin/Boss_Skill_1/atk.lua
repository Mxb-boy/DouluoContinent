---@class atk_C:PESkillTemplate_Base_C
--Edit Below--
local atk = {}
 
function atk:OnEnableSkill_BP()
    atk.SuperClass.OnEnableSkill_BP(self)
end

function atk:OnDisableSkill_BP()
    atk.SuperClass.OnDisableSkill_BP(self)
end

function atk:OnActivateSkill_BP()
    atk.SuperClass.OnActivateSkill_BP(self)
end

function atk:OnDeActivateSkill_BP()
    atk.SuperClass.OnDeActivateSkill_BP(self)
end

function atk:CanActivateSkill_BP()
    return atk.SuperClass.CanActivateSkill_BP(self)
end

return atk