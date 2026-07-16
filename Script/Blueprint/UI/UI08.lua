---@class UI08_C:UUserWidget
---@field BreakHh BreakHh_C
---@field Btn_Break UButton
---@field Btn_Close UButton
---@field Image_4 UImage
---@field Image_35 UImage
---@field Image_36 UImage
---@field Image_52 UImage
---@field Image_55 UImage
---@field Image_101 UImage
---@field Image_103 UImage
---@field Image_107 UImage
---@field Image_187 UImage
---@field Img_Current UImage
---@field Img_NeedItem_1 UImage
---@field Img_NeedItem_2 UImage
---@field Img_NeedItem_3 UImage
---@field Text_CurrentName UTextBlock
---@field Text_NextName UTextBlock
---@field Text_NextValue UTextBlock
---@field Text_NowValue UTextBlock
---@field TextBlock_0 UTextBlock
---@field TextBlock_1 UTextBlock
---@field TextBlock_2 UTextBlock
---@field TextCailiao UTextBlock
---@field TextZhanli UTextBlock
--Edit Below--
local RealmConfig = UGCGameSystem.UGCRequire("Script.Common.RealmConfig")
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")
local Ma_NumShow = UGCGameSystem.UGCRequire("Script.Ma.Ma_NumShow")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")

local UI08 = { bInitDoOnce = false }

function UI08:Construct()
    self:LuaInit()
end

function UI08:LuaInit()
    if self.bInitDoOnce then
        return
    end

    self.bInitDoOnce = true
    self.CurrentRealmLevel = self:GetPlayerRealmLevel()

    self:BindButton(self.Btn_Close, self.Btn_Close_OnClicked)
    self:BindButton(self.Btn_Break, self.Btn_Break_OnClicked)
    self:HideBreakHh()
    self:Refresh()
end

function UI08:GetWidget(WidgetName)
    local Widget = self[WidgetName]
        or UGCWidgetManagerSystem.GetWidgetFromName(self, WidgetName)
    self[WidgetName] = Widget
    return Widget
end

function UI08:BindButton(Button, Callback)
    if Button == nil then
        return
    end

    Button.OnClicked:Add(Callback, self)
    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function UI08:Open()
    self:SetBattleUIVisible(false)
    self.CurrentRealmLevel = self:GetPlayerRealmLevel()
    self:HideBreakHh()
    self:Refresh()
    self:SetVisibility(ESlateVisibility.Visible)
end

function UI08:Btn_Close_OnClicked()
    self:SetBattleUIVisible(true)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI08:Btn_Break_OnClicked()
    local NextConfig = RealmConfig.GetNext(self.CurrentRealmLevel)
    if NextConfig == nil then
        return
    end

    local HasPower = self:HasEnoughPower(NextConfig)
    local HasItems = self:HasEnoughNeedItems(NextConfig)
    if not HasPower or not HasItems then
        local ToastText = ""
        if not HasPower and not HasItems then
            ToastText = "战力和突破材料均不足"
        elseif not HasPower then
            ToastText = "战力不足，当前" .. Ma_NumShow.Format(self:GetCurrentPower()) ..
                            "，需要" .. Ma_NumShow.Format(tonumber(NextConfig.NeedPower) or 0)
        else
            ToastText = "突破材料不足"
        end

        if L_Com ~= nil and L_Com.ShowToast ~= nil then
            L_Com.ShowToast(ToastText)
        else
            ugcprint("[UI08:Btn_Break_OnClicked] L_Com.ShowToast is nil: " .. ToastText)
        end
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)

    if PlayerController ~= nil and PlayerController.Server_BreakRealm ~= nil then
        UnrealNetwork.CallUnrealRPC(
            PlayerController,
            PlayerController,
            "Server_BreakRealm",
            self.CurrentRealmLevel + 1
        )
        return
    end
    ugcprint("[UI08:Btn_Break_OnClicked] Server_BreakRealm is nil")
end

function UI08:Refresh()
    local CurrentConfig = RealmConfig.Get(self.CurrentRealmLevel) or RealmConfig.Get(1)
    local NextConfig = RealmConfig.GetNext(self.CurrentRealmLevel)
    self:PreloadRealmIcon(CurrentConfig)
    self:PreloadRealmIcon(NextConfig)
    self:SetText(self.Text_CurrentName, RealmConfig.GetDisplayName(CurrentConfig))
    self:SetImage(self.Img_Current, CurrentConfig.IconPath)
    self:RefreshNextRealm(CurrentConfig, NextConfig)
end
function UI08:RefreshNextRealm(CurrentConfig, NextConfig)
    if NextConfig == nil then
        self:SetText(self:GetWidget("Text_NextName"), "已达最高境界")
        self:SetText(self:GetWidget("Text_NowValue"), self:BuildCurrentBonusText(CurrentConfig.SuccessBonuses))
        self:SetText(self:GetWidget("Text_NextValue"), "")
        self:SetText(self:GetWidget("TextZhanli"), "所需战力：已满")
        self:RefreshNeedItems(nil)
        self:SetButtonEnabled(self.Btn_Break, false)
        return
    end
    local CurrentBonuses = CurrentConfig.SuccessBonuses or CurrentConfig.Bonuses or {}
    local Bonuses = NextConfig.SuccessBonuses or NextConfig.Bonuses or {}
    self:SetText(self:GetWidget("Text_NextName"), RealmConfig.GetDisplayName(NextConfig))
    self:SetText(self:GetWidget("Text_NowValue"), self:BuildCompareLeftText(CurrentBonuses, Bonuses))
    self:SetText(self:GetWidget("Text_NextValue"), self:BuildCompareRightText(Bonuses))
    self:SetText(self:GetWidget("TextZhanli"), self:BuildNeedPowerText(NextConfig))
    self:RefreshBreakButton(NextConfig)
end

function UI08:BuildCurrentBonusText(Bonuses)
    local Lines = {}
    for _, BonusText in ipairs(Bonuses or {}) do
        local Label, Value = self:ParseBonusText(BonusText)
        table.insert(Lines, Label .. "加成" .. Value)
    end
    return table.concat(Lines, "\n")
end
function UI08:BuildCompareLeftText(Bonuses, NextBonuses)
    local Lines = {}
    local CurrentValues = {}
    for _, BonusText in ipairs(Bonuses or {}) do
        local Label, Value = self:ParseBonusText(BonusText)
        CurrentValues[Label] = Value
    end
    for _, BonusText in ipairs(NextBonuses or Bonuses or {}) do
        local Label = self:ParseBonusText(BonusText)
        table.insert(Lines, Label .. "加成" .. tostring(CurrentValues[Label] or "0%") .. "→")
    end
    return table.concat(Lines, "\n")
end
function UI08:BuildCompareRightText(Bonuses)
    local Lines = {}
    for _, BonusText in ipairs(Bonuses or {}) do
        local _, Value = self:ParseBonusText(BonusText)
        table.insert(Lines, Value)
    end
    return table.concat(Lines, "\n")
end
function UI08:ParseBonusText(BonusText)
    local Label, Value = RealmConfig.ParseBonusText(BonusText)
    return Label, tostring(Value) .. "%"
end
function UI08:BuildNeedPowerText(Config)
    if Config == nil then
        return ""
    end

    local NeedPower = tonumber(Config.NeedPower)
    if NeedPower == nil then
        return "所需战力：------"
    end

    return "所需战力：" .. Ma_NumShow.Format(NeedPower)
end
function UI08:GetCurrentPower()
    if StateMgr == nil or StateMgr.GetFinalZhanLi == nil then
        return 0
    end

    return tonumber(StateMgr:GetFinalZhanLi()) or 0
end
function UI08:HasEnoughPower(Config)
    if Config == nil then
        return false
    end

    local NeedPower = tonumber(Config.NeedPower)
    if NeedPower == nil then
        return false
    end

    return self:GetCurrentPower() >= NeedPower
end
function UI08:RefreshBreakButton(Config)
    self:RefreshNeedItems(Config)
    self:SetButtonEnabled(self.Btn_Break, Config ~= nil)
end
function UI08:GetBackpackItemCount(ItemID)
    ItemID = tonumber(ItemID)
    if ItemID == nil then
        return 0
    end
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        return tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0
    end
    return 0
end
function UI08:RefreshNeedItems(Config)
    local NeedItems = {}
    if Config ~= nil then
        NeedItems = Config.NeedItems or {}
    end
    local TextBlockIndexes = { 1, 0, 2 }
    local CanBreak = true
    for Index = 1, 3 do
        local Image = self:GetWidget("Img_NeedItem_" .. tostring(Index))
        local TextBlock = self:GetWidget("TextBlock_" .. tostring(TextBlockIndexes[Index]))
        local Item = NeedItems[Index]
        local HasItem = Item ~= nil
        if HasItem then
            local NeedCount = tonumber(Item.Count) or 0
            local CurrentCount = self:GetBackpackItemCount(Item.ItemID)
            if CurrentCount < NeedCount then
                CanBreak = false
            end
        end
        if Image ~= nil then
            if HasItem and Item.IconPath ~= nil and Item.IconPath ~= "" then
                self:SetImage(Image, Item.IconPath)
                Image:SetVisibility(ESlateVisibility.Visible)
            else
                Image:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
        if TextBlock ~= nil then
            if HasItem then
                self:SetText(TextBlock, self:BuildNeedItemSingleText(Item))
                TextBlock:SetVisibility(ESlateVisibility.Visible)
            else
                self:SetText(TextBlock, "")
                TextBlock:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end
    return CanBreak
end
function UI08:HasEnoughNeedItems(Config)
    if Config == nil then
        return false
    end
    for _, Item in ipairs(Config.NeedItems or {}) do
        local NeedCount = tonumber(Item.Count) or 0
        local CurrentCount = self:GetBackpackItemCount(Item.ItemID)
        if CurrentCount < NeedCount then
            return false
        end
    end
    return true
end
function UI08:BuildNeedItemSingleText(Item)
    if Item == nil then
        return ""
    end
    local NeedCount = tonumber(Item.Count) or 0
    local CurrentCount = self:GetBackpackItemCount(Item.ItemID)
    return tostring(Item.Name or Item.ItemID) .. ":" .. tostring(CurrentCount) .. "/" .. tostring(NeedCount)
end
function UI08:SetText(TextBlock, Text)
    if TextBlock ~= nil then
        TextBlock:SetText(Text or "")
    end
end

function UI08:SetImage(Image, IconPath)
    if Image == nil then
        return
    end
    if IconPath == nil or IconPath == "" then
        self:ClearImage(Image)
        return
    end
    local Texture = UE.LoadObject(IconPath)
    if Texture == nil then
        ugcprint("[UI08] Load realm icon failed: " .. tostring(IconPath))
        return
    end
    Image:SetBrushFromTexture(Texture)
    self:ResetImageColor(Image)
end
function UI08:PreloadRealmIcon(Config)
    if Config == nil or Config.IconPath == nil or Config.IconPath == "" then
        return
    end
    self.RealmIconCache = self.RealmIconCache or {}
    if self.RealmIconCache[Config.IconPath] ~= nil then
        return
    end
    self.RealmIconCache[Config.IconPath] = UE.LoadObject(Config.IconPath)
end
function UI08:ClearImage(Image)
    if Image == nil then
        return
    end
    if Image.SetColorAndOpacity ~= nil then
        pcall(Image.SetColorAndOpacity, Image, { R = 1.0, G = 1.0, B = 1.0, A = 0.0 })
    end
    if Image.Brush ~= nil and Image.Brush.TintColor ~= nil then
        Image.Brush.TintColor = { SpecifiedColor = { R = 1.0, G = 1.0, B = 1.0, A = 0.0 } }
    end
end
function UI08:ResetImageColor(Image)
    if Image == nil then
        return
    end
    if Image.SetColorAndOpacity ~= nil then
        pcall(Image.SetColorAndOpacity, Image, { R = 1.0, G = 1.0, B = 1.0, A = 1.0 })
    end
    if Image.Brush ~= nil and Image.Brush.TintColor ~= nil then
        Image.Brush.TintColor = { SpecifiedColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 } }
    end
end
function UI08:SetButtonEnabled(Button, Enabled)
    if Button ~= nil then
        Button:SetIsEnabled(Enabled)
    end
end

function UI08:GetPlayerRealmLevel()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil and PlayerController.RealmLevel ~= nil then
        return math.max(1, math.min(RealmConfig.MaxLevel, tonumber(PlayerController.RealmLevel) or 1))
    end
    local PlayerState = nil
    if UGCGameSystem.GetLocalPlayerState ~= nil then
        PlayerState = UGCGameSystem.GetLocalPlayerState()
    end

    if PlayerState ~= nil and PlayerState.GetHunHuan ~= nil then
        return math.max(1, math.min(RealmConfig.MaxLevel, tonumber(PlayerState:GetHunHuan()) or 1))
    end

    return math.max(1, math.min(RealmConfig.MaxLevel, tonumber(self.CurrentRealmLevel) or 1))
end

function UI08:SetBattleUIVisible(isVisible)
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

function UI08:OnRealmLevelChanged(NewLevel)
    self.CurrentRealmLevel = math.max(1, math.min(RealmConfig.MaxLevel, tonumber(NewLevel) or 1))
    self:Refresh()
end
function UI08:OnRealmBreakResult(Success, NewLevel, TargetLevel, FailCount, UsedRate, IsGuaranteed)
    self.CurrentRealmLevel = math.max(1, math.min(RealmConfig.MaxLevel, tonumber(NewLevel) or 1))
    self:Refresh()
    if Success then
        if StateMgr ~= nil and StateMgr.UI ~= nil and StateMgr.JingJieTextShow ~= nil then
            StateMgr:JingJieTextShow(math.max(1, math.min(RealmConfig.MaxLevel, tonumber(NewLevel) or 1)))
        end
        self:ShowBreakHh(self.CurrentRealmLevel, true)
    else
        self:ShowBreakHh(TargetLevel, false)
        self:RefreshNeedItemsAfterDelay()
    end
    ugcprint("[UI08:OnRealmBreakResult] success="
        .. tostring(Success)
        .. ", newLevel=" .. tostring(NewLevel)
        .. ", targetLevel=" .. tostring(TargetLevel)
        .. ", failCount=" .. tostring(FailCount)
        .. ", rate=" .. tostring(UsedRate)
        .. ", guaranteed=" .. tostring(IsGuaranteed))
end
function UI08:RefreshNeedItemsAfterDelay()
    local TimerName = "UI08_RefreshNeedItemsAfterFail_" .. tostring(self)
    UGCTimerUtility.RemoveLuaTimerByName(TimerName)
    UGCTimerUtility.CreateLuaTimer(0.3, function()
        if self == nil then
            return
        end
        local NextConfig = RealmConfig.GetNext(self.CurrentRealmLevel)
        self:RefreshBreakButton(NextConfig)
    end, false, TimerName)
end
function UI08:HideBreakHh()
    local BreakHh = self:GetWidget("BreakHh")
    if BreakHh == nil then
        return
    end
    BreakHh:SetVisibility(ESlateVisibility.Collapsed)
    if BreakHh.SetIsEnabled ~= nil then
        BreakHh:SetIsEnabled(false)
    end
end
function UI08:ShowBreakHh(Level, bSuccess)
    local BreakHh = self:GetWidget("BreakHh")
    local Config = RealmConfig.Get(Level)
    if BreakHh == nil or Config == nil then
        return
    end
    if BreakHh.ShowBreakResult ~= nil then
        BreakHh:ShowBreakResult(Config.IconPath, bSuccess ~= false)
        return
    end
    if BreakHh.ShowBreakSuccess ~= nil then
        BreakHh:ShowBreakSuccess(Config.IconPath)
        return
    end
    self:SetImage(BreakHh.Img_Hh, Config.IconPath)
    BreakHh:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if BreakHh.SetIsEnabled ~= nil then
        BreakHh:SetIsEnabled(true)
    end
end
function UI08:Destruct()
    self:SetBattleUIVisible(true)
end

return UI08
