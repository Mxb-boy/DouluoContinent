---@class Fei_C:UUserWidget
---@field Button_0 UButton
---@field Button_84 UButton
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local RankMgr = UGCGameSystem.UGCRequire("Script.Xiao.RankMgr")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

local FLY_SPEED = 3600
local FLY_START_ANIM_PATH = "/Game/UGC/Repository/Arts_Player/Anim/Dash/AS_DashStart_F.AS_DashStart_F"
local FLY_LOOP_ANIM_PATH = "/Game/UGC/Repository/Arts_Player/Anim/Dash/AS_Dash_F.AS_Dash_F"
local FLY_END_ANIM_PATH = "/Game/UGC/Repository/Arts_Player/Anim/Dash/AS_DashEnd_F.AS_DashEnd_F"
local FLY_START_ANIM_DURATION = 0.45
local FLY_END_ANIM_DURATION = 0.45
local FLY_EFFECT_RELATIVE_PATH = "Asset/cs/P_Speed.P_Speed"
local FLY_EFFECT_SOCKET = "Root"
local FLY_EFFECT_OFFSET = Vector.New(0, 0, 80)
local FLY_EFFECT_ROTATION = Rotator.New(0, 0, 0)
local FLY_EFFECT_SCALE = Vector.New(2, 2, 2)
local FLY_RELEASE_GRACE_TIME = 0.35
local FLY_MOVE_RPC_INTERVAL = 0.05
local WingItemID = 1028
local WingBackpackItemIDs = {8310012, 8310013, 8310014, 8310058, 8310059, 8310010}

local BlockedControlWidgetNames = {
    "MainUI_Jump_C_0",
    "MainUI_Crouch_C_0",
    "MainUI_Crawl_C_0",
    "MainUI_Reload_14_C_0",
    "MainUI_Weapon1_C_0",
    "MainUI_Weapon2_C_0",
    "MainUI_Pistol_C_0",
    "MainUI_AimMode_16_C_0",
    "MainUI_Scope_29_C_0",
    "MainUI_ScopeList_42_C_0",
    "MainUI_ScopeSide_43_C_0",
    "MainUI_Projectile_C_0",
    "MainUI_DrawBow_139_C_0",
    "MainUI_Rush_C_0",
    "MainUI_BackPack_C_0",
}

local Fei = { bInitDoOnce = false } 

local function GetEnumValue(Enum, Names)
    for _, Name in ipairs(Names) do
        local Success, Value = pcall(function()
            return Enum[Name]
        end)
        if Success and Value ~= nil then
            return Value
        end
    end
end

function Fei:Construct()
    self:LuaInit()
end

function Fei:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true
    self:SetupRootHitTest()
    self:SetupKeyboardInputMode()

    if self.Button_0 ~= nil then
        UIEffectUtil.SetButtonStateBrushSameAsNormal(self.Button_0)
        UIEffectUtil.BindPressScale(self, self.Button_0, self.Button_0, 1.06, 1.0)
        self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self)
        self:RefreshButton0Visibility()
        self:RefreshButton0VisibilityLater(3)
    end

    if self.Button_84 ~= nil then
        UIEffectUtil.SetButtonStateBrushSameAsNormal(self.Button_84)
        UIEffectUtil.BindPressScale(self, self.Button_84, self.Button_84, 1.06, 1.0)
        self:SetupFlyButtonInputMode()

        if self.Button_84.OnPressed ~= nil then
            self.Button_84.OnPressed:Add(self.Button_84_OnPressed, self)
        end
        if self.Button_84.OnReleased ~= nil then
            self.Button_84.OnReleased:Add(self.Button_84_OnReleased, self)
        end
    end
end

function Fei:RefreshButton0VisibilityLater(RetriesRemaining)
    if UGCTimerUtility == nil or UGCTimerUtility.CreateLuaTimer == nil then
        return
    end

    UGCTimerUtility.CreateLuaTimer(0.5, function()
        if self ~= nil and self.RefreshButton0Visibility ~= nil then
            self:RefreshButton0Visibility()
            if (tonumber(RetriesRemaining) or 0) > 0 then
                self:RefreshButton0VisibilityLater(RetriesRemaining - 1)
            end
        end
    end, false)
end

function Fei:SetupRootHitTest()
    if self.SetVisibility ~= nil and ESlateVisibility ~= nil and ESlateVisibility.SelfHitTestInvisible ~= nil then
        pcall(self.SetVisibility, self, ESlateVisibility.SelfHitTestInvisible)
    end
end

function Fei:SetupKeyboardInputMode()
    if self.SetIsFocusable ~= nil then
        pcall(self.SetIsFocusable, self, true)
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil and self.SetUserFocus ~= nil then
        pcall(self.SetUserFocus, self, PlayerController)
    end

    if self.SetKeyboardFocus ~= nil then
        pcall(self.SetKeyboardFocus, self)
    end
end

function Fei:Button_84_OnPressed()
    if not self:IsWingEquipped() then
        self.bFlyButtonHeld = false
        self.FlyButtonReleaseGraceRemaining = nil
        L_Com.ShowToast("请装备翅膀")
        return
    end
    self.bFlyButtonHeld = true
    self.FlyButtonReleaseGraceRemaining = nil
    self:RefreshFlyHoldState()
end

function Fei:Button_84_OnReleased()
    self.FlyButtonReleaseGraceRemaining = FLY_RELEASE_GRACE_TIME
end

function Fei:Button_0_OnClicked()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    local ProductID = self:GetShopProductID(WingItemID)
    if PlayerController == nil or ProductID == nil then
        return
    end
    if ShopV2Manager.bBlockRepeatPurchase == true then
        return
    end

    local PurchaseUIClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath(
        "ExtendResource/ShopV2/OfficialPackage/Asset/ShopV2/Arts_UI/UIBP/ShopV2_PurchasePopups_UIBP.ShopV2_PurchasePopups_UIBP_C"))
    if PurchaseUIClass == nil then
        return
    end

    local PurchaseUI = UserWidget.NewWidgetObjectBP(PlayerController, PurchaseUIClass)
    if PurchaseUI == nil then
        return
    end

    local ProductData = ShopV2Manager:GetProductConfigData(ProductID)
    if ProductData ~= nil and RankMgr ~= nil and RankMgr.BeginConsumePurchase ~= nil then
        RankMgr:BeginConsumePurchase(ProductID, ProductData.ItemID, ShopV2Manager:GetDiscountPrice(ProductID), 1)
    end

    self:EnsureShopPurchaseCallbacks()
    ShopV2Manager.bBlockRepeatPurchase = true
    PurchaseUI:AddToViewport(15000)
    PurchaseUI:Refresh(ProductID)
end

function Fei:OnFeiAddVirtualItem(Result)
    if Result == nil or Result.bSucceeded ~= true or Result.ItemList == nil then
        return
    end

    local bGotWing = Result.ItemList[WingItemID] ~= nil or Result.ItemList[tostring(WingItemID)] ~= nil
    if not bGotWing then
        for _, ItemID in ipairs(WingBackpackItemIDs) do
            if Result.ItemList[ItemID] ~= nil or Result.ItemList[tostring(ItemID)] ~= nil then
                bGotWing = true
                break
            end
        end
    end

    if bGotWing then
        if RankMgr ~= nil and RankMgr.ConfirmConsumePurchase ~= nil then
            RankMgr:ConfirmConsumePurchase(WingItemID)
        end
        self:SetButton0Hidden(true)
    end
end

function Fei:SetButton0Hidden(value)
    local bHidden = value == true or tonumber(value) == 1
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        if PlayerController.PlayerState ~= nil then
            PlayerController.PlayerState.FeiButton0Hidden = bHidden and 1 or 0
        end
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_SetFeiButton0Hidden", bHidden and 1 or 0)
    end

    if self.Button_0 ~= nil then
        self.Button_0:SetVisibility(bHidden and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
    end
end

function Fei:SetTowerButtonsHidden(value)
    if value == true or tonumber(value) == 1 then
        self.TowerButtonsHiddenCount = (self.TowerButtonsHiddenCount or 0) + 1
    else
        self.TowerButtonsHiddenCount = math.max(0, (self.TowerButtonsHiddenCount or 0) - 1)
    end

    self:RefreshButton0Visibility()
end

function Fei:RefreshButton0Visibility()
    local bHasWing = self:HasAnyWing()
    local bTowerHidden = (self.TowerButtonsHiddenCount or 0) > 0
    if self.Button_0 ~= nil then
        self.Button_0:SetVisibility((bHasWing or bTowerHidden) and ESlateVisibility.Collapsed or
                                        ESlateVisibility.Visible)
    end
    if self.Button_84 ~= nil then
        self.Button_84:SetVisibility((bHasWing and not bTowerHidden) and ESlateVisibility.Visible or
                                         ESlateVisibility.Collapsed)
    end
end

function Fei:HasFeiButton0Hidden()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    local PlayerState = PlayerController and PlayerController.PlayerState
    if PlayerState == nil then
        return false
    end

    if PlayerState.GetFeiButton0Hidden ~= nil then
        return PlayerState:GetFeiButton0Hidden() == true
    end

    return tonumber(PlayerState.FeiButton0Hidden) == 1
end

function Fei:HasAnyWing()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerPawn = PlayerController and PlayerController.Pawn or nil
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetItemCountV2 == nil then
        return false
    end

    for _, ItemID in ipairs(WingBackpackItemIDs) do
        if (tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0) > 0 then
            return true
        end
    end

    return false
end

function Fei:IsWingEquipped()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    local PlayerPawn = PlayerController and (PlayerController.Pawn or
        (PlayerController.K2_GetPawn ~= nil and PlayerController:K2_GetPawn() or nil)) or nil
    if PlayerPawn ~= nil and tonumber(PlayerPawn.CurrentEquippedWingItemID) ~= nil and
        tonumber(PlayerPawn.CurrentEquippedWingItemID) > 0 then
        return true
    end
    -- Wing actor updates this value on the owning client, so it also covers an
    -- already-equipped wing restored before the backpack callback is received.
    return StateMgr ~= nil and (tonumber(StateMgr.ChiBang) or 0) > 0
end

function Fei:GetShopProductID(ItemID)
    local ProductDatas = ShopV2Manager:GetAllProductConfigData()
    for ProductID, ProductData in pairs(ProductDatas) do
        if tonumber(ProductData.ItemID) == ItemID then
            return tonumber(ProductData.ProductID) or tonumber(ProductData.ProductId) or tonumber(ProductID)
        end
    end

    return nil
end

function Fei:EnsureShopPurchaseCallbacks()
    if ShopV2Manager.bBuyProductResultBinded ~= true then
        ShopV2Manager:GetCommodityOperationManager().BuyProductResultDelegate:Add(ShopV2Manager.OnBuyProductResult,
            ShopV2Manager)
        ShopV2Manager.bBuyProductResultBinded = true
    end

    if ShopV2Manager.bAddItemResultDelegateBinded ~= true then
        ShopV2Manager:GetVirtualItemManager().AddItemResultDelegate:Add(ShopV2Manager.OnAddVirtualItem, ShopV2Manager)
        ShopV2Manager.bAddItemResultDelegateBinded = true
    end

    if self.bFeiAddVirtualItemResultBinded ~= true then
        ShopV2Manager:GetVirtualItemManager().AddItemResultDelegate:Add(self.OnFeiAddVirtualItem, self)
        self.bFeiAddVirtualItemResultBinded = true
    end
end

function Fei:SetupFlyButtonInputMode()
    if self.Button_84 == nil then
        return
    end

    if self.Button_84.SetIsFocusable ~= nil then
        pcall(self.Button_84.SetIsFocusable, self.Button_84, false)
    end

    if self.Button_84.SetTouchMethod ~= nil and EButtonTouchMethod ~= nil then
        local TouchMethod = GetEnumValue(EButtonTouchMethod, {"DownAndUp"})
        if TouchMethod ~= nil then
            pcall(self.Button_84.SetTouchMethod, self.Button_84, TouchMethod)
        end
    end

    if self.Button_84.SetClickMethod ~= nil and EButtonClickMethod ~= nil then
        local ClickMethod = GetEnumValue(EButtonClickMethod, {"DownAndUp"})
        if ClickMethod ~= nil then
            pcall(self.Button_84.SetClickMethod, self.Button_84, ClickMethod)
        end
    end
end

function Fei:StartFly()
    if self.bFlying then
        return
    end
    if not self:IsWingEquipped() then
        L_Com.ShowToast("请装备翅膀")
        return
    end

    self.bFlying = true
    self.FlyMoveRpcElapsed = FLY_MOVE_RPC_INTERVAL
    self:BeginFly()
    self:SetFlyMovementMode(true)
    self:PlayFlyStartAnimation()
    self:SpawnFlyEffect()
    self:SetOtherBlueprintUIHidden(true)
    self:SetNativeControlBlocked(true)
end

function Fei:StopFly()
    if not self.bFlying then
        return
    end

    self.bFlying = false
    self:EndFly()
    self:PlayFlyEndAnimation()
    self:DestroyFlyEffect()
    self:SetFlyMovementMode(false)
    self:SetOtherBlueprintUIHidden(false)
    self:SetNativeControlBlocked(false)
end

function Fei:Tick(MyGeometry, InDeltaTime)
    self.WingRefreshElapsed = (self.WingRefreshElapsed or 0) + (tonumber(InDeltaTime) or 0)
    if self.WingRefreshElapsed >= 0.5 then
        self.WingRefreshElapsed = 0
        self:RefreshButton0Visibility()
        if self.bFlying and not self:IsWingEquipped() then
            self.bFlyButtonHeld = false
            self.bFlyKeyboardHeld = false
            self.FlyButtonReleaseGraceRemaining = nil
            self:StopFly()
        end
    end
    self:UpdateKeyboardHold()
    self:UpdateButtonReleaseGrace(InDeltaTime)
    self:RefreshFlyHoldState()

    if self.bFlying then
        self:ApplyFlyMovement(InDeltaTime)
    end
end

function Fei:GetKeyNameFromEvent(KeyEvent)
    if KeyEvent == nil then
        return nil
    end

    local Key = nil
    if KeyEvent.GetKey ~= nil then
        local Success, Result = pcall(KeyEvent.GetKey, KeyEvent)
        if Success then
            Key = Result
        end
    end

    Key = Key or KeyEvent.Key or KeyEvent.KeyName
    if Key == nil then
        return nil
    end

    if type(Key) == "string" then
        return Key
    end

    local FunctionNames = { "GetFName", "GetDisplayName", "GetName", "ToString" }
    for _, FunctionName in ipairs(FunctionNames) do
        if Key[FunctionName] ~= nil then
            local Success, Result = pcall(Key[FunctionName], Key)
            if Success and Result ~= nil then
                return tostring(Result)
            end
        end
    end

    return tostring(Key)
end

function Fei:IsFlyKeyName(KeyName)
    if KeyName == nil then
        return false
    end

    KeyName = string.upper(tostring(KeyName))
    return KeyName == "C"
        or KeyName == "KEY_C"
        or KeyName == "EKEYS.C"
        or string.sub(KeyName, -2) == ".C"
        or string.sub(KeyName, -2) == "_C"
end

function Fei:OnKeyDown(MyGeometry, InKeyEvent)
    local KeyName = self:GetKeyNameFromEvent(InKeyEvent)
    if self:IsFlyKeyName(KeyName) then
        self.bFlyKeyboardHeld = true
        self:RefreshFlyHoldState()
    end
end

function Fei:OnKeyUp(MyGeometry, InKeyEvent)
    local KeyName = self:GetKeyNameFromEvent(InKeyEvent)
    if self:IsFlyKeyName(KeyName) then
        self.bFlyKeyboardHeld = false
        self:RefreshFlyHoldState()
    end
end

function Fei:IsFlyKeyDown(PlayerController)
    if PlayerController == nil or PlayerController.IsInputKeyDown == nil then
        return nil
    end

    local bChecked = false
    if EKeys ~= nil and EKeys.C ~= nil then
        local Success, Result = pcall(PlayerController.IsInputKeyDown, PlayerController, EKeys.C)
        bChecked = bChecked or Success
        if Success and Result then
            return true
        end
    end

    if bChecked then
        return false
    end

    return nil
end

function Fei:UpdateKeyboardHold()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    local bKeyDown = self:IsFlyKeyDown(PlayerController)
    if bKeyDown ~= nil then
        self.bFlyKeyboardHeld = bKeyDown
    end
end

function Fei:UpdateButtonReleaseGrace(InDeltaTime)
    if self.FlyButtonReleaseGraceRemaining == nil then
        return
    end

    local DeltaTime = tonumber(InDeltaTime) or 0.016
    if DeltaTime <= 0 or DeltaTime > 0.1 then
        DeltaTime = 0.016
    end

    self.FlyButtonReleaseGraceRemaining = self.FlyButtonReleaseGraceRemaining - DeltaTime
    if self.FlyButtonReleaseGraceRemaining <= 0 then
        self.FlyButtonReleaseGraceRemaining = nil
        self.bFlyButtonHeld = false
    end
end

function Fei:RefreshFlyHoldState()
    local bShouldFly = self.bFlyButtonHeld == true or self.bFlyKeyboardHeld == true
    if bShouldFly and not self.bFlying then
        self:StartFly()
    elseif not bShouldFly and self.bFlying then
        self:StopFly()
    end
end

function Fei:SetOtherBlueprintUIHidden(bHidden)
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    if bHidden then
        self.HiddenBlueprintWidgets = {}
        if PlayerController.MainUIInstance ~= nil
            and PlayerController.MainUIInstance.YXWDBuffIconActive == true then
            ugcprint("[Fei:SetOtherBlueprintUIHidden] keep MainUIInstance visible for YXWD icon")
        else
            self:HideWidget(PlayerController.MainUIInstance)
        end

        if PlayerController.MainUIInstance ~= nil then
            self:HideWidget(PlayerController.MainUIInstance.UI10Instance)
            self:HideWidget(PlayerController.MainUIInstance.TitleUIInstance)
        end
        return
    end

    if self.HiddenBlueprintWidgets == nil then
        return
    end

    for _, Item in ipairs(self.HiddenBlueprintWidgets) do
        if Item.Widget ~= nil and Item.Widget.SetVisibility ~= nil then
            Item.Widget:SetVisibility(Item.Visibility or ESlateVisibility.Visible)
        end
    end
    self.HiddenBlueprintWidgets = nil
end

function Fei:HideWidget(Widget)
    if Widget == nil or Widget == self or Widget.SetVisibility == nil then
        return
    end

    local Visibility = ESlateVisibility.Visible
    if Widget.GetVisibility ~= nil then
        local Success, Result = pcall(Widget.GetVisibility, Widget)
        if Success and Result ~= nil then
            Visibility = Result
        end
    end

    table.insert(self.HiddenBlueprintWidgets, {
        Widget = Widget,
        Visibility = Visibility,
    })
    Widget:SetVisibility(ESlateVisibility.Collapsed)
end

function Fei:BeginFly()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil and PlayerPawn.BeginFly ~= nil then
        PlayerPawn:BeginFly()
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_BeginFlyState")
    end
end

function Fei:EndFly()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil and PlayerPawn.EndFly ~= nil then
        PlayerPawn:EndFly()
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_EndFlyState")
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_StopFlyMove")
    end
end

function Fei:GetFlyAnimation(AnimPath)
    if AnimPath == nil then
        return nil
    end

    self.FlyAnimationCache = self.FlyAnimationCache or {}
    if self.FlyAnimationCache[AnimPath] ~= nil then
        return self.FlyAnimationCache[AnimPath]
    end

    local AnimAsset = UE.LoadObject(AnimPath)
    if AnimAsset ~= nil then
        self.FlyAnimationCache[AnimPath] = AnimAsset
        ugcprint("[Fei] Fly animation loaded: " .. tostring(AnimPath))
        return AnimAsset
    end

    ugcprint("[Fei] Fly animation load failed: " .. tostring(AnimPath))
    return nil
end

function Fei:CacheMeshAnimationState(Mesh)
    if Mesh == nil then
        return
    end

    if self.CacheMeshAnimationMode == nil then
        self.CacheMeshAnimationMode = Mesh.AnimationMode
    end
    if self.CacheMeshAnimClass == nil then
        self.CacheMeshAnimClass = Mesh.AnimClass
    end
end

local function RestoreAnimInstanceClass(Mesh, AnimClass)
    if Mesh == nil or Mesh.SetAnimInstanceClass == nil or AnimClass == nil then
        return
    end

    local Success = pcall(Mesh.SetAnimInstanceClass, Mesh, AnimClass, true)
    if not Success then
        pcall(Mesh.SetAnimInstanceClass, Mesh, AnimClass)
    end
end

function Fei:PlayFlyAnimationByPath(AnimPath, bLoop)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local Mesh = PlayerPawn ~= nil and PlayerPawn.Mesh or nil
    if Mesh == nil then
        return false
    end

    local AnimAsset = self:GetFlyAnimation(AnimPath)
    if AnimAsset == nil then
        self:SetPawnAnimationPaused(true)
        return false
    end

    self:CacheMeshAnimationState(Mesh)
    self:SetPawnAnimationPaused(false)

    if Mesh.PlayAnimation ~= nil then
        local Success = pcall(Mesh.PlayAnimation, Mesh, AnimAsset, bLoop == true)
        if Success then
            self.bPlayingFlyAnimation = true
            return true
        end
    end

    self:SetPawnAnimationPaused(true)
    return false
end

function Fei:PlayFlyStartAnimation()
    self.FlyAnimationSerial = (self.FlyAnimationSerial or 0) + 1
    local Serial = self.FlyAnimationSerial
    local bPlayed = self:PlayFlyAnimationByPath(FLY_START_ANIM_PATH, false)
    if not bPlayed then
        self:PlayFlyLoopAnimation()
        return
    end

    if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
        UGCTimerUtility.CreateLuaTimer(FLY_START_ANIM_DURATION, function()
            if self ~= nil and self.bFlying == true and self.FlyAnimationSerial == Serial then
                self:PlayFlyLoopAnimation()
            end
        end, false)
    else
        self:PlayFlyLoopAnimation()
    end
end

function Fei:PlayFlyLoopAnimation()
    if self.bFlying ~= true then
        return
    end

    self:PlayFlyAnimationByPath(FLY_LOOP_ANIM_PATH, true)
end

function Fei:PlayFlyEndAnimation()
    self.FlyAnimationSerial = (self.FlyAnimationSerial or 0) + 1
    self:PlayFlyAnimationByPath(FLY_END_ANIM_PATH, false)

    if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
        local Serial = self.FlyAnimationSerial
        UGCTimerUtility.CreateLuaTimer(FLY_END_ANIM_DURATION, function()
            if self ~= nil and self.bFlying ~= true and self.FlyAnimationSerial == Serial then
                self:StopFlyAnimation()
                self:SetPawnAnimationPaused(false)
            end
        end, false)
    else
        self:StopFlyAnimation()
        self:SetPawnAnimationPaused(false)
    end
end

function Fei:StopFlyAnimation()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local Mesh = PlayerPawn ~= nil and PlayerPawn.Mesh or nil
    if Mesh ~= nil and self.bPlayingFlyAnimation == true then
        if Mesh.Stop ~= nil then
            pcall(Mesh.Stop, Mesh)
        end
        if Mesh.SetAnimationMode ~= nil and self.CacheMeshAnimationMode ~= nil then
            pcall(Mesh.SetAnimationMode, Mesh, self.CacheMeshAnimationMode)
        end
        if Mesh.SetAnimInstanceClass ~= nil and self.CacheMeshAnimClass ~= nil then
            RestoreAnimInstanceClass(Mesh, self.CacheMeshAnimClass)
        end
    end

    self.bPlayingFlyAnimation = false
    self.CacheAnimationMode = nil
    self.CacheMeshAnimationMode = nil
    self.CacheMeshAnimClass = nil
end

function Fei:SetPawnAnimationPaused(bPaused)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local Mesh = PlayerPawn ~= nil and PlayerPawn.Mesh or nil
    if Mesh == nil then
        return
    end

    if bPaused then
        if self.CacheMeshPauseAnims == nil then
            self.CacheMeshPauseAnims = Mesh.bPauseAnims
        end
        if self.CacheMeshGlobalAnimRateScale == nil then
            self.CacheMeshGlobalAnimRateScale = Mesh.GlobalAnimRateScale
        end

        pcall(function()
            Mesh.bPauseAnims = true
        end)
        pcall(function()
            Mesh.GlobalAnimRateScale = 0
        end)

        if Mesh.SetComponentTickEnabled ~= nil then
            pcall(Mesh.SetComponentTickEnabled, Mesh, false)
        end
        return
    end

    if self.CacheMeshPauseAnims ~= nil then
        local PauseAnims = self.CacheMeshPauseAnims
        pcall(function()
            Mesh.bPauseAnims = PauseAnims
        end)
    else
        pcall(function()
            Mesh.bPauseAnims = false
        end)
    end
    self.CacheMeshPauseAnims = nil

    if self.CacheMeshGlobalAnimRateScale ~= nil then
        local AnimRateScale = self.CacheMeshGlobalAnimRateScale
        pcall(function()
            Mesh.GlobalAnimRateScale = AnimRateScale
        end)
    else
        pcall(function()
            Mesh.GlobalAnimRateScale = 1
        end)
    end
    self.CacheMeshGlobalAnimRateScale = nil

    if Mesh.SetComponentTickEnabled ~= nil then
        pcall(Mesh.SetComponentTickEnabled, Mesh, true)
    end
end

function Fei:GetFlyEffectTemplate()
    if self.FlyEffectTemplate ~= nil then
        return self.FlyEffectTemplate
    end

    local EffectPaths = {}
    if UGCGameSystem ~= nil and UGCGameSystem.GetUGCResourcesFullPath ~= nil then
        local Success, Path = pcall(UGCGameSystem.GetUGCResourcesFullPath, FLY_EFFECT_RELATIVE_PATH)
        if Success and Path ~= nil then
            table.insert(EffectPaths, Path)
        end
    end
    if UGCMapInfoLib ~= nil and UGCMapInfoLib.GetRootLongPackagePath ~= nil then
        table.insert(EffectPaths, UGCMapInfoLib.GetRootLongPackagePath() .. FLY_EFFECT_RELATIVE_PATH)
    end
    table.insert(EffectPaths, "/Douluo/" .. FLY_EFFECT_RELATIVE_PATH)

    for _, EffectPath in ipairs(EffectPaths) do
        self.FlyEffectTemplate = UE.LoadObject(EffectPath)
        if self.FlyEffectTemplate ~= nil then
            self.FlyEffectPath = EffectPath
            ugcprint("[Fei] Fly effect loaded: " .. tostring(EffectPath))
            return self.FlyEffectTemplate
        end
    end

    if self.FlyEffectTemplate == nil then
        ugcprint("[Fei] Fly effect load failed: " .. tostring(FLY_EFFECT_RELATIVE_PATH))
    end

    return self.FlyEffectTemplate
end

function Fei:SpawnFlyEffect()
    if self.FlyEffectComponent ~= nil then
        return
    end

    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil or PlayerPawn.Mesh == nil then
        return
    end

    local EffectTemplate = self:GetFlyEffectTemplate()
    if EffectTemplate == nil or GameplayStatics == nil or GameplayStatics.SpawnEmitterAttached == nil then
        return
    end

    local AttachLocationRule = nil
    if EAttachLocation ~= nil then
        AttachLocationRule = EAttachLocation.SnapToTarget or EAttachLocation.KeepRelativeOffset
    end

    local Success, EffectComponent = false, nil
    if AttachLocationRule ~= nil then
        Success, EffectComponent = pcall(
            GameplayStatics.SpawnEmitterAttached,
            EffectTemplate,
            PlayerPawn.Mesh,
            FLY_EFFECT_SOCKET,
            FLY_EFFECT_OFFSET,
            FLY_EFFECT_ROTATION,
            FLY_EFFECT_SCALE,
            AttachLocationRule,
            false
        )
    end

    if not Success or EffectComponent == nil then
        Success, EffectComponent = pcall(
            GameplayStatics.SpawnEmitterAttached,
            EffectTemplate,
            PlayerPawn.Mesh,
            FLY_EFFECT_SOCKET
        )
    end

    if Success and EffectComponent ~= nil then
        self.FlyEffectComponent = EffectComponent
        ugcprint("[Fei] Fly effect spawned")
    else
        ugcprint("[Fei] Fly effect spawn failed")
    end
end

function Fei:DestroyFlyEffect()
    local EffectComponent = self.FlyEffectComponent
    self.FlyEffectComponent = nil

    if EffectComponent == nil then
        return
    end

    if EffectComponent.Deactivate ~= nil then
        pcall(EffectComponent.Deactivate, EffectComponent)
    end

    if EffectComponent.K2_DestroyComponent ~= nil then
        pcall(EffectComponent.K2_DestroyComponent, EffectComponent, EffectComponent)
    elseif EffectComponent.DestroyComponent ~= nil then
        pcall(EffectComponent.DestroyComponent, EffectComponent)
    end
end

function Fei:ApplyFlyMovement(InDeltaTime)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        return
    end

    local ForwardVector = self:GetViewForwardVector(PlayerPawn)
    if ForwardVector == nil then
        return
    end

    self:ApplyNativeFlyMovement(PlayerPawn, ForwardVector)

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        self.FlyMoveRpcElapsed = (self.FlyMoveRpcElapsed or 0) + (tonumber(InDeltaTime) or 0.016)
        if self.FlyMoveRpcElapsed >= FLY_MOVE_RPC_INTERVAL then
            local RpcDeltaTime = self.FlyMoveRpcElapsed
            self.FlyMoveRpcElapsed = 0
            UnrealNetwork.CallUnrealRPC(
                PlayerController,
                PlayerController,
                "Server_FlyMove",
                ForwardVector.X or 0,
                ForwardVector.Y or 0,
                ForwardVector.Z or 0,
                RpcDeltaTime
            )
        end
    end
end

function Fei:ApplyNativeFlyMovement(PlayerPawn, Direction)
    if PlayerPawn == nil or Direction == nil then
        return
    end

    if PlayerPawn.AddMovementInput ~= nil then
        local Success = pcall(PlayerPawn.AddMovementInput, PlayerPawn, Direction, 1.0, true)
        if Success then
            return
        end
        Success = pcall(PlayerPawn.AddMovementInput, PlayerPawn, Direction, 1.0)
        if Success then
            return
        end
    end

    local MovementComponent = PlayerPawn.CharacterMovement or PlayerPawn.MovementComponent
    if MovementComponent ~= nil and MovementComponent.Velocity ~= nil then
        MovementComponent.Velocity = Vector.New(
            (Direction.X or 0) * FLY_SPEED,
            (Direction.Y or 0) * FLY_SPEED,
            (Direction.Z or 0) * FLY_SPEED
        )
        return
    end

    self:MovePawnByDirection(PlayerPawn, Direction, 0.016)
end

function Fei:GetViewForwardVector(PlayerPawn)
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)

    if PlayerController ~= nil and PlayerController.PlayerCameraManager ~= nil
        and PlayerController.PlayerCameraManager.GetCameraRotation ~= nil then
        local Success, CameraRotation =
            pcall(PlayerController.PlayerCameraManager.GetCameraRotation, PlayerController.PlayerCameraManager)
        if Success and CameraRotation ~= nil and KismetMathLibrary ~= nil
            and KismetMathLibrary.GetForwardVector ~= nil then
            return KismetMathLibrary.GetForwardVector(CameraRotation)
        end
    end

    if PlayerController ~= nil and PlayerController.GetControlRotation ~= nil then
        local Success, ControlRotation = pcall(PlayerController.GetControlRotation, PlayerController)
        if Success and ControlRotation ~= nil and KismetMathLibrary ~= nil
            and KismetMathLibrary.GetForwardVector ~= nil then
            return KismetMathLibrary.GetForwardVector(ControlRotation)
        end
    end

    if PlayerPawn ~= nil and PlayerPawn.GetActorForwardVector ~= nil then
        local Success, ForwardVector = pcall(PlayerPawn.GetActorForwardVector, PlayerPawn)
        if Success then
            return ForwardVector
        end
    end

    return Vector.New(1, 0, 0)
end

function Fei:SetFlyMovementMode(bFlying)
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        return
    end

    local MovementComponent = PlayerPawn.CharacterMovement or PlayerPawn.MovementComponent
    if MovementComponent ~= nil and MovementComponent.SetMovementMode ~= nil then
        if bFlying then
            if self.bFlyMovementModeEnabled == true then
                return
            end
            self.bFlyMovementModeEnabled = true
            if self.CacheGravityScale == nil then
                self.CacheGravityScale = MovementComponent.GravityScale
            end
            pcall(MovementComponent.SetMovementMode, MovementComponent, 5)
            if MovementComponent.GravityScale ~= nil then
                MovementComponent.GravityScale = 0
            end
            if MovementComponent.MaxFlySpeed ~= nil then
                MovementComponent.MaxFlySpeed = FLY_SPEED
            end
            if MovementComponent.MaxWalkSpeed ~= nil then
                self.CacheMaxWalkSpeed = self.CacheMaxWalkSpeed or MovementComponent.MaxWalkSpeed
                MovementComponent.MaxWalkSpeed = FLY_SPEED
            end
            if MovementComponent.Velocity ~= nil then
                MovementComponent.Velocity = Vector.New(0, 0, 0)
            end
        else
            self.bFlyMovementModeEnabled = false
            if self.CacheGravityScale ~= nil and MovementComponent.GravityScale ~= nil then
                MovementComponent.GravityScale = self.CacheGravityScale
            end
            self.CacheGravityScale = nil
            if self.CacheMaxWalkSpeed ~= nil and MovementComponent.MaxWalkSpeed ~= nil then
                MovementComponent.MaxWalkSpeed = self.CacheMaxWalkSpeed
            end
            self.CacheMaxWalkSpeed = nil
            if MovementComponent.Velocity ~= nil then
                MovementComponent.Velocity = Vector.New(0, 0, 0)
            end
            pcall(MovementComponent.SetMovementMode, MovementComponent, 1)
        end
    end
end

function Fei:MovePawnByDirection(PlayerPawn, Direction, DeltaTime)
    if PlayerPawn == nil or Direction == nil or PlayerPawn.K2_GetActorLocation == nil
        or PlayerPawn.K2_SetActorLocation == nil then
        return
    end

    DeltaTime = tonumber(DeltaTime) or 0.016
    if DeltaTime <= 0 or DeltaTime > 0.1 then
        DeltaTime = 0.016
    end

    local Success, Location = pcall(PlayerPawn.K2_GetActorLocation, PlayerPawn)
    if not Success or Location == nil then
        return
    end

    local Distance = FLY_SPEED * DeltaTime
    local NewLocation = Vector.New(
        Location.X + (Direction.X or 0) * Distance,
        Location.Y + (Direction.Y or 0) * Distance,
        Location.Z + (Direction.Z or 0) * Distance
    )

    pcall(PlayerPawn.K2_SetActorLocation, PlayerPawn, NewLocation, true, nil, true)
end

function Fei:SetNativeControlBlocked(bBlocked)
    local MainControlUI = nil
    if UGCWidgetManagerSystem ~= nil and UGCWidgetManagerSystem.GetMainControlUI ~= nil then
        MainControlUI = UGCWidgetManagerSystem.GetMainControlUI()
    end

    if MainControlUI == nil then
        return
    end

    if bBlocked then
        self.HiddenControlWidgets = {}
        for _, WidgetName in ipairs(BlockedControlWidgetNames) do
            self:HideControlWidget(MainControlUI[WidgetName])
        end
        return
    end

    if self.HiddenControlWidgets == nil then
        return
    end

    for _, Item in ipairs(self.HiddenControlWidgets) do
        if Item.Widget ~= nil and Item.Widget.SetVisibility ~= nil then
            Item.Widget:SetVisibility(Item.Visibility or ESlateVisibility.Visible)
        end
    end
    self.HiddenControlWidgets = nil
end

function Fei:HideControlWidget(Widget)
    if Widget == nil or Widget.SetVisibility == nil then
        return
    end

    local Visibility = ESlateVisibility.Visible
    if Widget.GetVisibility ~= nil then
        local Success, Result = pcall(Widget.GetVisibility, Widget)
        if Success and Result ~= nil then
            Visibility = Result
        end
    end

    table.insert(self.HiddenControlWidgets, {
        Widget = Widget,
        Visibility = Visibility,
    })
    Widget:SetVisibility(ESlateVisibility.Collapsed)
end

function Fei:Destruct()
    self:StopFly()
end

return Fei
