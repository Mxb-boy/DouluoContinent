local WeaponLevelConfig = {}

WeaponLevelConfig.MAX_LEVEL = 5

WeaponLevelConfig.LevelNames = {
    [1] = "Lv1",
    [2] = "Lv2",
    [3] = "Lv3",
    [4] = "Lv4",
    [5] = "Lv5",
}

WeaponLevelConfig.Series = {
    HTC = {
        Name = "HTC",
        ItemIDs = { 8310002, 8310015, 8310016, 8310017, 8310018 },
    },
    HWSCJ = {
        Name = "HWSCJ",
        ItemIDs = { 8310000, 8310019, 8310020, 8310021, 8310022 },
    },
    LCSL = {
        Name = "LCSL",
        ItemIDs = { 8310004, 8310023, 8310024, 8310025, 8310026 },
    },
    TSSJ = {
        Name = "TSSJ",
        ItemIDs = { 8310003, 8310027, 8310028, 8310029, 8310030 },
    },
    XJWQ = {
        Name = "XJWQ",
        ItemIDs = { 8310006, 8310031, 8310032, 8310033, 8310034 },
    },
    XLSJ = {
        Name = "XLSJ",
        ItemIDs = { 8310005 },
    },
}

WeaponLevelConfig.ForgeCostByLevel = {
    [1] = { HGRJ = 20, QNHH = 1 },
    [2] = { HGRJ = 50, QNHH = 5 },
    [3] = { HGRJ = 100, QNHH = 10 },
    [4] = { HGRJ = 300, QNHH = 20 },
}

WeaponLevelConfig.ForgeRateBySeries = {
    HWSCJ = {
        [1] = { Success = 65, Keep = 35, Down = 0 },
        [2] = { Success = 52, Keep = 36, Down = 12 },
        [3] = { Success = 38, Keep = 42, Down = 20 },
        [4] = { Success = 22, Keep = 48, Down = 30 },
    },
    HTC = {
        [1] = { Success = 55, Keep = 45, Down = 0 },
        [2] = { Success = 43, Keep = 39, Down = 18 },
        [3] = { Success = 30, Keep = 44, Down = 26 },
        [4] = { Success = 16, Keep = 47, Down = 37 },
    },
    LCSL = {
        [1] = { Success = 55, Keep = 45, Down = 0 },
        [2] = { Success = 43, Keep = 39, Down = 18 },
        [3] = { Success = 30, Keep = 44, Down = 26 },
        [4] = { Success = 16, Keep = 47, Down = 37 },
    },
    TSSJ = {
        [1] = { Success = 55, Keep = 45, Down = 0 },
        [2] = { Success = 43, Keep = 39, Down = 18 },
        [3] = { Success = 30, Keep = 44, Down = 26 },
        [4] = { Success = 16, Keep = 47, Down = 37 },
    },
    XJWQ = {
        [1] = { Success = 42, Keep = 58, Down = 0 },
        [2] = { Success = 30, Keep = 41, Down = 29 },
        [3] = { Success = 19, Keep = 43, Down = 38 },
        [4] = { Success = 9, Keep = 44, Down = 47 },
    },
}

WeaponLevelConfig.BaseAttributeBySeries = {
    XJWQ = {
        [1] = { AttackPercent = 0 },
        [2] = { AttackPercent = 2 },
        [3] = { AttackPercent = 5 },
        [4] = { AttackPercent = 8 },
        [5] = { AttackPercent = 10 },
    },
    HWSCJ = {
        [1] = { AttackPercent = 20 },
        [2] = { AttackPercent = 55 },
        [3] = { AttackPercent = 100 },
        [4] = { AttackPercent = 170 },
        [5] = { AttackPercent = 250 },
    },
    HTC = {
        [1] = { AttackPercent = 6 },
        [2] = { AttackPercent = 31 },
        [3] = { AttackPercent = 66 },
        [4] = { AttackPercent = 123 },
        [5] = { AttackPercent = 193 },
    },
    LCSL = {
        [1] = { AttackPercent = 4 },
        [2] = { AttackPercent = 29 },
        [3] = { AttackPercent = 64 },
        [4] = { AttackPercent = 121 },
        [5] = { AttackPercent = 197 },
    },
    TSSJ = {
        [1] = { AttackPercent = 8 },
        [2] = { AttackPercent = 33 },
        [3] = { AttackPercent = 68 },
        [4] = { AttackPercent = 125 },
        [5] = { AttackPercent = 195 },
    },
}


WeaponLevelConfig.ItemIndex = {}
for SeriesKey, SeriesData in pairs(WeaponLevelConfig.Series) do
    for Level, ItemID in ipairs(SeriesData.ItemIDs) do
        WeaponLevelConfig.ItemIndex[ItemID] = {
            SeriesKey = SeriesKey,
            Level = Level,
        }
    end
end

function WeaponLevelConfig.GetItemID(SeriesKey, Level)
    local SeriesData = WeaponLevelConfig.Series[SeriesKey]
    if SeriesData == nil then
        return nil
    end

    return SeriesData.ItemIDs[tonumber(Level)]
end

function WeaponLevelConfig.GetWeaponInfo(ItemID)
    local IndexData = WeaponLevelConfig.ItemIndex[tonumber(ItemID)]
    if IndexData == nil then
        return nil
    end

    return {
        SeriesKey = IndexData.SeriesKey,
        Level = IndexData.Level,
        LevelName = WeaponLevelConfig.LevelNames[IndexData.Level],
        Series = WeaponLevelConfig.Series[IndexData.SeriesKey],
    }
end

function WeaponLevelConfig.GetNextItemID(ItemID)
    local Info = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if Info == nil then
        return nil
    end

    return Info.Series.ItemIDs[Info.Level + 1]
end

function WeaponLevelConfig.GetPrevItemID(ItemID)
    local Info = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if Info == nil then
        return nil
    end

    return Info.Series.ItemIDs[Info.Level - 1]
end

function WeaponLevelConfig.IsMaxLevel(ItemID)
    return WeaponLevelConfig.GetNextItemID(ItemID) == nil
end

function WeaponLevelConfig.GetForgeCost(ItemID)
    local Info = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if Info == nil or WeaponLevelConfig.IsMaxLevel(ItemID) then
        return nil
    end

    return WeaponLevelConfig.ForgeCostByLevel[Info.Level]
end

function WeaponLevelConfig.GetForgeRate(ItemID)
    local Info = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if Info == nil or WeaponLevelConfig.IsMaxLevel(ItemID) then
        return nil
    end

    local SeriesRate = WeaponLevelConfig.ForgeRateBySeries[Info.SeriesKey]
    if SeriesRate == nil then
        return nil
    end

    return SeriesRate[Info.Level]
end

function WeaponLevelConfig.GetBaseAttribute(ItemID)
    local Info = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if Info == nil then
        return nil
    end

    local SeriesAttribute = WeaponLevelConfig.BaseAttributeBySeries[Info.SeriesKey]
    if SeriesAttribute == nil then
        return nil
    end

    return SeriesAttribute[Info.Level]
end

function WeaponLevelConfig.GetTotalAttribute(ItemID)
    local BaseAttribute = WeaponLevelConfig.GetBaseAttribute(ItemID)
    if BaseAttribute == nil then
        return nil
    end

    return {
        AttackPercent = tonumber(BaseAttribute.AttackPercent) or 0,
    }
end

function WeaponLevelConfig.RollForgeResult(ItemID)
    local Rate = WeaponLevelConfig.GetForgeRate(ItemID)
    if Rate == nil then
        return "Keep"
    end

    local TotalRate = (Rate.Success or 0) + (Rate.Keep or 0) + (Rate.Down or 0)
    if TotalRate <= 0 then
        return "Keep"
    end

    local Roll = math.random(1, TotalRate)
    if Roll <= (Rate.Success or 0) then
        return "Success"
    end
    if Roll <= (Rate.Success or 0) + (Rate.Keep or 0) then
        return "Keep"
    end
    return "Down"
end

function WeaponLevelConfig.GetResultItemID(ItemID, ResultType)
    if ResultType == "Success" then
        return WeaponLevelConfig.GetNextItemID(ItemID) or ItemID
    end
    if ResultType == "Down" then
        return WeaponLevelConfig.GetPrevItemID(ItemID) or ItemID
    end
    return ItemID
end

function WeaponLevelConfig.GetAllBaseItemIDs()
    local Result = {}
    local SeriesOrder = { "XJWQ", "HWSCJ", "HTC", "LCSL", "TSSJ" }
    for _, SeriesKey in ipairs(SeriesOrder) do
        local SeriesData = WeaponLevelConfig.Series[SeriesKey]
        if SeriesData ~= nil and SeriesData.ItemIDs[1] ~= nil then
            table.insert(Result, SeriesData.ItemIDs[1])
        end
    end
    return Result
end

return WeaponLevelConfig
