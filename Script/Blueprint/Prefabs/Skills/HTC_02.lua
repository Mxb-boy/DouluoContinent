---@class HTC_01_C:PESkillTemplate_Base_C
--Edit Below--
local HTC_02 = {}
 
function HTC_02:OnEnableSkill_BP()
    HTC_02.SuperClass.OnEnableSkill_BP(self)
end

function HTC_02:OnDisableSkill_BP()
    HTC_02.SuperClass.OnDisableSkill_BP(self)
end

function HTC_02:OnActivateSkill_BP()
    HTC_02.SuperClass.OnActivateSkill_BP(self)
end

function HTC_02:OnDeActivateSkill_BP()
    HTC_02.SuperClass.OnDeActivateSkill_BP(self)
end

function HTC_02:CanActivateSkill_BP()
    return HTC_02.SuperClass.CanActivateSkill_BP(self)
end

return HTC_02