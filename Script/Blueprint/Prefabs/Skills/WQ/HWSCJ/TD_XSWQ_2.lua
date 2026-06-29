---@class TD_XSWQ_2_C:PESkillTemplate_Base_C
--Edit Below--
local TD_CS = {}
 
function TD_CS:OnEnableSkill_BP()
    TD_CS.SuperClass.OnEnableSkill_BP(self)
end

function TD_CS:OnDisableSkill_BP()
    TD_CS.SuperClass.OnDisableSkill_BP(self)
end

function TD_CS:OnActivateSkill_BP()
    TD_CS.SuperClass.OnActivateSkill_BP(self)
end

function TD_CS:OnDeActivateSkill_BP()
    TD_CS.SuperClass.OnDeActivateSkill_BP(self)
end

function TD_CS:CanActivateSkill_BP()
    return TD_CS.SuperClass.CanActivateSkill_BP(self)
end

return TD_CS