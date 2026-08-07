---@class UI15_C:UUserWidget
---@field Btn_Close UButton
---@field Button_0 UButton
---@field Button_1 UButton
---@field Button_2 UButton
---@field Button_3 UButton
---@field Button_4 UButton
---@field Button_5 UButton
---@field Button_6 UButton
---@field Button_81 UButton
---@field Button_82 UButton
---@field Button_83 UButton
---@field Button_84 UButton
---@field Button_85 UButton
---@field Button_86 UButton
---@field Button_87 UButton
---@field Button_88 UButton
---@field Button_89 UButton
---@field Button_90 UButton
---@field Button_96 UButton
---@field Button_97 UButton
---@field Button_154 UButton
---@field Button_263 UButton
---@field Button_359 UButton
---@field CheckBox_100 UCheckBox
---@field CheckBox_101 UCheckBox
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_2 UImage
---@field Image_3 UImage
---@field Image_4 UImage
---@field Image_5 UImage
---@field Image_6 UImage
---@field Image_7 UImage
---@field Image_8 UImage
---@field Image_9 UImage
---@field Image_10 UImage
---@field Image_11 UImage
---@field Image_12 UImage
---@field Image_13 UImage
---@field Image_14 UImage
---@field Image_15 UImage
---@field Image_16 UImage
---@field Image_17 UImage
---@field Image_18 UImage
---@field Image_19 UImage
---@field Image_20 UImage
---@field Image_21 UImage
---@field Image_26 UImage
---@field Image_39 UImage
---@field Image_40 UImage
---@field Image_41 UImage
---@field Image_42 UImage
---@field Image_65 UImage
---@field Image_66 UImage
---@field Image_83 UImage
---@field Image_138 UImage
---@field Image_139 UImage
---@field Image_181 UImage
---@field Image_182 UImage
---@field Image_210 UImage
---@field Image_238 UImage
---@field Image_239 UImage
---@field Image_358 UImage
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local LotteryConfig = UGCGameSystem.UGCRequire("Script.Common.LotteryConfig")

local UI15 = { bInitDoOnce = false }

local LotteryType = LotteryConfig.Types
local DefaultImageColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 }
local AwardBgOwnedColor = { R = 0.32549, G = 0.32549, B = 0.32549, A = 1.0 }
local AwardIconOwnedColor = { R = 0.6, G = 0.6, B = 0.6, A = 1.0 }
local TabButtonBrightColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 }
local TabButtonDarkColor = { R = 0.282353, G = 0.282353, B = 0.282353, A = 1.0 }

function UI15:Construct()
    self:LuaInit()
end

function UI15:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    self.SelectedLotteryType = LotteryType.Weapon

    self:BindButton(self.Btn_Close, self.Btn_Close_OnClicked)
    self:BindButton(self.Btn_FHSY, self.Btn_FHSY_OnClicked)
    self:BindButton(self.Btn_Title, self.Btn_Title_OnClicked)
    self:BindButton(self.Btn_Weapon, self.Btn_Weapon_OnClicked)
    self:BindButton(self.Btn_Wing, self.Btn_Wing_OnClicked)
    self:BindAwardSlots()
    self:Refresh()
end

function UI15:BindButton(Button, Callback)
    if Button == nil then
        return
    end

    Button.OnClicked:Add(Callback, self)
    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function UI15:Open()
    self:SetBattleUIVisible(false)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestLotteryStateSync")
    end
    self:Refresh()
    self:SetVisibility(ESlateVisibility.Visible)
end

function UI15:Btn_Close_OnClicked()
    self:Close()
end

function UI15:Btn_FHSY_OnClicked()
    self:SelectLotteryType(LotteryType.FHSY)
end

function UI15:Btn_Title_OnClicked()
    self:SelectLotteryType(LotteryType.Title)
end

function UI15:Btn_Weapon_OnClicked()
    self:SelectLotteryType(LotteryType.Weapon)
end

function UI15:Btn_Wing_OnClicked()
    self:SelectLotteryType(LotteryType.Wing)
end

function UI15:Close()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI15:SelectLotteryType(Type)
    if LotteryConfig.GetPool(Type) == nil then
        return
    end
    if self.ActiveTabType == Type then
        return
    end

    self.SelectedLotteryType = Type
    self.ActiveTabType = Type
    self:RefreshLotteryTabButtons()
    self:Refresh()
end

function UI15:Refresh()
    local Config = LotteryConfig.GetPool(self.SelectedLotteryType)
    self:RefreshLotteryTicketText()
    self:RefreshLotteryTabButtons()
    self:RefreshAwardPanel(Config)
    self:RefreshAwardPreview(Config and Config.GrandPrize or nil)
end

function UI15:GetAwardPanels()
    return {
        [LotteryType.Weapon] = self.kj01_C_0,
        [LotteryType.Wing] = self.kj01_C_1,
        [LotteryType.Title] = self.kj01_C_2,
        [LotteryType.FHSY] = self.kj01_C_3,
    }
end

function UI15:GetLotteryTabButtons()
    return {
        [LotteryType.Weapon] = self.Btn_Weapon,
        [LotteryType.Wing] = self.Btn_Wing,
        [LotteryType.Title] = self.Btn_Title,
        [LotteryType.FHSY] = self.Btn_FHSY,
    }
end

function UI15:RefreshLotteryTabButtons()
    for Type, Button in pairs(self:GetLotteryTabButtons()) do
        local bDark = Type == self.ActiveTabType or self:IsLotteryCompleted(Type)
        self:SetButtonTint(Button, bDark and TabButtonDarkColor or TabButtonBrightColor)
    end
end

function UI15:SetButtonTint(Button, Color)
    if Button == nil or Color == nil then
        return
    end

    if Button.SetColorAndOpacity ~= nil then
        pcall(Button.SetColorAndOpacity, Button, Color)
    end
    if Button.WidgetStyle ~= nil then
        self:SetBrushTint(Button.WidgetStyle.Normal, Color)
        self:SetBrushTint(Button.WidgetStyle.Hovered, Color)
        self:SetBrushTint(Button.WidgetStyle.Pressed, Color)
        if Button.SetStyle ~= nil then
            Button:SetStyle(Button.WidgetStyle)
        end
    end
end

function UI15:SetBrushTint(Brush, Color)
    if Brush ~= nil then
        Brush.TintColor = { SpecifiedColor = Color }
    end
end

function UI15:BindAwardSlots()
    for Type, Panel in pairs(self:GetAwardPanels()) do
        if Panel ~= nil and Panel.Btn_Summon ~= nil then
            local PanelLotteryType = Type
            Panel.LotteryType = Type
            Panel.Btn_Summon.OnClicked:Add(function()
                self:RequestLottery(PanelLotteryType)
            end, self)
            UIEffectUtil.SetButtonStateBrushSameAsNormal(Panel.Btn_Summon)
            UIEffectUtil.BindPressScale(self, Panel.Btn_Summon, Panel.Btn_Summon, 1.06, 1.0)
        end
    end
end

function UI15:RefreshAwardPanel(Config)
    local Panels = self:GetAwardPanels()
    local ActivePanel = Panels[self.SelectedLotteryType]

    for _, Panel in pairs(Panels) do
        self:SetWidgetVisible(Panel, Panel == ActivePanel)
        self:HideAwardOKImages(Panel)
    end
    self:SetWidgetVisible(self.kj01, false)

    if ActivePanel == nil or Config == nil then
        return
    end

    self:SetAwardImage(ActivePanel.Img_Best, Config.GrandPrize and Config.GrandPrize.IconPath or "")
    local Images = { ActivePanel.Img1, ActivePanel.Img2, ActivePanel.Img3, ActivePanel.Img4, ActivePanel.Img5, ActivePanel.Img6 }
    for Index, Image in ipairs(Images) do
        local Award = Config.Awards and Config.Awards[Index] or nil
        if Award ~= nil then
            self:SetAwardImage(Image, Award.IconPath)
        end
    end
    self:RefreshSummonCostText(ActivePanel, self.SelectedLotteryType)
    self:RefreshSummonButtonState(ActivePanel, self.SelectedLotteryType)
    self:ApplyLotteryOKState(ActivePanel, self.SelectedLotteryType)
end

function UI15:RefreshSummonCostText(Panel, LotteryTypeValue)
    if Panel == nil or Panel.TextNum == nil then
        return
    end

    local Round = self:GetLotteryRound(LotteryTypeValue)
    local NextRound = self:IsLotteryCompleted(LotteryTypeValue) and Round or Round + 1
    Panel.TextNum:SetText("x" .. tostring(LotteryConfig.GetRoundCost(NextRound)) .. "召唤")
end

function UI15:HideAwardOKImages(Panel)
    if Panel == nil then
        return
    end

    local Images = {
        Panel.Img_OK_Best,
        Panel.Img_OK_1,
        Panel.Img_OK_2,
        Panel.Img_OK_3,
        Panel.Img_OK_4,
        Panel.Img_OK_5,
        Panel.Img_OK_6,
    }
    for _, Image in ipairs(Images) do
        self:SetWidgetVisible(Image, false)
    end
    self:ResetAwardBgImages(Panel)
end

function UI15:SetAwardOKVisible(Panel, AwardIndex, bVisible)
    if Panel == nil then
        return
    end

    local OKImages = {
        [0] = Panel.Img_OK_Best,
        [1] = Panel.Img_OK_1,
        [2] = Panel.Img_OK_2,
        [3] = Panel.Img_OK_3,
        [4] = Panel.Img_OK_4,
        [5] = Panel.Img_OK_5,
        [6] = Panel.Img_OK_6,
    }
    self:SetWidgetVisible(OKImages[tonumber(AwardIndex) or -1], bVisible)
    self:SetAwardBgOwned(Panel, AwardIndex, bVisible)
    self:SetAwardIconOwned(Panel, AwardIndex, bVisible)
end

function UI15:ShowAllAwardOKImages(Panel)
    if Panel == nil then
        return
    end

    for Index = 0, 6 do
        self:SetAwardOKVisible(Panel, Index, true)
    end
end

function UI15:ResetAwardBgImages(Panel)
    for Index = 0, 6 do
        self:SetAwardBgOwned(Panel, Index, false)
        self:SetAwardIconOwned(Panel, Index, false)
    end
end

function UI15:SetAwardBgOwned(Panel, AwardIndex, bOwned)
    if Panel == nil then
        return
    end

    local BgImages = {
        [0] = Panel.Image_7,
        [1] = Panel.Image_47,
        [2] = Panel.Image_2,
        [3] = Panel.Image_3,
        [4] = Panel.Image_4,
        [5] = Panel.Image_5,
        [6] = Panel.Image_6,
    }
    self:SetImageColor(BgImages[tonumber(AwardIndex) or -1], bOwned and AwardBgOwnedColor or DefaultImageColor)
end

function UI15:SetAwardIconOwned(Panel, AwardIndex, bOwned)
    if Panel == nil then
        return
    end

    local AwardImages = {
        [0] = Panel.Img_Best,
        [1] = Panel.Img1,
        [2] = Panel.Img2,
        [3] = Panel.Img3,
        [4] = Panel.Img4,
        [5] = Panel.Img5,
        [6] = Panel.Img6,
    }
    self:SetImageColor(AwardImages[tonumber(AwardIndex) or -1], bOwned and AwardIconOwnedColor or DefaultImageColor)
end

function UI15:SetImageOwnedColor(Image, bOwned, OwnedColor)
    if Image == nil then
        return
    end

    if bOwned then
        self:SetImageColor(Image, OwnedColor)
    else
        self:RestoreImageColor(Image)
    end
end

function UI15:CopyImageColor(Color)
    Color = Color or DefaultImageColor
    return {
        R = tonumber(Color.R) or 1.0,
        G = tonumber(Color.G) or 1.0,
        B = tonumber(Color.B) or 1.0,
        A = tonumber(Color.A) or 1.0,
    }
end

function UI15:GetImageColor(Image)
    local Color = Image
        and Image.Brush
        and Image.Brush.TintColor
        and Image.Brush.TintColor.SpecifiedColor
        or DefaultImageColor
    return self:CopyImageColor(Color)
end

function UI15:CacheOriginalImageColor(Image)
    if Image == nil then
        return
    end

    self.OriginalImageColors = self.OriginalImageColors or {}
    if self.OriginalImageColors[Image] == nil then
        self.OriginalImageColors[Image] = self:GetImageColor(Image)
    end
end

function UI15:RestoreImageColor(Image)
    if Image == nil then
        return
    end

    self:CacheOriginalImageColor(Image)
    self:SetImageColor(Image, self.OriginalImageColors and self.OriginalImageColors[Image] or DefaultImageColor)
end

function UI15:SetImageColor(Image, Color)
    if Image == nil or Color == nil then
        return
    end

    self:CacheOriginalImageColor(Image)
    if Image.SetColorAndOpacity ~= nil then
        pcall(Image.SetColorAndOpacity, Image, Color)
    end
    if Image.Brush ~= nil then
        Image.Brush.TintColor = { SpecifiedColor = Color }
    end
end

function UI15:GetLocalLotteryOKState(LotteryTypeValue)
    self.LocalLotteryOKStates = self.LocalLotteryOKStates or {}
    local Key = tostring(LotteryTypeValue)
    self.LocalLotteryOKStates[Key] = self.LocalLotteryOKStates[Key] or {
        Awards = {},
        Completed = false,
        Round = 0,
    }
    return self.LocalLotteryOKStates[Key]
end

function UI15:ApplyLotteryOKState(Panel, LotteryTypeValue)
    local State = self:GetLocalLotteryOKState(LotteryTypeValue)
    local ServerState = self:GetServerLotteryState(LotteryTypeValue)
    if ServerState ~= nil then
        State.Completed = ServerState.Completed == true
        State.Round = tonumber(ServerState.Round) or State.Round
        if ServerState.GrandPrize == true then
            State.Awards["0"] = true
        end
        for Index, bOwned in pairs(ServerState.OwnedAwards or {}) do
            if bOwned == true then
                State.Awards[tostring(Index)] = true
            end
        end
    end

    if State.Completed == true then
        self:ShowAllAwardOKImages(Panel)
        return
    end

    for Index, bOwned in pairs(State.Awards) do
        if bOwned == true then
            self:SetAwardOKVisible(Panel, tonumber(Index) or -1, true)
        end
    end
end

function UI15:GetServerLotteryState(LotteryTypeValue)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerState = PlayerController and PlayerController.PlayerState or nil
    local State = PlayerState and PlayerState.LotteryState or nil
    return State and State[tostring(LotteryTypeValue)] or nil
end

function UI15:GetLotteryRound(LotteryTypeValue)
    local Round = 0
    local ServerState = self:GetServerLotteryState(LotteryTypeValue)
    if ServerState ~= nil then
        Round = tonumber(ServerState.Round) or 0
    end

    local LocalState = self.LocalLotteryOKStates and self.LocalLotteryOKStates[tostring(LotteryTypeValue)] or nil
    local LocalRound = tonumber(LocalState and LocalState.Round) or 0
    if LocalRound > Round then
        return LocalRound
    end

    return Round
end

function UI15:GetLotteryTicketCount()
    local ItemID = tonumber(LotteryConfig.CostItemID) or 0
    if ItemID <= 0 then
        return 0
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerPawn = PlayerController and PlayerController.Pawn or nil
    if PlayerPawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        return tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0
    end

    return 0
end

function UI15:GetAdjustedLotteryTicketCount()
    local Count = self:GetLotteryTicketCount()
    local Offset = tonumber(self.LocalLotteryTicketOffset) or 0
    local LastCount = tonumber(self.LastLotteryTicketCount)
    if LastCount ~= nil and Count < LastCount and Offset < 0 then
        Offset = math.min(0, Offset + LastCount - Count)
        self.LocalLotteryTicketOffset = Offset
    end
    self.LastLotteryTicketCount = Count

    local AdjustedCount = Count + Offset
    return AdjustedCount > 0 and AdjustedCount or 0
end

function UI15:RefreshLotteryTicketText()
    if self.TextTicket_Now == nil then
        return
    end

    self.TextTicket_Now:SetText(tostring(self:GetAdjustedLotteryTicketCount()))
end

function UI15:IsLotteryCompleted(LotteryTypeValue)
    local ServerState = self:GetServerLotteryState(LotteryTypeValue)
    if ServerState ~= nil and (ServerState.Completed == true or ServerState.GrandPrize == true) then
        return true
    end

    local LocalState = self.LocalLotteryOKStates and self.LocalLotteryOKStates[tostring(LotteryTypeValue)] or nil
    return LocalState ~= nil and (LocalState.Completed == true or LocalState.Awards["0"] == true)
end

function UI15:CanSummonLottery(LotteryTypeValue)
    if self:IsLotteryCompleted(LotteryTypeValue) then
        return false
    end

    local CostItemID = tonumber(LotteryConfig.CostItemID) or 0
    if CostItemID <= 0 then
        return true
    end

    local Cost = LotteryConfig.GetRoundCost(self:GetLotteryRound(LotteryTypeValue) + 1)
    return self:GetAdjustedLotteryTicketCount() >= Cost
end

function UI15:RefreshSummonButtonState(Panel, LotteryTypeValue)
    if Panel == nil or Panel.Btn_Summon == nil then
        return
    end

    local bEnabled = self:CanSummonLottery(LotteryTypeValue)
    Panel.Btn_Summon:SetIsEnabled(bEnabled)
    if Panel.Btn_Summon.SetRenderOpacity ~= nil then
        Panel.Btn_Summon:SetRenderOpacity(bEnabled and 1.0 or 0.45)
    end
end

function UI15:SetAwardImage(Image, IconPath)
    if Image == nil or IconPath == nil or IconPath == "" then
        return
    end

    local Texture = IconPath
    if type(IconPath) == "string" then
        Texture = UE.LoadObject(IconPath)
    end
    if Texture == nil then
        ugcprint("[UI15:SetAwardImage] load failed: " .. tostring(IconPath))
        return
    end

    Image:SetBrushFromTexture(Texture)
end

function UI15:RefreshAwardPreview(Award)
    if Award == nil or self.Img_Award == nil then
        return
    end

    self:SetAwardImage(self.Img_Award, Award.IconPath)
    if self.Text_AwardName ~= nil then
        self.Text_AwardName:SetText(Award.Name or "")
    end
end

function UI15:RequestLottery(LotteryTypeValue)
    LotteryTypeValue = tonumber(LotteryTypeValue) or self.SelectedLotteryType
    local Config = LotteryConfig.GetPool(LotteryTypeValue)
    if Config == nil then
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        ugcprint("[UI15:RequestLottery] PlayerController is nil")
        return
    end
    if not self:CanSummonLottery(LotteryTypeValue) then
        self:RefreshAwardPanel(Config)
        return
    end

    local Cost = LotteryConfig.GetRoundCost(self:GetLotteryRound(LotteryTypeValue) + 1)
    self.LocalLotteryTicketOffset = (tonumber(self.LocalLotteryTicketOffset) or 0) - Cost
    self.PendingLotteryRounds = self.PendingLotteryRounds or {}
    self.PendingLotteryCosts = self.PendingLotteryCosts or {}
    self.PendingLotteryRounds[tostring(LotteryTypeValue)] = self:GetLotteryRound(LotteryTypeValue)
    self.PendingLotteryCosts[tostring(LotteryTypeValue)] = Cost
    self:RefreshAwardPanel(Config)
    UnrealNetwork.CallUnrealRPC(
        PlayerController,
        PlayerController,
        "Server_RequestLottery",
        LotteryTypeValue,
        0
    )
end

function UI15:OnLotteryResult(LotteryTypeValue, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
    if LotteryTypeValue ~= nil then
        self.SelectedLotteryType = tonumber(LotteryTypeValue) or self.SelectedLotteryType
    end

    local AwardIndex = tonumber(SlotIndex) or 0
    local OKState = self:GetLocalLotteryOKState(self.SelectedLotteryType)
    local Key = tostring(self.SelectedLotteryType)
    if AwardIndex < 0 and self.PendingLotteryCosts ~= nil and self.PendingLotteryCosts[Key] ~= nil then
        self.LocalLotteryTicketOffset = (tonumber(self.LocalLotteryTicketOffset) or 0) + self.PendingLotteryCosts[Key]
        self.PendingLotteryCosts[Key] = nil
    end
    if AwardIndex >= 0 then
        OKState.Awards[tostring(AwardIndex)] = true
        local PendingRound = self.PendingLotteryRounds and self.PendingLotteryRounds[Key] or nil
        OKState.Round = (tonumber(PendingRound) or self:GetLotteryRound(self.SelectedLotteryType)) + 1
        if self.PendingLotteryRounds ~= nil then
            self.PendingLotteryRounds[Key] = nil
        end
        if self.PendingLotteryCosts ~= nil then
            self.PendingLotteryCosts[Key] = nil
        end
    end
    if tonumber(bCompleted) == 1 then
        OKState.Completed = true
    end

    self:Refresh()
    local Panel = self:GetAwardPanels()[self.SelectedLotteryType]
    if tonumber(bCompleted) == 1 then
        self:ShowAllAwardOKImages(Panel)
    else
        self:SetAwardOKVisible(Panel, AwardIndex, true)
    end
    self:OpenLotteryGetItemUI(ItemList)
end

function UI15:OpenLotteryGetItemUI(ItemList)
    if ItemList == nil or #ItemList <= 0 then
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local LotteryComponent = PlayerController and PlayerController.LotteryComponent or nil
    if LotteryComponent ~= nil and LotteryComponent.OpenGetItemUI ~= nil then
        LotteryComponent:OpenGetItemUI(ItemList)
    end
end

function UI15:SetWidgetVisible(Widget, bVisible)
    if Widget ~= nil then
        Widget:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end
end

function UI15:SetBattleUIVisible(isVisible)
    if isVisible then
        if self.HiddenBattleWidgets == nil then
            return
        end
        for _, Item in ipairs(self.HiddenBattleWidgets) do
            if Item.Widget ~= nil then
                Item.Widget:SetVisibility(Item.Visibility)
            end
        end
        self.HiddenBattleWidgets = nil
        return
    end

    self.HiddenBattleWidgets = {}
    local function HideWidget(Widget)
        if Widget == nil then
            return
        end
        table.insert(self.HiddenBattleWidgets, {
            Widget = Widget,
            Visibility = Widget:GetVisibility(),
        })
        Widget:SetVisibility(ESlateVisibility.Collapsed)
    end

    HideWidget(UGCWidgetManagerSystem.GetMainUI())
    HideWidget(UGCWidgetManagerSystem.GetMainControlUI())
    HideWidget(UGCWidgetManagerSystem.GetShootingUIPanel())
    HideWidget(UGCWidgetManagerSystem.GetSkillRootPanel())
end

function UI15:Destruct()
    self:SetBattleUIVisible(true)
end

return UI15