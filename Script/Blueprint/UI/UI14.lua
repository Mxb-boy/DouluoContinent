---@class UI14_C:UUserWidget
---@field Btn_Close UButton
---@field Btn_FHSY UButton
---@field Btn_Title UButton
---@field Btn_Weapon UButton
---@field Btn_Wing UButton
---@field Image_0 UImage
---@field Image_19 UImage
---@field Image_26 UImage
---@field Image_45 UImage
---@field Image_126 UImage
---@field Image_358 UImage
---@field Image_544 UImage
---@field Img_Award UImage
---@field kj01 kj01_C
---@field kj01_C_0 kj01_C
---@field kj01_C_1 kj01_C
---@field kj01_C_2 kj01_C
---@field kj01_C_3 kj01_C
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local LotteryConfig = UGCGameSystem.UGCRequire("Script.Common.LotteryConfig")

local UI14 = { bInitDoOnce = false }

local LotteryType = LotteryConfig.Types
local LotteryConfigs = LotteryConfig.Pools

function UI14:Construct()
    self:LuaInit()
end

function UI14:LuaInit()
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

function UI14:BindButton(Button, Callback)
    if Button == nil then
        return
    end

    Button.OnClicked:Add(Callback, self)
    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function UI14:Open()
    self:SetBattleUIVisible(false)
    self:Refresh()
    self:SetVisibility(ESlateVisibility.Visible)
end

function UI14:Btn_Close_OnClicked()
    self:Close()
end

function UI14:Btn_FHSY_OnClicked()
    self:SelectLotteryType(LotteryType.FHSY)
end

function UI14:Btn_Title_OnClicked()
    self:SelectLotteryType(LotteryType.Title)
end

function UI14:Btn_Weapon_OnClicked()
    self:SelectLotteryType(LotteryType.Weapon)
end

function UI14:Btn_Wing_OnClicked()
    self:SelectLotteryType(LotteryType.Wing)
end

function UI14:Close()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI14:SelectLotteryType(Type)
    if LotteryConfigs[Type] == nil then
        return
    end

    self.SelectedLotteryType = Type
    self:Refresh()
end

function UI14:Refresh()
    local Config = LotteryConfigs[self.SelectedLotteryType]
    self:RefreshAwardPanel(Config)
    self:RefreshAwardPreview(Config and Config.GrandPrize or nil)
end

function UI14:GetAwardPanels()
    return {
        [LotteryType.Weapon] = self.kj01_C_0,
        [LotteryType.Wing] = self.kj01_C_1,
        [LotteryType.Title] = self.kj01_C_2,
        [LotteryType.FHSY] = self.kj01_C_3,
    }
end

function UI14:BindAwardSlots()
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

function UI14:RefreshAwardPanel(Config)
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
    self:ApplyLotteryOKState(ActivePanel, self.SelectedLotteryType)
end

function UI14:RefreshSummonCostText(Panel, LotteryTypeValue)
    if Panel == nil or Panel.TextNum == nil then
        return
    end

    local ServerState = self:GetServerLotteryState(LotteryTypeValue)
    local NextRound = (tonumber(ServerState and ServerState.Round) or 0) + 1
    Panel.TextNum:SetText(tostring(LotteryConfig.GetRoundCost(NextRound)) .. "召唤")
end

function UI14:HideAwardOKImages(Panel)
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
end

function UI14:SetAwardOKVisible(Panel, AwardIndex, bVisible)
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
end

function UI14:ShowAllAwardOKImages(Panel)
    if Panel == nil then
        return
    end

    for Index = 0, 6 do
        self:SetAwardOKVisible(Panel, Index, true)
    end
end

function UI14:GetLocalLotteryOKState(LotteryTypeValue)
    self.LocalLotteryOKStates = self.LocalLotteryOKStates or {}
    local Key = tostring(LotteryTypeValue)
    self.LocalLotteryOKStates[Key] = self.LocalLotteryOKStates[Key] or {
        Awards = {},
        Completed = false,
    }
    return self.LocalLotteryOKStates[Key]
end

function UI14:ApplyLotteryOKState(Panel, LotteryTypeValue)
    local State = self:GetLocalLotteryOKState(LotteryTypeValue)
    local ServerState = self:GetServerLotteryState(LotteryTypeValue)
    if ServerState ~= nil then
        State.Completed = ServerState.Completed == true
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

function UI14:GetServerLotteryState(LotteryTypeValue)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerState = PlayerController and PlayerController.PlayerState or nil
    local State = PlayerState and PlayerState.LotteryState or nil
    return State and State[tostring(LotteryTypeValue)] or nil
end

function UI14:SetAwardImage(Image, IconPath)
    if Image == nil or IconPath == nil or IconPath == "" then
        return
    end

    local Texture = UE.LoadObject(IconPath)
    if Texture == nil then
        ugcprint("[UI14:SetAwardImage] load failed: " .. tostring(IconPath))
        return
    end

    Image:SetBrushFromTexture(Texture)
end

function UI14:RefreshAwardPreview(Award)
    if Award == nil or self.Img_Award == nil then
        return
    end

    self:SetAwardImage(self.Img_Award, Award.IconPath)
end

function UI14:RequestLottery(LotteryTypeValue)
    LotteryTypeValue = tonumber(LotteryTypeValue) or self.SelectedLotteryType
    local Config = LotteryConfigs[LotteryTypeValue]
    if Config == nil then
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        ugcprint("[UI14:RequestLottery] PlayerController is nil")
        return
    end

    UnrealNetwork.CallUnrealRPC(
        PlayerController,
        PlayerController,
        "Server_RequestLottery",
        LotteryTypeValue,
        0
    )
end

function UI14:OnLotteryResult(LotteryTypeValue, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
    if LotteryTypeValue ~= nil then
        self.SelectedLotteryType = tonumber(LotteryTypeValue) or self.SelectedLotteryType
    end

    local Config = LotteryConfigs[self.SelectedLotteryType]
    local AwardIndex = tonumber(SlotIndex) or 0
    local OKState = self:GetLocalLotteryOKState(self.SelectedLotteryType)
    if AwardIndex >= 0 then
        OKState.Awards[tostring(AwardIndex)] = true
    end
    if tonumber(bCompleted) == 1 then
        OKState.Completed = true
    end

    local Award = nil
    if Config ~= nil then
        Award = AwardIndex == 0 and Config.GrandPrize or Config.Awards[AwardIndex]
    end
    self:Refresh()
    local Panel = self:GetAwardPanels()[self.SelectedLotteryType]
    if tonumber(bCompleted) == 1 then
        self:ShowAllAwardOKImages(Panel)
        self:RefreshAwardPreview(Config and Config.GrandPrize or nil)
    else
        self:SetAwardOKVisible(Panel, AwardIndex, true)
        self:RefreshAwardPreview(Award)
    end
    self:OpenLotteryGetItemUI(ItemList)

    ugcprint("[UI14:OnLotteryResult] type="
        .. tostring(self.SelectedLotteryType)
        .. ", slot=" .. tostring(SlotIndex)
        .. ", item=" .. tostring(AwardItemID)
        .. ", count=" .. tostring(AwardCount))
end

function UI14:OpenLotteryGetItemUI(ItemList)
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

function UI14:SetWidgetVisible(Widget, bVisible)
    if Widget ~= nil then
        Widget:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end
end

function UI14:SetBattleUIVisible(isVisible)
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

function UI14:Destruct()
    self:SetBattleUIVisible(true)
end

return UI14
