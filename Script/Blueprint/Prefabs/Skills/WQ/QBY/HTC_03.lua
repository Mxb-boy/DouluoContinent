---@class HTC_03_C:PESkillTemplate_Base_C
--Edit Below--
local HTC_03 = {}
 
function HTC_03:OnEnableSkill_BP()
    HTC_03.SuperClass.OnEnableSkill_BP(self)
end

function HTC_03:OnDisableSkill_BP()
    HTC_03.SuperClass.OnDisableSkill_BP(self)
end

function HTC_03:OnActivateSkill_BP()
    HTC_03.SuperClass.OnActivateSkill_BP(self)
end

function HTC_03:OnDeActivateSkill_BP()
    HTC_03.SuperClass.OnDeActivateSkill_BP(self)
end

function HTC_03:CanActivateSkill_BP()
    return HTC_03.SuperClass.CanActivateSkill_BP(self)
end

return HTC_03