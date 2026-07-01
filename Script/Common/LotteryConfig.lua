local LotteryConfig = {}

local ProjectRootPath = UGCMapInfoLib.GetRootLongPackagePath()

local function GetIconPath(IconName)
    return ProjectRootPath .. "Asset/ui/Icon/" .. IconName .. "." .. IconName
end

LotteryConfig.Types = {
    Weapon = 1,
    Wing = 2,
    Title = 3,
    FHSY = 4,
}

LotteryConfig.CostItemID = 8310006

LotteryConfig.RoundCosts = { 8, 38, 88, 128, 188, 268, 368 }
LotteryConfig.DiscountCosts = { 4, 19, 44, 64 }
LotteryConfig.DiscountRoundCount = 4
LotteryConfig.MaxRound = 7
LotteryConfig.SmallAwardWeight = 165
LotteryConfig.GrandPrizeWeight = 10
LotteryConfig.CompleteOnGrandPrize = true
LotteryConfig.GrantMissingAwardsOnGrandPrize = true
LotteryConfig.LockPoolOnComplete = true
LotteryConfig.ResetPoolOnComplete = false

LotteryConfig.Pools = {
    [LotteryConfig.Types.Weapon] = {
        Name = "Weapon",
        GrandPrizeRound = 7,
        GrandPrize = { ItemID = 0, Count = 1, Weight = LotteryConfig.GrandPrizeWeight, IconPath = "" },
        Awards = {
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
        },
    },
    [LotteryConfig.Types.Wing] = {
        Name = "Wing",
        GrandPrizeRound = 7,
        GrandPrize = { ItemID = 0, Count = 1, Weight = LotteryConfig.GrandPrizeWeight, IconPath = "" },
        Awards = {
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
        },
    },
    [LotteryConfig.Types.Title] = {
        Name = "Title",
        GrandPrizeRound = 7,
        GrandPrize = { ItemID = 0, Count = 1, Weight = LotteryConfig.GrandPrizeWeight, IconPath = "" },
        Awards = {
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
            { ItemID = 0, Count = 1, Weight = LotteryConfig.SmallAwardWeight, IconPath = "" },
        },
    },
    [LotteryConfig.Types.FHSY] = {
        Name = "FHSY",
        GrandPrizeRound = 7,
        GrandPrize = { ItemID = 8310044, Count = 1, Weight = LotteryConfig.GrandPrizeWeight, Name = "LV9_FHSY", IconPath = GetIconPath("fhsy") },
        Awards = {
            { ItemID = 8310038, Count = 1, Weight = LotteryConfig.SmallAwardWeight, Name = "LV3_HSZZ", IconPath = GetIconPath("hszz") },
            { ItemID = 8310039, Count = 1, Weight = LotteryConfig.SmallAwardWeight, Name = "LV4_LYZH", IconPath = GetIconPath("lyzh") },
            { ItemID = 8310040, Count = 1, Weight = LotteryConfig.SmallAwardWeight, Name = "LV5_FZSP", IconPath = GetIconPath("fzsp") },
            { ItemID = 8310041, Count = 1, Weight = LotteryConfig.SmallAwardWeight, Name = "LV6_DHY", IconPath = GetIconPath("dhy") },
            { ItemID = 8310042, Count = 1, Weight = LotteryConfig.SmallAwardWeight, Name = "LV7_SHY", IconPath = GetIconPath("shy") },
            { ItemID = 8310043, Count = 1, Weight = LotteryConfig.SmallAwardWeight, Name = "LV8_SSZX", IconPath = GetIconPath("sszx") },
        },
    },
}

function LotteryConfig.GetPool(LotteryType)
    return LotteryConfig.Pools[tonumber(LotteryType) or 0]
end

function LotteryConfig.GetRoundCost(RoundIndex)
    RoundIndex = tonumber(RoundIndex) or 1
    if RoundIndex <= LotteryConfig.DiscountRoundCount and LotteryConfig.DiscountCosts[RoundIndex] ~= nil then
        return LotteryConfig.DiscountCosts[RoundIndex]
    end

    return LotteryConfig.RoundCosts[RoundIndex] or LotteryConfig.RoundCosts[LotteryConfig.MaxRound]
end

function LotteryConfig.IsGrandPrizeRound(LotteryType, RoundIndex)
    local Pool = LotteryConfig.GetPool(LotteryType)
    return Pool ~= nil and tonumber(RoundIndex) == Pool.GrandPrizeRound
end

function LotteryConfig.GetAllAwards(LotteryType)
    local Pool = LotteryConfig.GetPool(LotteryType)
    if Pool == nil then
        return {}
    end

    local Awards = {}
    table.insert(Awards, Pool.GrandPrize)
    for _, Award in ipairs(Pool.Awards) do
        table.insert(Awards, Award)
    end
    return Awards
end

function LotteryConfig.GetAwardByItemID(ItemID)
    ItemID = tonumber(ItemID) or 0
    for _, Pool in pairs(LotteryConfig.Pools) do
        if Pool.GrandPrize ~= nil and tonumber(Pool.GrandPrize.ItemID) == ItemID then
            return Pool.GrandPrize
        end
        for _, Award in ipairs(Pool.Awards or {}) do
            if tonumber(Award.ItemID) == ItemID then
                return Award
            end
        end
    end
    return nil
end

function LotteryConfig.CanDrawCompletedPool()
    return not LotteryConfig.LockPoolOnComplete or LotteryConfig.ResetPoolOnComplete
end

return LotteryConfig
