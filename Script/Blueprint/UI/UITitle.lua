---@class UITitle_C:UUserWidget
---@field Btn_Close UButton
---@field Btn_Equip UButton
---@field Btn_Title_10 UButton
---@field Btn_Title_11 UButton
---@field Btn_Title_12 UButton
---@field Btn_Title_13 UButton
---@field Btn_Title_14 UButton
---@field Btn_Title_15 UButton
---@field Btn_Title_01 UButton
---@field Btn_Title_02 UButton
---@field Btn_Title_03 UButton
---@field Btn_Title_04 UButton
---@field Btn_Title_05 UButton
---@field Btn_Title_06 UButton
---@field Btn_Title_07 UButton
---@field Btn_Title_08 UButton
---@field Btn_Title_09 UButton
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_2 UImage
---@field Image_3 UImage
---@field Image_4 UImage
---@field Image_5 UImage
---@field Image_6 UImage
---@field Image_7 UImage
---@field Image_8 UImage
---@field Image_15 UImage
---@field Image_16 UImage
---@field Image_17 UImage
---@field Image_18 UImage
---@field Image_19 UImage
---@field Image_26 UImage
---@field Image_93 UImage
---@field Image_97 UImage
---@field Image_98 UImage
---@field Image_99 UImage
---@field Image_123 UImage
---@field Image_132 UImage
---@field Text_TitleName UTextBlock
---@field TextBlock_256 UTextBlock
---@field TextBlock_257 UTextBlock
--Edit Below--
local UITitle = { bInitDoOnce = false }
function UITitle:Construct()
    self:LuaInit()
end

function UITitle:SetBattleUIVisible(isVisible)
    if isVisible then
        if self.HiddenBattleWidgets == nil then
            return
        end

        for _, item in ipairs(self.HiddenBattleWidgets) do
            if item.Widget ~= nil then
                item.Widget:SetVisibility(item.Visibility)
            end
        end
        self.HiddenBattleWidgets = nil
        return
    end

    self.HiddenBattleWidgets = {}
    local function HideWidget(widget)
        if widget == nil then
            return
        end

        for _, item in ipairs(self.HiddenBattleWidgets) do
            if item.Widget == widget then
                return
            end
        end

        table.insert(self.HiddenBattleWidgets, {
            Widget = widget,
            Visibility = widget:GetVisibility(),
        })
        widget:SetVisibility(ESlateVisibility.Collapsed)
    end

    HideWidget(UGCWidgetManagerSystem.GetMainUI())
    HideWidget(UGCWidgetManagerSystem.GetMainControlUI())
    HideWidget(UGCWidgetManagerSystem.GetShootingUIPanel())
    HideWidget(UGCWidgetManagerSystem.GetSkillRootPanel())
end

function UITitle:Open()
    self:SetBattleUIVisible(false)
    self:SetVisibility(ESlateVisibility.Visible)
end

function UITitle:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    -- Temporary placeholder data. Replace these three text fields when the
    -- final title names and unlock conditions are confirmed.
    self.TitleConfigs = {}
    self.UnlockedTitles = {}
    self.SelectedTitleID = 1
    self.EquippedTitleID = 0

    for id = 1, 15 do
        self.TitleConfigs[id] = {
            Name = string.format("称号%02d", id),
            UnlockText = string.format("完成称号%02d的解锁条件", id),
            BonusText = string.format("属性加成：\n测试属性+%d%%", id),
        }
        self.UnlockedTitles[id] = false
    end
    for id = 1, 15 do
        self:RefreshTitleLockState(id)
    end
    self.Btn_Title_01.OnClicked:Add(self.Btn_Title_01_OnClicked, self)
    self.Btn_Title_02.OnClicked:Add(self.Btn_Title_02_OnClicked, self)
    self.Btn_Title_03.OnClicked:Add(self.Btn_Title_03_OnClicked, self)
    self.Btn_Title_04.OnClicked:Add(self.Btn_Title_04_OnClicked, self)
    self.Btn_Title_05.OnClicked:Add(self.Btn_Title_05_OnClicked, self)
    self.Btn_Title_06.OnClicked:Add(self.Btn_Title_06_OnClicked, self)
    self.Btn_Title_07.OnClicked:Add(self.Btn_Title_07_OnClicked, self)
    self.Btn_Title_08.OnClicked:Add(self.Btn_Title_08_OnClicked, self)
    self.Btn_Title_09.OnClicked:Add(self.Btn_Title_09_OnClicked, self)
    self.Btn_Title_10.OnClicked:Add(self.Btn_Title_10_OnClicked, self)
    self.Btn_Title_11.OnClicked:Add(self.Btn_Title_11_OnClicked, self)
    self.Btn_Title_12.OnClicked:Add(self.Btn_Title_12_OnClicked, self)
    self.Btn_Title_13.OnClicked:Add(self.Btn_Title_13_OnClicked, self)
    self.Btn_Title_14.OnClicked:Add(self.Btn_Title_14_OnClicked, self)
    self.Btn_Title_15.OnClicked:Add(self.Btn_Title_15_OnClicked, self)
    self.Btn_Equip.OnClicked:Add(self.Btn_Equip_OnClicked, self)
    self.Btn_Close.OnClicked:Add(self.Btn_Close_OnClicked, self)

    self:UnlockTitle(1) -- 临时测试解锁第一个称号
    self:SelectTitle(1)
end
function UITitle:RefreshTitleLockState(titleID)
    local widgetName = string.format("Text_Locked_%02d", titleID)
    local lockText = self[widgetName]
        or UGCWidgetManagerSystem.GetWidgetFromName(self, widgetName)
    if lockText == nil then
        return
    end
    self[widgetName] = lockText
    if self.UnlockedTitles[titleID] then
        lockText:SetVisibility(ESlateVisibility.Collapsed)
    else
        lockText:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end
function UITitle:SelectTitle(titleID)
    ugcprint("[UITitle] Title button clicked: " .. tostring(titleID))

    local config = self.TitleConfigs[titleID]
    if config == nil then
        ugcprint("[UITitle] Missing title config: " .. tostring(titleID))
        return
    end

    if self.Text_TitleName == nil
        or self.TextBlock_256 == nil
        or self.TextBlock_257 == nil then
        ugcprint("[UITitle] Text widgets are nil; enable Is Variable for Text_TitleName, TextBlock_256 and TextBlock_257")
        return
    end

    self.SelectedTitleID = titleID
    self.Text_TitleName:SetText(config.Name)
    self.TextBlock_256:SetText("获取途径：\n" .. config.UnlockText)
    self.TextBlock_257:SetText(config.BonusText)
    ugcprint("[UITitle] Title text updated: " .. tostring(titleID))
    local canEquip = self.UnlockedTitles[titleID]
        and self.EquippedTitleID ~= titleID
    self.Btn_Equip:SetIsEnabled(canEquip)
end
-- Called by gameplay behavior after a player meets an unlock condition.
function UITitle:UnlockTitle(titleID)
    if self.TitleConfigs[titleID] == nil then
        return
    end
    self.UnlockedTitles[titleID] = true
    self:RefreshTitleLockState(titleID)
    if self.SelectedTitleID == titleID then
        self:SelectTitle(titleID)
    end
end
function UITitle:Btn_Equip_OnClicked()
    local titleID = self.SelectedTitleID
    if not self.UnlockedTitles[titleID] then
        ugcprint("[UITitle] Cannot equip a locked title: " .. tostring(titleID))
        return
    end
    self.EquippedTitleID = titleID
    self:SelectTitle(titleID)
    ugcprint("[UITitle] Equipped title: " .. tostring(titleID))
end
function UITitle:Btn_Close_OnClicked()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UITitle:Destruct()
    self:SetBattleUIVisible(true)
end
function UITitle:Btn_Title_01_OnClicked() self:SelectTitle(1) end
function UITitle:Btn_Title_02_OnClicked() self:SelectTitle(2) end
function UITitle:Btn_Title_03_OnClicked() self:SelectTitle(3) end
function UITitle:Btn_Title_04_OnClicked() self:SelectTitle(4) end
function UITitle:Btn_Title_05_OnClicked() self:SelectTitle(5) end
function UITitle:Btn_Title_06_OnClicked() self:SelectTitle(6) end
function UITitle:Btn_Title_07_OnClicked() self:SelectTitle(7) end
function UITitle:Btn_Title_08_OnClicked() self:SelectTitle(8) end
function UITitle:Btn_Title_09_OnClicked() self:SelectTitle(9) end
function UITitle:Btn_Title_10_OnClicked() self:SelectTitle(10) end
function UITitle:Btn_Title_11_OnClicked() self:SelectTitle(11) end
function UITitle:Btn_Title_12_OnClicked() self:SelectTitle(12) end
function UITitle:Btn_Title_13_OnClicked() self:SelectTitle(13) end
function UITitle:Btn_Title_14_OnClicked() self:SelectTitle(14) end
function UITitle:Btn_Title_15_OnClicked() self:SelectTitle(15) end
return UITitle
