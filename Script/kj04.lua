---@class kj04_C:UUserWidget
---@field Btn_Buy UButton
---@field Btn_Close UButton
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_45 UImage
---@field Image_107 UImage
---@field Image_108 UImage
---@field Image_109 UImage
---@field Image_110 UImage
---@field Image_111 UImage
---@field Image_112 UImage
---@field Image_113 UImage
--Edit Below--
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local GiftPackPurchaseService = UGCGameSystem.UGCRequire("Script.Common.GiftPackPurchaseService")

local kj04 = { bInitDoOnce = false } 

function kj04:Construct()
    self:LuaInit()
end

function kj04:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    self:ApplyButtonEffect(self.Btn_Buy)
    self:ApplyButtonEffect(self.Btn_Close)

    if self.Btn_Buy ~= nil then
        self.Btn_Buy.OnClicked:Add(self.Btn_Buy_OnClicked, self)
    end

    if self.Btn_Close ~= nil then
        self.Btn_Close.OnClicked:Add(self.Btn_Close_OnClicked, self)
    end

    self:RefreshBuyButtonState()
end

function kj04:ApplyButtonEffect(Button)
    if Button == nil or UIEffectUtil == nil then
        return
    end

    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function kj04:Btn_Buy_OnClicked()
    if self:HasPurchasedGiftPack() then
        self:RefreshBuyButtonState()
        return
    end

    self:PurchaseGiftPack()
end

function kj04:Btn_Close_OnClicked()
    if self.RemoveFromParent ~= nil then
        self:RemoveFromParent()
    elseif self.SetVisibility ~= nil then
        self:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function kj04:PurchaseGiftPack()
    if self:HasPurchasedGiftPack() then
        self:RefreshBuyButtonState()
        return false
    end

    if GiftPackPurchaseService == nil then
        return false
    end

    local Widget = self
    local PurchaseFuture = GiftPackPurchaseService:Purchase("FirstRecharge", {
        OnPurchaseSuccess = function()
            Widget:UnlockFlight()
            Widget:SetGiftPackPurchased(true)
        end,
    })
    return PurchaseFuture ~= nil
end

function kj04:UnlockFlight()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    if PlayerController.PlayerState ~= nil then
        PlayerController.PlayerState.FeiButton0Hidden = 1
    end
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_SetFeiButton0Hidden", 1)
end

function kj04:HasPurchasedGiftPack()
    if self.bGiftPackPurchased ~= nil then
        return self.bGiftPackPurchased == true
    end

    local PlayerState = self:GetLocalPlayerState()
    if PlayerState == nil then
        return false
    end

    if PlayerState.GetKJ04GiftPackPurchased ~= nil then
        return PlayerState:GetKJ04GiftPackPurchased() == true
    end

    return tonumber(PlayerState.KJ04GiftPackPurchased) == 1
end

function kj04:GetLocalPlayerState()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    return PlayerController and PlayerController.PlayerState or nil
end

function kj04:SetGiftPackPurchased(value)
    local bPurchased = value == true or tonumber(value) == 1
    self.bGiftPackPurchased = bPurchased

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        if PlayerController.PlayerState ~= nil then
            PlayerController.PlayerState.KJ04GiftPackPurchased = bPurchased and 1 or 0
        end
        -- 购买结果由客户端委托回调收到，但购买判定必须落在服务端存档。
        if bPurchased and UnrealNetwork ~= nil and UnrealNetwork.CallUnrealRPC ~= nil then
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController,
                "Server_SetKJ04GiftPackPurchased", 1)
        end
    end

    self:RefreshBuyButtonState()
end

function kj04:RefreshBuyButtonState()
    if self.Btn_Buy == nil then
        return
    end

    local bPurchased = self:HasPurchasedGiftPack()
    self.Btn_Buy:SetIsEnabled(not bPurchased)

    if self.Btn_Buy.SetRenderOpacity ~= nil then
        self.Btn_Buy:SetRenderOpacity(bPurchased and 0.45 or 1)
    end
end

-- function kj04:Tick(MyGeometry, InDeltaTime)

-- end

function kj04:Destruct()
end

return kj04
