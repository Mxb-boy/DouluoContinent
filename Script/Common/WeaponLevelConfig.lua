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

WeaponLevelConfig.ForgeRateByLevel = {
    [1] = { Success = 90, Keep = 10, Down = 0 },
    [2] = { Success = 70, Keep = 25, Down = 5 },
    [3] = { Success = 50, Keep = 25, Down = 15 },
    [4] = { Success = 30, Keep = 50, Down = 20 },
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

    return WeaponLevelConfig.ForgeRateByLevel[Info.Level]
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
    for _, SeriesData in pairs(WeaponLevelConfig.Series) do
        if SeriesData.ItemIDs[1] ~= nil then
            table.insert(Result, SeriesData.ItemIDs[1])
        end
    end
    return Result
end

return WeaponLevelConfig
