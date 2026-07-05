---@class HWSCJ_05_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_05 = {}

local function SetOwnerSocketVisible(Skill, bVisible)
    local owner = nil
    if Skill.GetOwner ~= nil then
        owner = Skill:GetOwner()
    else
        owner = Skill.Owner or Skill.Instigator or Skill.Caster
    end

    if owner ~= nil and owner.SetSocketVisible ~= nil then
        owner:SetSocketVisible("item_r", bVisible)
    end
end
  
function HWSCJ_05:OnEnableSkill_BP()
    HWSCJ_05.SuperClass.OnEnableSkill_BP(self)
end

function HWSCJ_05:OnDisableSkill_BP()
    HWSCJ_05.SuperClass.OnDisableSkill_BP(self)
end

function HWSCJ_05:OnActivateSkill_BP()
    HWSCJ_05.SuperClass.OnActivateSkill_BP(self)
    SetOwnerSocketVisible(self, false)
end

function HWSCJ_05:OnDeActivateSkill_BP()
    HWSCJ_05.SuperClass.OnDeActivateSkill_BP(self)
    SetOwnerSocketVisible(self, true)
end

function HWSCJ_05:CanActivateSkill_BP()
    return HWSCJ_05.SuperClass.CanActivateSkill_BP(self)
end

return HWSCJ_05
