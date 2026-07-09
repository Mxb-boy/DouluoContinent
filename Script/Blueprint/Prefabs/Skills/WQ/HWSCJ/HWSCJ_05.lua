---@class HWSCJ_05_C:PESkillTemplate_Base_C
--Edit Below--
local HWSCJ_05 = {}

local function SetOwnerSocketVisible(self)

end
  
function HWSCJ_05:OnEnableSkill_BP()
    HWSCJ_05.SuperClass.OnEnableSkill_BP(self)
end

pcall(function()
    if owner ~= nil and owner.SetSocketVisible ~= nil then
        owner:SetSocketVisible("item_r", bVisible)
    end
end)

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
