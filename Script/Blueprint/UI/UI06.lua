---@class UI06_C:UUserWidget
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
---@field Image_26 UImage
---@field Image_93 UImage
---@field Image_97 UImage
---@field Image_98 UImage
---@field Image_143 UImage
---@field Image_144 UImage
---@field Img_10 UImage
---@field Img_11 UImage
---@field Img_12 UImage
---@field Img_13 UImage
---@field Img_14 UImage
---@field Img_15 UImage
---@field Img_01 UImage
---@field Img_02 UImage
---@field Img_03 UImage
---@field Img_04 UImage
---@field Img_05 UImage
---@field Img_06 UImage
---@field Img_07 UImage
---@field Img_08 UImage
---@field Img_09 UImage
---@field ImgShow UImage
---@field TextAdd UTextBlock
---@field TextToGet UTextBlock
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local TitleConfig = UGCGameSystem.UGCRequire("Script.Common.TitleConfig")
local TitleMgr = UGCGameSystem.UGCRequire("Script.Xiao.TitleMgr")
local Ma_NumShow = UGCGameSystem.UGCRequire("Script.Ma.Ma_NumShow")

local function FormatProgressValue(value, source)
    if source == "CombatPower" then
        return Ma_NumShow.Format(value)
    end
    return tostring(math.floor(math.max(0, tonumber(value) or 0)))
end

local UI06 = { bInitDoOnce = false }
function UI06:Construct()
    self:LuaInit()
end
function UI06:ApplyButtonEffect(Button)
    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end
function UI06:SetBattleUIVisible(isVisible)
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
function UI06:Open()
    self:SetBattleUIVisible(false)
    self:SetVisibility(ESlateVisibility.Visible)
end
function UI06:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    self.TitleConfigs = {}
    self.UnlockedTitles = {}
    self.SelectedTitleID = 1
    self.EquippedTitleID = 0
    for id = 1, TitleConfig.MaxTitleID do
        self.TitleConfigs[id] = TitleConfig.GetTitle(id)
        self.UnlockedTitles[id] = false
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

    self.EquipButton = self.Btn_Equip
    if self.EquipButton then
        self.EquipButton.OnClicked:Add(self.Btn_Equip_OnClicked, self)
    end
    self.Btn_Close.OnClicked:Add(self.Btn_Close_OnClicked, self)

    self:ApplyButtonEffect(self.Btn_Title_01)
    self:ApplyButtonEffect(self.Btn_Title_02)
    self:ApplyButtonEffect(self.Btn_Title_03)
    self:ApplyButtonEffect(self.Btn_Title_04)
    self:ApplyButtonEffect(self.Btn_Title_05)
    self:ApplyButtonEffect(self.Btn_Title_06)
    self:ApplyButtonEffect(self.Btn_Title_07)
    self:ApplyButtonEffect(self.Btn_Title_08)
    self:ApplyButtonEffect(self.Btn_Title_09)
    self:ApplyButtonEffect(self.Btn_Title_10)
    self:ApplyButtonEffect(self.Btn_Title_11)
    self:ApplyButtonEffect(self.Btn_Title_12)
    self:ApplyButtonEffect(self.Btn_Title_13)
    self:ApplyButtonEffect(self.Btn_Title_14)
    self:ApplyButtonEffect(self.Btn_Title_15)
    self:ApplyButtonEffect(self.Btn_Equip)
    self:ApplyButtonEffect(self.Btn_Close)
    local playerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local unlockedTitles = nil
    if playerController ~= nil then
        self.EquippedTitleID = tonumber(playerController.EquippedTitleID) or self.EquippedTitleID
        unlockedTitles = playerController.UnlockedTitles
        local playerState = playerController.PlayerState
        if unlockedTitles == nil and playerState ~= nil then
            unlockedTitles = playerState.GetUnlockedTitles and playerState:GetUnlockedTitles() or playerState.UnlockedTitles
            self.EquippedTitleID = tonumber(playerState.GetEquippedTitleID and playerState:GetEquippedTitleID() or playerState.EquippedTitleID) or self.EquippedTitleID
        end
    end
    if unlockedTitles ~= nil then
        for id, unlocked in pairs(unlockedTitles) do
            if unlocked then
                self:UnlockTitle(id)
            end
        end
    end

    self:SelectTitle(1)
end

function UI06:GetNamedWidget(widgetName)
    local widget = self[widgetName]
        or UGCWidgetManagerSystem.GetWidgetFromName(self, widgetName)
    self[widgetName] = widget
    return widget
end
function UI06:RefreshTitleLockState(titleID)
    local lockText = self:GetNamedWidget(
        string.format("TextLocked_%02d", titleID)
    )
    if lockText == nil then
        return
    end
    local visibility = self.UnlockedTitles[titleID]
        and ESlateVisibility.Collapsed
        or ESlateVisibility.HitTestInvisible
    lockText:SetVisibility(visibility)
end
function UI06:RefreshTitleImage(titleID)
    local sourceButton = self:GetNamedWidget(
        string.format("Btn_Title_%02d", titleID)
    )
    if sourceButton == nil or self.ImgShow == nil then
        ugcprint("[UI06] RefreshTitleImage: sourceButton or ImgShow nil for " .. titleID)
        return
    end

    local texture = WidgetBlueprintLibrary.GetBrushResourceAsTexture2D(
        sourceButton.WidgetStyle.Normal
    )
    if texture == nil then
        ugcprint("[UI06] RefreshTitleImage: button texture nil for " .. titleID)
        return
    end

    self.ImgShow:SetBrushFromTexture(texture)
end
function UI06:SelectTitle(titleID)
    local config = self.TitleConfigs[titleID]
    if config == nil then
        return
    end
    self.SelectedTitleID = titleID
    local getText = "获取途径：\n" .. config.TextToGet
    if not self.UnlockedTitles[titleID] then
        local playerController = UGCGameSystem.GetLocalPlayerController()
            or GameplayStatics.GetPlayerController(self, 0)
        local current, target, source = TitleMgr:GetProgress(titleID, playerController)
        if current ~= nil and target ~= nil then
            local currentText = FormatProgressValue(math.min(current, target), source)
            if source == "CombatPower" then
                getText = getText .. "\n当前战力：" .. currentText
            else
                local targetText = FormatProgressValue(target, source)
                getText = getText .. "\n进度：" .. currentText .. "/" .. targetText
            end
        end
    end
    self.TextToGet:SetText(getText)
    self.TextAdd:SetText(config.BonusText)
    self:RefreshTitleImage(titleID)
    if self.EquipButton then
        local canEquip = self.UnlockedTitles[titleID]
            and self.EquippedTitleID ~= titleID
        self.EquipButton:SetIsEnabled(canEquip)
    end
end
function UI06:UnlockTitle(titleID)
    titleID = tonumber(titleID) or 0
    if self.TitleConfigs[titleID] == nil then
        return
    end
    self.UnlockedTitles[titleID] = true
    self:RefreshTitleLockState(titleID)
    if self.SelectedTitleID == titleID then
        self:SelectTitle(titleID)
    end
end

function UI06:ApplyEquippedTitleToHead(titleID)
    local playerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if playerController == nil then
        ugcprint("[UI06] ApplyEquippedTitleToHead failed: local playerController is nil")
        return
    end

    if playerController.Server_EquipTitle == nil then
        ugcprint("[UI06] ApplyEquippedTitleToHead failed: Server_EquipTitle is nil")
        return
    end

    if playerController:HasAuthority() then
        playerController:Server_EquipTitle(titleID)
    else
        UnrealNetwork.CallUnrealRPC(
            playerController,
            playerController,
            "Server_EquipTitle",
            titleID
        )
    end
end

function UI06:Btn_Equip_OnClicked()
    local titleID = self.SelectedTitleID
    if not self.UnlockedTitles[titleID] then
        return
    end
    self.EquippedTitleID = titleID
    self:ApplyEquippedTitleToHead(titleID)
    self:SelectTitle(titleID)
end
function UI06:Btn_Close_OnClicked()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end
function UI06:Destruct()
    self:SetBattleUIVisible(true)
end
function UI06:Btn_Title_01_OnClicked() self:SelectTitle(1) end
function UI06:Btn_Title_02_OnClicked() self:SelectTitle(2) end
function UI06:Btn_Title_03_OnClicked() self:SelectTitle(3) end
function UI06:Btn_Title_04_OnClicked() self:SelectTitle(4) end
function UI06:Btn_Title_05_OnClicked() self:SelectTitle(5) end
function UI06:Btn_Title_06_OnClicked() self:SelectTitle(6) end
function UI06:Btn_Title_07_OnClicked() self:SelectTitle(7) end
function UI06:Btn_Title_08_OnClicked() self:SelectTitle(8) end
function UI06:Btn_Title_09_OnClicked() self:SelectTitle(9) end
function UI06:Btn_Title_10_OnClicked() self:SelectTitle(10) end
function UI06:Btn_Title_11_OnClicked() self:SelectTitle(11) end
function UI06:Btn_Title_12_OnClicked() self:SelectTitle(12) end
function UI06:Btn_Title_13_OnClicked() self:SelectTitle(13) end
function UI06:Btn_Title_14_OnClicked() self:SelectTitle(14) end
function UI06:Btn_Title_15_OnClicked() self:SelectTitle(15) end
return UI06
