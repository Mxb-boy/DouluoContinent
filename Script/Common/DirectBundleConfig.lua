local DirectBundleConfig = {}

DirectBundleConfig.Packs = {
    NewPlayer = {
        ProductID = 9000059,
        TokenItemID = 1064,
        Rewards = {
            {ItemID = 8310056, Count = 6}, -- 千万年星环
            {ItemID = 8310057, Count = 1}, -- 亿年星环
            {ItemID = 8310064, Count = 10}, -- 爬塔传送券
            {ItemID = 8310069, Count = 2}, -- 30分钟十倍魂环爆率（倍率药水）
        },
    },
    Deluxe = {
        ProductID = 9000060,
        TokenItemID = 1065,
        Rewards = {
            {ItemID = 8310047, Count = 1}, -- 英雄无敌
            {ItemID = 8310007, Count = 1}, -- 自动攻击
            {ItemID = 8310009, Count = 1}, -- 自动拾取
            {ItemID = 8310069, Count = 10}, -- 倍率药水
        },
    },
    Forge = {
        ProductID = 9000061,
        TokenItemID = 1066,
        Rewards = {
            {ItemID = 8310035, Count = 100}, -- 熔骨熔晶
            {ItemID = 8310036, Count = 2}, -- 千年星核
            {ItemID = 8310069, Count = 2}, -- 倍率药水
            {ItemID = 8310121, Count = 2}, -- 强化保护卷
        },
    },
    Realm = {
        ProductID = 9000062,
        TokenItemID = 1067,
        Rewards = {
            {ItemID = 8310038, Count = 2}, -- 融星玉
            {ItemID = 8310039, Count = 1}, -- 领域之核
            {ItemID = 8310064, Count = 10}, -- 爬塔传送券
            {ItemID = 8310040, Count = 2}, -- 法则碎片
        },
    },
    SoulRing = {
        ProductID = 9000063,
        TokenItemID = 1068,
        Rewards = {
            {ItemID = 8310122, Count = 1}, -- 千亿年星环
            {ItemID = 8310123, Count = 1}, -- 兆年星环
            {ItemID = 8310124, Count = 1}, -- 十兆年星环
            {ItemID = 8310125, Count = 1}, -- 百兆年星环
        },
    },
}

DirectBundleConfig.ByTokenItemID = {}
for PackKey, Config in pairs(DirectBundleConfig.Packs) do
    Config.PackKey = PackKey
    DirectBundleConfig.ByTokenItemID[Config.TokenItemID] = Config
end

return DirectBundleConfig
