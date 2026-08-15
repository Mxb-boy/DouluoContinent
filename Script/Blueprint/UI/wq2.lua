---@class wq2_C:UUserWidget
---@field Button_148 UButton
---@field Button_149 UButton
---@field Button_261 UButton
---@field Image_1 UImage
---@field Image_16 UImage
---@field Image_17 UImage
---@field Image_18 UImage
---@field Image_154 UImage
---@field Image_155 UImage
---@field Image_296 UImage
---@field Image_408 UImage
--Edit Below--
local wq2 = { bInitDoOnce = false }

function wq2:GetWidget(Name)
    local Widget = self[Name]
    if Widget == nil and self.GetWidgetFromName ~= nil then
        Widget = self:GetWidgetFromName(Name)
    end
    return Widget
end

function wq2:Construct()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    local GiveUpButton = self:GetWidget("Button_148")
    if GiveUpButton ~= nil then
        GiveUpButton.OnClicked:Add(self.Button_148_OnClicked, self)
    end
    local ConfirmButton = self:GetWidget("Button_149")
    if ConfirmButton ~= nil then
        ConfirmButton.OnClicked:Add(self.Button_149_OnClicked, self)
    end
end

function wq2:SetWeaponRefineResult(GunIndex, Attack, AttackSpeed, OwnerUI)
    self.GunIndex = tonumber(GunIndex)
    self.NewAttack = tonumber(Attack)
    self.NewAttackSpeed = tonumber(AttackSpeed)
    self.OwnerUI = OwnerUI
    self:SetDecisionButtonsEnabled(true)
end

function wq2:SetDecisionButtonsEnabled(bEnabled)
    for _, ButtonName in ipairs({"Button_148", "Button_149"}) do
        local Button = self:GetWidget(ButtonName)
        if Button ~= nil and Button.SetIsEnabled ~= nil then
            Button:SetIsEnabled(bEnabled == true)
        end
    end
end

function wq2:ResolveResult(bAccept)
    if self.OwnerUI == nil or self.OwnerUI.ResolveWeaponRefine == nil then
        return false
    end
    self:SetDecisionButtonsEnabled(false)
    if self.OwnerUI:ResolveWeaponRefine(bAccept) ~= true then
        self:SetDecisionButtonsEnabled(true)
        return false
    end
    return true
end

function wq2:Button_148_OnClicked()
    return self:ResolveResult(false)
end

function wq2:Button_149_OnClicked()
    return self:ResolveResult(true)
end

return wq2
