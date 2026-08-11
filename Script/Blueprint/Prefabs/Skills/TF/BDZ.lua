---@class BDZ_C:PESkillTemplate_Base_C
--Edit Below--
local BDZ = {}
 
function BDZ:OnEnableSkill_BP()
    BDZ.SuperClass.OnEnableSkill_BP(self)
end

function BDZ:OnDisableSkill_BP()
    BDZ.SuperClass.OnDisableSkill_BP(self)
end

function BDZ:OnActivateSkill_BP()
    BDZ.SuperClass.OnActivateSkill_BP(self)
end

function BDZ:OnDeActivateSkill_BP()
    BDZ.SuperClass.OnDeActivateSkill_BP(self)
end

function BDZ:CanActivateSkill_BP()
    return BDZ.SuperClass.CanActivateSkill_BP(self)
end

return BDZ