---@class NewUGCWidgetBlueprint_C:UUserWidget
---@field Button_97 UButton
---@field Image_55 UImage
---@field text_name UTextBlock
---@field TextBlock_94 UTextBlock
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")

local NewUGCWidgetBlueprint = { bInitDoOnce = false }
local WeaponButtonHoverImageSize = { X = 660.0, Y = 660.0 }
local WeaponButtonPressScale = 1.06
local WeaponButtonNormalScale = 1.0

function NewUGCWidgetBlueprint:Construct()
    self:LuaInit()
end

-- Bind button events once.
function NewUGCWidgetBlueprint:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    if self.Button_97 ~= nil then
        self.Button_97.OnClicked:Add(self.Button_97_OnClicked, self)
        UIEffectUtil.BindPressScale(
            self,
            self.Button_97,
            self,
            WeaponButtonPressScale,
            WeaponButtonNormalScale
        )
    end
end

-- Fill one weapon item: bottom name, button icon, and owner UI callback.
function NewUGCWidgetBlueprint:SetWeaponData(WeaponName, IconPath, OwnerUI, ItemID)
    self:SetVisibility(ESlateVisibility.Visible)
    self.WeaponName = WeaponName
    self.IconPath = IconPath
    self.OwnerUI = OwnerUI
    self.ItemID = ItemID

    if self.text_name ~= nil then
        self.text_name:SetText(WeaponName)
    end

    if self.Button_97 == nil or IconPath == nil then
        return
    end

    local IconTexture = UE.LoadObject(IconPath)
    if IconTexture == nil then
        return
    end

    self:SetButtonTexture(self.Button_97, IconTexture)
end

-- Hide this item when there is no matching backpack weapon.
function NewUGCWidgetBlueprint:ClearWeaponData()
    self.WeaponName = nil
    self.IconPath = nil
    self.OwnerUI = nil
    self.ItemID = nil
    self:SetVisibility(ESlateVisibility.Collapsed)
end

-- Notify UI10 to update the top preview.
function NewUGCWidgetBlueprint:Button_97_OnClicked()
    if self.OwnerUI ~= nil and self.OwnerUI.SelectWeapon ~= nil then
        self.OwnerUI:SelectWeapon(self.WeaponName, self.IconPath, self.ItemID)
    end
end

-- Set all button states to use the same icon. Hovered must copy Normal or it may lose the icon.
function NewUGCWidgetBlueprint:SetButtonTexture(Button, Texture)
    if Button == nil or Texture == nil then
        return
    end

    if Button.WidgetStyle == nil then
        return
    end

    self:SetBrushTexture(Button.WidgetStyle.Normal, Texture, nil)
    self:CopyBrush(Button.WidgetStyle.Normal, Button.WidgetStyle.Hovered)
    self:CopyBrush(Button.WidgetStyle.Normal, Button.WidgetStyle.Pressed)
    self:SetBrushTexture(Button.WidgetStyle.Hovered, Texture, WeaponButtonHoverImageSize)
    self:SetBrushTexture(Button.WidgetStyle.Pressed, Texture, nil)

    if Button.SetStyle ~= nil then
        Button:SetStyle(Button.WidgetStyle)
    end
end

-- Copy the visual style from one Brush to another.
function NewUGCWidgetBlueprint:CopyBrush(SourceBrush, TargetBrush)
    if SourceBrush == nil or TargetBrush == nil then
        return
    end

    TargetBrush.ResourceObject = SourceBrush.ResourceObject
    TargetBrush.ImageSize = SourceBrush.ImageSize
    TargetBrush.DrawAs = SourceBrush.DrawAs
    TargetBrush.Tiling = SourceBrush.Tiling
    TargetBrush.Mirroring = SourceBrush.Mirroring
    TargetBrush.Margin = SourceBrush.Margin
    TargetBrush.TintColor = SourceBrush.TintColor
end

-- Set a Brush texture; ImageSize is only passed for special states.
function NewUGCWidgetBlueprint:SetBrushTexture(Brush, Texture, ImageSize)
    if Brush == nil or Texture == nil then
        return
    end

    Brush.ResourceObject = Texture

    if ImageSize ~= nil then
        Brush.ImageSize = ImageSize
    end

    if Brush.TintColor ~= nil and Brush.TintColor.SpecifiedColor ~= nil then
        Brush.TintColor.SpecifiedColor.A = 1.0
    end
end

-- function NewUGCWidgetBlueprint:Tick(MyGeometry, InDeltaTime)
-- end

-- function NewUGCWidgetBlueprint:Destruct()
-- end

return NewUGCWidgetBlueprint
