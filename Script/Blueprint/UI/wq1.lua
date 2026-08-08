---@class wq1_C:UUserWidget
---@field Button_154 UButton
---@field Image_181 UImage
---@field Image_182 UImage
---@field SizeBox_0 USizeBox
--Edit Below--
---@class wq1_C:UUserWidget
---@field Button_154 UButton
---@field Image_181 UImage
---@field Image_182 UImage
---@field TextBlock_515 UTextBlock
---@field TextBlock_516 UTextBlock
local wq1 = { bInitDoOnce = false }

function wq1:GetWidget(Name)
    local Widget = self[Name]
    if Widget == nil and self.GetWidgetFromName ~= nil then
        Widget = self:GetWidgetFromName(Name)
    end
    return Widget
end
function wq1:Construct()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    local Button = self:GetWidget("Button_154")
    if Button ~= nil then
        Button.OnClicked:Add(self.Button_154_OnClicked, self)
    end
    self:SetSelected(false)
end
function wq1:SetSoulRingData(Data, OwnerUI)
    self.SoulRingData = Data
    self.OwnerUI = OwnerUI
    local NameText = self:GetWidget("TextBlock_515")
    if NameText ~= nil then
        NameText:SetText(tostring(Data.Name or ""))
    end
    local CountText = self:GetWidget("TextBlock_516")
    if CountText ~= nil then
        CountText:SetText(tostring(tonumber(Data.Count) or 0))
    end
    local Icon = self:GetWidget("Image_181")
    if Data.IconPath ~= nil and Data.IconPath ~= "" then
        local Texture = UE.LoadObject(Data.IconPath)
        if Texture ~= nil then
            if Icon ~= nil then
                Icon:SetBrushFromTexture(Texture)
            end
        else
            ugcprint("[wq1:SetSoulRingData] icon load failed: " .. tostring(Data.IconPath))
        end
    end
    self:SetSelected(false)
end
function wq1:SetSelected(bSelected)
    local SelectImage = self:GetWidget("Image_182")
    if SelectImage ~= nil then
        SelectImage:SetVisibility(bSelected and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end
end
function wq1:Button_154_OnClicked()
    if self.OwnerUI ~= nil and self.OwnerUI.SelectSoulRing ~= nil then
        self.OwnerUI:SelectSoulRing(self)
    end
end
return wq1
