---@class UI14_C:UUserWidget
---@field Btn_Buy UButton
---@field Btn_Close UButton
---@field Btn_Detail UButton
---@field Btn_FHSY UButton
---@field Btn_Quit UButton
---@field Btn_Title UButton
---@field Btn_Weapon UButton
---@field Btn_Wing UButton
---@field Image_0 UImage
---@field Image_19 UImage
---@field Image_26 UImage
---@field Image_45 UImage
---@field Image_126 UImage
---@field Image_144 UImage
---@field Image_358 UImage
---@field Image_544 UImage
---@field Img_Award UImage
---@field kj01 kj01_C
---@field kj01_C_0 kj01_C
---@field kj01_C_1 kj01_C
---@field kj01_C_2 kj01_C
---@field kj01_C_3 kj01_C
---@field Panel_Detail UCanvasPanel
---@field Text_AwardName UTextBlock
---@field TextTicket_Now UTextBlock
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local LotteryConfig = UGCGameSystem.UGCRequire("Script.Common.LotteryConfig")

local UI14 = { bInitDoOnce = false }

local LotteryType = LotteryConfig.Types
local DefaultImageColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 }
local AwardBgOwnedColor = { R = 0.32549, G = 0.32549, B = 0.32549, A = 1.0 }
local AwardIconOwnedColor = { R = 0.6, G = 0.6, B = 0.6, A = 1.0 }
local TabButtonBrightColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 }
local TabButtonDarkColor = { R = 0.282353, G = 0.282353, B = 0.282353, A = 1.0 }

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
    self:BindButton(self.Btn_Detail, self.Btn_Detail_OnClicked)
    self:BindButton(self.Btn_Quit, self.Btn_Quit_OnClicked)
    self:BindButton(self.Btn_Buy, self.Btn_Buy_OnClicked)
    self:BindAwardSlots()
    self:SetDetailVisible(false)
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
    self:ResetLotteryTicketRefreshState()
    self:SetBattleUIVisible(false)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestLotteryStateSync")
    end
    self:Refresh()
    self:SetVisibility(ESlateVisibility.Visible)
end

-- GM 玩家数据重置后的客户端收口：服务端 LotteryState 清空后，必须同步清掉
-- UI14 自己维护的已获得标记、待处理抽奖和票券临时偏移，避免旧缓存覆盖新进度。
function UI14:ResetAfterPlayerDataReset()
    self.LocalLotteryOKStates = {}
    self.PendingLotteryRounds = {}
    self.PendingLotteryCosts = {}
    self:ResetLotteryTicketRefreshState()
    self.SelectedLotteryType = LotteryType.Weapon
    self.ActiveTabType = nil
    self:Refresh()
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

function UI14:Btn_Detail_OnClicked()
    self:SetDetailVisible(true)
end

function UI14:Btn_Quit_OnClicked()
    self:SetDetailVisible(false)
end

function UI14:Btn_Buy_OnClicked()
    self:OpenLotteryTicketPurchaseUI()
end

function UI14:Close()
    self:SetDetailVisible(false)
    self:ResetLotteryTicketRefreshState()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI14:SetDetailVisible(bVisible)
    self:SetWidgetVisible(self.Panel_Detail, bVisible)
end

function UI14:OpenLotteryTicketPurchaseUI()
    if not self:EnsureShopV2Manager() then
        ugcprint("[UI14:OpenLotteryTicketPurchaseUI] ShopV2Manager require failed")
        return false
    end
    if ShopV2Manager == nil or ShopV2Manager.CheckBackpackBeforePurchase == nil then
        ugcprint("[UI14:OpenLotteryTicketPurchaseUI] ShopV2Manager unavailable or backpack check failed")
        return false
    end
    local BackpackCheckOK, bCanPurchase = pcall(ShopV2Manager.CheckBackpackBeforePurchase, ShopV2Manager)
    if not BackpackCheckOK or bCanPurchase == false then
        ugcprint("[UI14:OpenLotteryTicketPurchaseUI] backpack check failed")
        return false
    end

    local ProductID = self:GetLotteryTicketProductID()
    if ProductID == nil then
        ugcprint("[UI14:OpenLotteryTicketPurchaseUI] lottery ticket product not found")
        return false
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        ugcprint("[UI14:OpenLotteryTicketPurchaseUI] PlayerController is nil")
        return false
    end
    if ShopV2Manager.bBlockRepeatPurchase == true then
        return false
    end

    self:EnsureShopPurchaseCallbacks()
    return self:OpenLotteryTicketPurchasePopup(PlayerController, ProductID)
end

function UI14:EnsureShopV2Manager()
    if ShopV2Manager ~= nil then
        return true
    end

    if UGCGameSystem == nil or UGCGameSystem.UGCRequire == nil then
        return false
    end

    local Success = pcall(UGCGameSystem.UGCRequire,
        "ExtendResource.ShopV2.OfficialPackage." .. "Script.ShopV2.ShopV2Manager")
    return Success and ShopV2Manager ~= nil
end

function UI14:OpenLotteryTicketPurchasePopup(PlayerController, ProductID)
    local PurchaseUIClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(
        "ExtendResource/ShopV2/OfficialPackage/Asset/ShopV2/Arts_UI/UIBP/ShopV2_PurchasePopups_UIBP.ShopV2_PurchasePopups_UIBP_C"))
    if PurchaseUIClass == nil then
        ugcprint("[UI14:OpenLotteryTicketPurchasePopup] PurchaseUIClass is nil")
        return false
    end

    local PurchaseUI = UserWidget.NewWidgetObjectBP(PlayerController, PurchaseUIClass)
    if PurchaseUI == nil then
        ugcprint("[UI14:OpenLotteryTicketPurchasePopup] PurchaseUI is nil")
        return false
    end

    ShopV2Manager.bBlockRepeatPurchase = true
    PurchaseUI:AddToViewport(15000)
    local Success, Err = pcall(PurchaseUI.Refresh, PurchaseUI, ProductID)
    if not Success then
        ShopV2Manager.bBlockRepeatPurchase = false
        PurchaseUI:SetVisibility(ESlateVisibility.Collapsed)
        ugcprint("[UI14:OpenLotteryTicketPurchasePopup] refresh failed: " .. tostring(Err))
        return false
    end

    return true
end

function UI14:GetLotteryTicketProductID()
    return self:GetShopProductID(LotteryConfig.CostShopItemID)
end

function UI14:GetShopProductID(ItemID)
    if ItemID == nil or ShopV2Manager == nil or ShopV2Manager.GetAllProductConfigData == nil then
        return nil
    end

    local Success, ProductDatas = pcall(ShopV2Manager.GetAllProductConfigData, ShopV2Manager)
    if not Success then
        ugcprint("[UI14:GetShopProductID] get product data failed")
        return nil
    end
    if ProductDatas == nil then
        return nil
    end

    for ProductID, ProductData in pairs(ProductDatas) do
        if tonumber(ProductData.ItemID) == tonumber(ItemID) then
            return tonumber(ProductData.ProductID) or tonumber(ProductData.ProductId) or tonumber(ProductID)
        end
    end
    return nil
end

function UI14:EnsureShopPurchaseCallbacks()
    if ShopV2Manager == nil then
        return
    end

    local CommodityOperationManager = self:GetShopCommodityOperationManager()
    if CommodityOperationManager ~= nil and ShopV2Manager.bBuyProductResultBinded ~= true then
        CommodityOperationManager.BuyProductResultDelegate:Add(ShopV2Manager.OnBuyProductResult, ShopV2Manager)
        ShopV2Manager.bBuyProductResultBinded = true
    end

    local VirtualItemManager = self:GetShopVirtualItemManager()
    if VirtualItemManager ~= nil and ShopV2Manager.bAddItemResultDelegateBinded ~= true then
        VirtualItemManager.AddItemResultDelegate:Add(ShopV2Manager.OnAddVirtualItem, ShopV2Manager)
        ShopV2Manager.bAddItemResultDelegateBinded = true
    end

    if VirtualItemManager ~= nil and self.bLotteryTicketAddItemResultBinded ~= true then
        VirtualItemManager.AddItemResultDelegate:Add(self.OnLotteryTicketAddVirtualItem, self)
        self.bLotteryTicketAddItemResultBinded = true
    end

    if CommodityOperationManager ~= nil and self.bLotteryTicketBuyProductResultBinded ~= true then
        CommodityOperationManager.BuyProductResultDelegate:Add(self.OnLotteryTicketBuyProductResult, self)
        self.bLotteryTicketBuyProductResultBinded = true
    end
end

function UI14:GetShopCommodityOperationManager()
    if ShopV2Manager == nil or ShopV2Manager.GetCommodityOperationManager == nil then
        return nil
    end

    local Success, Manager = pcall(ShopV2Manager.GetCommodityOperationManager, ShopV2Manager)
    if not Success then
        ugcprint("[UI14:GetShopCommodityOperationManager] manager unavailable")
        return nil
    end
    return Manager
end

function UI14:GetShopVirtualItemManager()
    if ShopV2Manager == nil or ShopV2Manager.GetVirtualItemManager == nil then
        return nil
    end

    local Success, Manager = pcall(ShopV2Manager.GetVirtualItemManager, ShopV2Manager)
    if not Success then
        ugcprint("[UI14:GetShopVirtualItemManager] manager unavailable")
        return nil
    end
    return Manager
end

function UI14:RemoveShopPurchaseCallbacks()
    if ShopV2Manager == nil then
        return
    end

    if self.bLotteryTicketAddItemResultBinded == true then
        local VirtualItemManager = self:GetShopVirtualItemManager()
        if VirtualItemManager ~= nil and VirtualItemManager.AddItemResultDelegate ~= nil then
            VirtualItemManager.AddItemResultDelegate:Remove(self.OnLotteryTicketAddVirtualItem, self)
        end
        self.bLotteryTicketAddItemResultBinded = false
    end

    if self.bLotteryTicketBuyProductResultBinded == true then
        local CommodityOperationManager = self:GetShopCommodityOperationManager()
        if CommodityOperationManager ~= nil and CommodityOperationManager.BuyProductResultDelegate ~= nil then
            CommodityOperationManager.BuyProductResultDelegate:Remove(self.OnLotteryTicketBuyProductResult, self)
        end
        self.bLotteryTicketBuyProductResultBinded = false
    end
end

function UI14:OnLotteryTicketBuyProductResult(Result)
    if Result == nil or Result.bSucceeded ~= true then
        return
    end

    local ProductID = self:GetLotteryTicketProductID()
    if ProductID ~= nil and tonumber(Result.ProductID) ~= tonumber(ProductID) then
        return
    end

    self:ScheduleLotteryTicketRefresh()
end

function UI14:OnLotteryTicketAddVirtualItem(Result)
    if Result == nil or Result.bSucceeded ~= true or Result.ItemList == nil then
        return
    end

    local ShopItemID = tonumber(LotteryConfig.CostShopItemID)
    if ShopItemID == nil then
        return
    end

    local bGotTicket = Result.ItemList[ShopItemID] ~= nil or Result.ItemList[tostring(ShopItemID)] ~= nil
    if not bGotTicket then
        return
    end

    self:ScheduleLotteryTicketRefresh()
end

function UI14:ScheduleLotteryTicketRefresh()
    self.LocalLotteryTicketOffset = 0
    self.LastLotteryTicketCount = nil
    self:RefreshLotteryTicketDisplay()
    self:RefreshLotteryTicketDisplayLater(0.2)
    self:RefreshLotteryTicketDisplayLater(0.8)
    self:RefreshLotteryTicketDisplayLater(2.0)
end

function UI14:RefreshLotteryTicketDisplayLater(Delay)
    if UGCTimerUtility == nil or UGCTimerUtility.CreateLuaTimer == nil then
        return
    end

    UGCTimerUtility.CreateLuaTimer(Delay, function()
        if self ~= nil then
            self:RefreshLotteryTicketDisplay()
        end
    end, false)
end

function UI14:ResetLotteryTicketRefreshState()
    self.LastLotteryTicketCount = nil
    self.LocalLotteryTicketOffset = 0
end

function UI14:RefreshLotteryTicketDisplay()
    self:RefreshLotteryTicketText()
    local Panel = self:GetAwardPanels()[self.SelectedLotteryType]
    self:RefreshSummonButtonState(Panel, self.SelectedLotteryType)
end

function UI14:SelectLotteryType(Type)
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

function UI14:Refresh()
    local Config = LotteryConfig.GetPool(self.SelectedLotteryType)
    self:RefreshLotteryTicketText()
    self:RefreshLotteryTabButtons()
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

function UI14:GetLotteryTabButtons()
    return {
        [LotteryType.Weapon] = self.Btn_Weapon,
        [LotteryType.Wing] = self.Btn_Wing,
        [LotteryType.Title] = self.Btn_Title,
        [LotteryType.FHSY] = self.Btn_FHSY,
    }
end

function UI14:RefreshLotteryTabButtons()
    for Type, Button in pairs(self:GetLotteryTabButtons()) do
        local bDark = Type == self.ActiveTabType or self:IsLotteryCompleted(Type)
        self:SetButtonTint(Button, bDark and TabButtonDarkColor or TabButtonBrightColor)
    end
end

function UI14:SetButtonTint(Button, Color)
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

function UI14:SetBrushTint(Brush, Color)
    if Brush ~= nil then
        Brush.TintColor = { SpecifiedColor = Color }
    end
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
    local CountTexts = { ActivePanel.Num_1, ActivePanel.Num_2, ActivePanel.Num_3, ActivePanel.Num_4, ActivePanel.Num_5, ActivePanel.Num_6 }
    for Index, Image in ipairs(Images) do
        local Award = Config.Awards and Config.Awards[Index] or nil
        if Award ~= nil then
            self:SetAwardImage(Image, Award.IconPath)
            self:SetAwardCountText(CountTexts[Index], Award.Count)
        else
            self:SetAwardCountText(CountTexts[Index], nil)
        end
    end
    self:RefreshSummonCostText(ActivePanel, self.SelectedLotteryType)
    self:RefreshSummonButtonState(ActivePanel, self.SelectedLotteryType)
    self:ApplyLotteryOKState(ActivePanel, self.SelectedLotteryType)
end

function UI14:SetAwardCountText(TextWidget, Count)
    if TextWidget == nil then
        return
    end

    local CountValue = tonumber(Count)
    if CountValue == nil then
        TextWidget:SetText("")
        return
    end

    TextWidget:SetText("x" .. tostring(CountValue))
end

function UI14:RefreshSummonCostText(Panel, LotteryTypeValue)
    if Panel == nil or Panel.TextNum == nil then
        return
    end

    local Round = self:GetLotteryRound(LotteryTypeValue)
    local NextRound = self:IsLotteryCompleted(LotteryTypeValue) and Round or Round + 1
    local Cost = LotteryConfig.GetRoundCost(NextRound)
    Panel.TextNum:SetText("x" .. tostring(Cost) .. "召唤")
    self:RefreshDiscountCostText(Panel, NextRound)
end

function UI14:RefreshDiscountCostText(Panel, RoundIndex)
    if Panel == nil then
        return
    end

    local bDiscount = LotteryConfig.IsDiscountRound(RoundIndex)
    if Panel.Text_zhekou ~= nil then
        if bDiscount then
            Panel.Text_zhekou:SetText("原价x" .. tostring(LotteryConfig.GetOriginalRoundCost(RoundIndex)))
        else
            Panel.Text_zhekou:SetText("本次消耗")
        end
    end
    self:SetWidgetVisible(Panel.Red_Line, bDiscount)
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
    self:ResetAwardBgImages(Panel)
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
    self:SetAwardBgOwned(Panel, AwardIndex, bVisible)
    self:SetAwardIconOwned(Panel, AwardIndex, bVisible)
end

function UI14:ShowAllAwardOKImages(Panel)
    if Panel == nil then
        return
    end

    for Index = 0, 6 do
        self:SetAwardOKVisible(Panel, Index, true)
    end
end

function UI14:ResetAwardBgImages(Panel)
    for Index = 0, 6 do
        self:SetAwardBgOwned(Panel, Index, false)
        self:SetAwardIconOwned(Panel, Index, false)
    end
end

function UI14:SetAwardBgOwned(Panel, AwardIndex, bOwned)
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

function UI14:SetAwardIconOwned(Panel, AwardIndex, bOwned)
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

function UI14:SetImageOwnedColor(Image, bOwned, OwnedColor)
    if Image == nil then
        return
    end

    if bOwned then
        self:SetImageColor(Image, OwnedColor)
    else
        self:RestoreImageColor(Image)
    end
end

function UI14:CopyImageColor(Color)
    Color = Color or DefaultImageColor
    return {
        R = tonumber(Color.R) or 1.0,
        G = tonumber(Color.G) or 1.0,
        B = tonumber(Color.B) or 1.0,
        A = tonumber(Color.A) or 1.0,
    }
end

function UI14:GetImageColor(Image)
    local Color = Image
        and Image.Brush
        and Image.Brush.TintColor
        and Image.Brush.TintColor.SpecifiedColor
        or DefaultImageColor
    return self:CopyImageColor(Color)
end

function UI14:CacheOriginalImageColor(Image)
    if Image == nil then
        return
    end

    self.OriginalImageColors = self.OriginalImageColors or {}
    if self.OriginalImageColors[Image] == nil then
        self.OriginalImageColors[Image] = self:GetImageColor(Image)
    end
end

function UI14:RestoreImageColor(Image)
    if Image == nil then
        return
    end

    self:CacheOriginalImageColor(Image)
    self:SetImageColor(Image, self.OriginalImageColors and self.OriginalImageColors[Image] or DefaultImageColor)
end

function UI14:SetImageColor(Image, Color)
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

function UI14:GetLocalLotteryOKState(LotteryTypeValue)
    self.LocalLotteryOKStates = self.LocalLotteryOKStates or {}
    local Key = tostring(LotteryTypeValue)
    self.LocalLotteryOKStates[Key] = self.LocalLotteryOKStates[Key] or {
        Awards = {},
        Completed = false,
        Round = 0,
    }
    return self.LocalLotteryOKStates[Key]
end

function UI14:ApplyLotteryOKState(Panel, LotteryTypeValue)
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

function UI14:GetServerLotteryState(LotteryTypeValue)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerState = PlayerController and PlayerController.PlayerState or nil
    local State = PlayerState and PlayerState.LotteryState or nil
    return State and State[tostring(LotteryTypeValue)] or nil
end

function UI14:GetLotteryRound(LotteryTypeValue)
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

function UI14:GetLotteryTicketCount()
    return self:GetBackpackLotteryTicketCount()
end

function UI14:GetBackpackLotteryTicketCount()
    if self.bLotteryTicketCountUnavailable == true then
        return 0
    end

    local ItemID = tonumber(LotteryConfig.CostItemID) or 0
    if ItemID <= 0 then
        return 0
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerPawn = PlayerController and PlayerController.Pawn or nil
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil then
        return 0
    end

    local Success, Count = pcall(function()
        return UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)
    end)
    if not Success or Count == nil then
        self.bLotteryTicketCountUnavailable = true
        ugcprint("[UI14:GetBackpackLotteryTicketCount] UGCBackpackSystemV2.GetItemCountV2 unavailable")
        return 0
    end

    return tonumber(Count) or 0
end

function UI14:GetAdjustedLotteryTicketCount()
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

function UI14:RefreshLotteryTicketText()
    if self.TextTicket_Now == nil then
        return
    end

    self.TextTicket_Now:SetText(tostring(self:GetAdjustedLotteryTicketCount()))
end

function UI14:IsLotteryCompleted(LotteryTypeValue)
    local ServerState = self:GetServerLotteryState(LotteryTypeValue)
    if ServerState ~= nil and (ServerState.Completed == true or ServerState.GrandPrize == true) then
        return true
    end

    local LocalState = self.LocalLotteryOKStates and self.LocalLotteryOKStates[tostring(LotteryTypeValue)] or nil
    return LocalState ~= nil and (LocalState.Completed == true or LocalState.Awards["0"] == true)
end

function UI14:CanSummonLottery(LotteryTypeValue)
    if self:IsLotteryCompleted(LotteryTypeValue) then
        return false
    end

    local CostItemID = tonumber(LotteryConfig.CostItemID) or 0
    if CostItemID <= 0 then
        return true
    end

    if self.bLotteryTicketCountUnavailable == true then
        return true
    end

    local Cost = LotteryConfig.GetRoundCost(self:GetLotteryRound(LotteryTypeValue) + 1)
    return self:GetAdjustedLotteryTicketCount() >= Cost
end

function UI14:RefreshSummonButtonState(Panel, LotteryTypeValue)
    if Panel == nil or Panel.Btn_Summon == nil then
        return
    end

    local bEnabled = self:CanSummonLottery(LotteryTypeValue)
    Panel.Btn_Summon:SetIsEnabled(bEnabled)
    if Panel.Btn_Summon.SetRenderOpacity ~= nil then
        Panel.Btn_Summon:SetRenderOpacity(bEnabled and 1.0 or 0.45)
    end
end

function UI14:SetAwardImage(Image, IconPath)
    if Image == nil or IconPath == nil or IconPath == "" then
        return
    end

    local Texture = IconPath
    if type(IconPath) == "string" then
        local Success, LoadedTexture = pcall(UE.LoadObject, IconPath)
        if not Success then
            ugcprint("[UI14:SetAwardImage] load exception: " .. tostring(IconPath))
            return
        end
        Texture = LoadedTexture
    end
    if Texture == nil then
        ugcprint("[UI14:SetAwardImage] load failed: " .. tostring(IconPath))
        return
    end

    if Image.SetBrushFromTexture ~= nil then
        pcall(Image.SetBrushFromTexture, Image, Texture)
    end
end

function UI14:RefreshAwardPreview(Award)
    if Award == nil or self.Img_Award == nil then
        return
    end

    self:SetAwardImage(self.Img_Award, Award.IconPath)
    if self.Text_AwardName ~= nil then
        self.Text_AwardName:SetText(Award.Name or "")
    end
end

function UI14:RequestLottery(LotteryTypeValue)
    LotteryTypeValue = tonumber(LotteryTypeValue) or self.SelectedLotteryType
    local Config = LotteryConfig.GetPool(LotteryTypeValue)
    if Config == nil then
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        ugcprint("[UI14:RequestLottery] PlayerController is nil")
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

function UI14:OnLotteryResult(LotteryTypeValue, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
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

    local function HideManagedWidget(FunctionName)
        if UGCWidgetManagerSystem == nil or UGCWidgetManagerSystem[FunctionName] == nil then
            return
        end

        local Success, Widget = pcall(UGCWidgetManagerSystem[FunctionName])
        if Success then
            HideWidget(Widget)
        end
    end

    HideManagedWidget("GetMainUI")
    HideManagedWidget("GetMainControlUI")
    HideManagedWidget("GetShootingUIPanel")
    HideManagedWidget("GetSkillRootPanel")
end

function UI14:Destruct()
    self:RemoveShopPurchaseCallbacks()
    self:SetBattleUIVisible(true)
end

return UI14
