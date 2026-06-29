---@class HWSCJ_05_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_05 = {}
 
function HWSCJ_05:OnEnableSkill_BP()
    HWSCJ_05.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_05:OnDisableSkill_BP()
    HWSCJ_05.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_05:OnActivateSkill_BP()
    HWSCJ_05.SuperClass.OnActivateSkill_BP(self)
    local owner = self:GetOwner()
    owner:SetSocketVisible("item_r", false)
end

function HWSCJ_05:OnDeActivateSkill_BP()
    HWSCJ_05.SuperClass.OnDeActivateSkill_BP(self)
    local owner = self:GetOwner()
    owner:SetSocketVisible("item_r", true)
end

function HWSCJ_05:CanActivateSkill_BP()
    return HWSCJ_05.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_05