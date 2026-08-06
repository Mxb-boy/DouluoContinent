---@class UI21_C:UUserWidget
---@field Btn_LeftSlot_1 UButton
---@field Btn_LockAttack UButton
---@field Btn_LockHP UButton
---@field Btn_RightSlot_1 UButton
---@field Button_9 UButton
---@field Button_10 UButton
---@field Button_11 UButton
---@field Button_12 UButton
---@field Button_13 UButton
---@field Button_14 UButton
---@field Button_15 UButton
---@field Button_16 UButton
---@field Image_11 UImage
---@field Image_12 UImage
---@field Image_13 UImage
---@field Image_14 UImage
---@field Image_15 UImage
---@field Image_16 UImage
---@field Image_17 UImage
---@field Image_18 UImage
---@field Image_145 UImage
---@field Image_231 UImage
---@field Image_232 UImage
---@field Image_233 UImage
---@field Img_CenterPanelBG UImage
---@field Img_LeftLong_1 UImage
---@field Img_LeftSelected_1 UImage
---@field Img_MainBG UImage
---@field Img_RightAttrBG UImage
---@field Img_RightSlot_1 UImage
--Edit Below--
---@class UI21_C:UUserWidget
---@field Btn_Close UButton
---@field Btn_Absorb UButton
---@field Btn_LockAttack UButton
---@field Btn_LockHP UButton
---@field Scroll_LeftSlots UScrollBox
---@field Scroll_RightSlots UScrollBox
---@field Txt_Attack UTextBlock
---@field Txt_HP UTextBlock
---@field Txt_RightAttr1 UTextBlock
---@field Txt_RightAttr2 UTextBlock
---@field Txt_RightAttr3 UTextBlock
---@field Img_LockAttack UImage
---@field Img_LockHP UImage
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local UI21 = { bInitDoOnce = false }
local RIGHT_NORMAL_COLOR = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 }
local RIGHT_SELECTED_COLOR = { R = 1.0, G = 0.75, B = 0.2, A = 1.0 }
function UI21:Construct()
    self:LuaInit()
end
function UI21:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    self.SelectedLeftSlot = nil
    self.SelectedRightSlot = nil
    self.bAttackLocked = false
    self.bHPLocked = false
    self:BindButton(self:GetWidget("Btn_Close"), self.Btn_Close_OnClicked)
    self:BindButton(self:GetWidget("Btn_Absorb"), self.Btn_Absorb_OnClicked)
    self:BindButton(self:GetWidget("Btn_LockAttack"), self.Btn_LockAttack_OnClicked)
    self:BindButton(self:GetWidget("Btn_LockHP"), self.Btn_LockHP_OnClicked)
    for Index = 1, 8 do
        local Button = self:GetWidget("Btn_LeftSlot_" .. tostring(Index))
        if Button ~= nil then
            local SlotIndex = Index
            self:BindButton(Button, function()
                self:SelectLeftSlot(SlotIndex)
            end)
        end
    end
    for Index = 1, 9 do
        local Button = self:GetWidget("Btn_RightSlot_" .. tostring(Index))
        if Button ~= nil then
            local SlotIndex = Index
            self:BindButton(Button, function()
                self:SelectRightSlot(SlotIndex)
            end)
        end
    end
    self:RefreshLeftSelection()
    self:RefreshRightSelection()
    self:RefreshLockState()
end
function UI21:GetWidget(Name)
    local Widget = self[Name]
    if Widget == nil and UGCWidgetManagerSystem ~= nil then
        if UGCWidgetManagerSystem.GetSubWidget ~= nil then
            Widget = UGCWidgetManagerSystem.GetSubWidget(self, Name)
        elseif UGCWidgetManagerSystem.GetWidgetFromName ~= nil then
            Widget = UGCWidgetManagerSystem.GetWidgetFromName(self, Name)
        end
    end
    self[Name] = Widget
    return Widget
end
function UI21:BindButton(Button, Callback)
    if Button == nil or Callback == nil then
        return
    end
    Button.OnClicked:Add(Callback, self)
    if UIEffectUtil ~= nil then
        UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
        UIEffectUtil.BindPressScale(self, Button, Button, 1.04, 1.0)
    end
end
function UI21:Open()
    self:SetVisibility(ESlateVisibility.Visible)
end
function UI21:Close()
    self:SetVisibility(ESlateVisibility.Collapsed)
end
function UI21:Btn_Close_OnClicked()
    self:Close()
end
function UI21:SelectLeftSlot(Index)
    self.SelectedLeftSlot = Index
    self:RefreshLeftSelection()
end
function UI21:RefreshLeftSelection()
    for Index = 1, 8 do
        local Frame = self:GetWidget("Img_LeftSelected_" .. tostring(Index))
        if Frame ~= nil then
            local Visibility = Index == self.SelectedLeftSlot
                and ESlateVisibility.SelfHitTestInvisible
                or ESlateVisibility.Collapsed
            Frame:SetVisibility(Visibility)
        end
    end
end
function UI21:SelectRightSlot(Index)
    self.SelectedRightSlot = Index
    self:RefreshRightSelection()
end
function UI21:RefreshRightSelection()
    for Index = 1, 9 do
        local Button = self:GetWidget("Btn_RightSlot_" .. tostring(Index))
        if Button ~= nil and Button.SetColorAndOpacity ~= nil then
            local Color = Index == self.SelectedRightSlot
                and RIGHT_SELECTED_COLOR
                or RIGHT_NORMAL_COLOR
            pcall(Button.SetColorAndOpacity, Button, Color)
        end
    end
end
function UI21:Btn_LockAttack_OnClicked()
    self.bAttackLocked = not self.bAttackLocked
    self:RefreshLockState()
end
function UI21:Btn_LockHP_OnClicked()
    self.bHPLocked = not self.bHPLocked
    self:RefreshLockState()
end
function UI21:RefreshLockState()
    self:SetIndicatorVisible(self:GetWidget("Img_LockAttack"), self.bAttackLocked)
    self:SetIndicatorVisible(self:GetWidget("Img_LockHP"), self.bHPLocked)
end
function UI21:SetIndicatorVisible(Image, bVisible)
    if Image ~= nil then
        Image:SetVisibility(bVisible
            and ESlateVisibility.SelfHitTestInvisible
            or ESlateVisibility.Collapsed)
    end
end
function UI21:Btn_Absorb_OnClicked()
    if self.SelectedRightSlot == nil then
        if UGCWidgetManagerSystem ~= nil and UGCWidgetManagerSystem.ShowTipsUI ~= nil then
            UGCWidgetManagerSystem.ShowTipsUI("请先选择一个魂环")
        end
        return
    end
    if self.OnAbsorbRequested ~= nil then
        self:OnAbsorbRequested(
            self.SelectedLeftSlot,
            self.SelectedRightSlot,
            self.bAttackLocked,
            self.bHPLocked
        )
    end
end
function UI21:SetCenterAttributes(AttackText, HPText)
    local Attack = self:GetWidget("Txt_Attack")
    local HP = self:GetWidget("Txt_HP")
    if Attack ~= nil then Attack:SetText(tostring(AttackText or "攻击")) end
    if HP ~= nil then HP:SetText(tostring(HPText or "生命")) end
end
function UI21:SetRightAttributes(Line1, Line2, Line3)
    local Values = { Line1, Line2, Line3 }
    for Index = 1, 3 do
        local TextBlock = self:GetWidget("Txt_RightAttr" .. tostring(Index))
        if TextBlock ~= nil then
            TextBlock:SetText(tostring(Values[Index] or ""))
        end
    end
end
function UI21:Destruct()
    self.bInitDoOnce = false
end
return UI21