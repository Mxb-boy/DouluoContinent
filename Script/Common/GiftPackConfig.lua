local GiftPackConfig = {}

GiftPackConfig.OpenRetryIntervalSeconds = 0.2
GiftPackConfig.OpenRetryCount = 10
GiftPackConfig.ConfirmationTimeoutSeconds = 120
GiftPackConfig.ProcessTimeoutSeconds = 15

-- Add future gift packs here. Reward counts remain in UGCGiftPack/UGCDrop.
GiftPackConfig.Packs = {
    FirstRecharge = {
        ProductID = 9000051,
        GiftPackID = 900051,
        GiftItemID = 1055,
        SuppressOfficialGetUI = true,
    },
    TalentPoint = {
        ProductID = 9000058,
        GiftPackID = 900058,
        GiftItemID = 1063,
        SuppressOfficialGetUI = true,
    },
}

-- HandledByShopV2 means the existing ShopV2 OnAddVirtualItem mapping already
-- transfers this virtual item to Backpack V2. Gift-only rewards can omit it;
-- the project-side gift service will transfer those rewards itself.
GiftPackConfig.RewardMappings = {
    [1028] = {BackpackItemID = 8310012, HandledByShopV2 = true},
    [1047] = {BackpackItemID = 8310051, HandledByShopV2 = true},
    [1057] = {BackpackItemID = 8310121, HandledByShopV2 = true},
    [1058] = {BackpackItemID = 8310132, HandledByShopV2 = true},
}

return GiftPackConfig
