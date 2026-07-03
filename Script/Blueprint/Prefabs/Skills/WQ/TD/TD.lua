---@class TD_C:PESkillTemplate_Base_C
--Edit Below--
local TD = {}
 
function TD:OnEnableSkill_BP()
    TD.SuperClass.OnEnableSkill_BP(self)
end

function TD:OnDisableSkill_BP()
    TD.SuperClass.OnDisableSkill_BP(self)
end

function TD:OnActivateSkill_BP()
    TD.SuperClass.OnActivateSkill_BP(self)
end

function TD:OnDeActivateSkill_BP()
    TD.SuperClass.OnDeActivateSkill_BP(self)
end

function TD:CanActivateSkill_BP()
    return TD.SuperClass.CanActivateSkill_BP(self)
end

return TD