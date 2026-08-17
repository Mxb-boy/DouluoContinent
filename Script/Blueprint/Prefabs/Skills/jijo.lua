---@class jijo_C:PESkillTemplate_Base_C
--Edit Below--
local jijo = {}
 
function jijo:OnEnableSkill_BP()
    jijo.SuperClass.OnEnableSkill_BP(self)
end

function jijo:OnDisableSkill_BP()
    jijo.SuperClass.OnDisableSkill_BP(self)
end

function jijo:OnActivateSkill_BP()
    jijo.SuperClass.OnActivateSkill_BP(self)
end

function jijo:OnDeActivateSkill_BP()
    jijo.SuperClass.OnDeActivateSkill_BP(self)
end

function jijo:CanActivateSkill_BP()
    return jijo.SuperClass.CanActivateSkill_BP(self)
end

return jijo