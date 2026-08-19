UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage.Script.ShopV2.ShopV2Manager")

local DirectBundleConfig = UGCGameSystem.UGCRequire("Script.Common.DirectBundleConfig")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")

local DirectBundlePurchaseService = {
    bAddItemResultBound = false,
}

local function GetLocalPlayerController()
    if UGCGameSystem.GetLocalPlayerController ~= nil then
        local PlayerController = UGCGameSystem.GetLocalPlayerController()
        if PlayerController ~= nil then
            return PlayerController
        end
    end
    return GameplayStatics.GetPlayerController(UGCGameSystem.GameState, 0)
end

function DirectBundlePurchaseService:EnsureCallback()
    if self.bAddItemResultBound == true then
        return true
    end
    if ShopV2Manager == nil or ShopV2Manager.GetVirtualItemManager == nil then
        return false
    end

    local VirtualItemManager = ShopV2Manager:GetVirtualItemManager()
    if VirtualItemManager == nil or VirtualItemManager.AddItemResultDelegate == nil then
        return false
    end

    VirtualItemManager.AddItemResultDelegate:Add(self.OnAddVirtualItem, self)
    self.bAddItemResultBound = true
    return true
end

function DirectBundlePurchaseService:RequestClaim(TokenItemID)
    local PlayerController = GetLocalPlayerController()
    if PlayerController == nil or UnrealNetwork == nil or UnrealNetwork.CallUnrealRPC == nil then
        return false
    end

    local Succeeded = pcall(UnrealNetwork.CallUnrealRPC, PlayerController, PlayerController,
        "Server_ClaimDirectPurchaseBundle", tonumber(TokenItemID))
    return Succeeded
end

function DirectBundlePurchaseService:OnAddVirtualItem(Result)
    if Result == nil or Result.bSucceeded ~= true then
        return
    end

    for RawItemID, RawCount in pairs(Result.ItemList or {}) do
        local ItemID = tonumber(RawItemID)
        local Count = math.floor(tonumber(RawCount) or 0)
        if Count > 0 and DirectBundleConfig.ByTokenItemID[ItemID] ~= nil then
            self:RequestClaim(ItemID)
        end
    end
end

function DirectBundlePurchaseService:RecoverPendingPurchases()
    if self:EnsureCallback() ~= true then
        return
    end

    local PlayerController = GetLocalPlayerController()
    local VirtualItemManager = ShopV2Manager:GetVirtualItemManager()
    if PlayerController == nil or VirtualItemManager == nil or VirtualItemManager.GetItemNum == nil then
        return
    end

    for _, Config in pairs(DirectBundleConfig.Packs) do
        local Succeeded, Count = pcall(VirtualItemManager.GetItemNum, VirtualItemManager,
            Config.TokenItemID, PlayerController)
        if Succeeded and (tonumber(Count) or 0) > 0 then
            self:RequestClaim(Config.TokenItemID)
        end
    end
end

function DirectBundlePurchaseService:Purchase(PackKey)
    local Config = DirectBundleConfig.Packs[PackKey]
    if Config == nil or self:EnsureCallback() ~= true or ShopV2Manager == nil then
        return nil
    end

    local ProductData = ShopV2Manager:GetProductConfigData(Config.ProductID)
    if ProductData == nil or tonumber(ProductData.ItemID) ~= tonumber(Config.TokenItemID) then
        ugcprint("[DirectBundle] invalid product mapping key=" .. tostring(PackKey))
        return nil
    end

    return L_Com.BuyShopProduct(Config.ProductID, 1)
end

return DirectBundlePurchaseService
