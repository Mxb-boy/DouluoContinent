local WeaponLevelConfig = {}

local WU_QI_TABLE_PATHS = {
    "Data/Table/Customized/WuQiConfig",
    "Asset/Data/Table/Customized/WuQiConfig.WuQiConfig",
}

local WQ_LEVEL_TABLE_PATHS = {
    "Data/Table/Customized/WqLevelConfig",
    "Asset/Data/Table/Customized/WqLevelConfig.WqLevelConfig",
}

local LEGACY_KEY_TO_WPID = {
    HWSCJ = 8310000,
    TSSJ = 8310003,
    HTC = 8310002,
    LCSL = 8310004,
    LSSL = 8310004,
    XJWQ = 8310006,
    XSWQ = 8310006,
}

local DEFAULT_LEVEL_ITEM_IDS = {
    [1001] = { -- HWSCJ_B
        [1] = 8310000,
        [2] = 8310019,
        [3] = 8310020,
        [4] = 8310021,
        [5] = 8310022,
        [6] = 8310001,
        [7] = 8310046,
        [8] = 8310073,
        [9] = 8310074,
        [10] = 8310075,
        [11] = 8310076,
        [12] = 8310077,
        [13] = 8310078,
        [14] = 8310079,
        [15] = 8310080,
    },
    [1003] = { -- HTC_B
        [1] = 8310002,
        [2] = 8310015,
        [3] = 8310016,
        [4] = 8310017,
        [5] = 8310018,
        [6] = 8310081,
        [7] = 8310082,
        [8] = 8310083,
        [9] = 8310084,
        [10] = 8310085,
        [11] = 8310086,
        [12] = 8310087,
        [13] = 8310088,
        [14] = 8310089,
        [15] = 8310090,
    },
    [1002] = { -- TSSJ_B
        [1] = 8310003,
        [2] = 8310120,
        [3] = 8310027,
        [4] = 8310028,
        [5] = 8310029,
        [6] = 8310030,
        [7] = 8310101,
        [8] = 8310102,
        [9] = 8310103,
        [10] = 8310104,
        [11] = 8310105,
        [12] = 8310106,
        [13] = 8310107,
        [14] = 8310108,
        [15] = 8310109,
    },
    [1004] = { -- LCSL_B
        [1] = 8310004,
        [2] = 8310023,
        [3] = 8310024,
        [4] = 8310025,
        [5] = 8310026,
        [6] = 8310091,
        [7] = 8310092,
        [8] = 8310093,
        [9] = 8310094,
        [10] = 8310095,
        [11] = 8310096,
        [12] = 8310097,
        [13] = 8310098,
        [14] = 8310099,
        [15] = 8310100,
    },
    [1005] = { -- XJWQ_B
        [1] = 8310006,
        [2] = 8310031,
        [3] = 8310032,
        [4] = 8310033,
        [5] = 8310034,
        [6] = 8310110,
        [7] = 8310111,
        [8] = 8310112,
        [9] = 8310113,
        [10] = 8310114,
        [11] = 8310115,
        [12] = 8310116,
        [13] = 8310117,
        [14] = 8310118,
        [15] = 8310119,
    },
}

local function ToNumber(Value, DefaultValue)
    local NumberValue = tonumber(Value)
    if NumberValue == nil then
        return DefaultValue
    end
    return NumberValue
end

local function FirstNumber(Row, FieldNames, DefaultValue)
    if Row == nil then
        return DefaultValue
    end
    for _, FieldName in ipairs(FieldNames) do
        local NumberValue = tonumber(Row[FieldName])
        if NumberValue ~= nil then
            return NumberValue
        end
    end
    return DefaultValue
end

local function FirstString(Row, FieldNames, DefaultValue)
    if Row == nil then
        return DefaultValue
    end
    for _, FieldName in ipairs(FieldNames) do
        local Value = Row[FieldName]
        if Value ~= nil and tostring(Value) ~= "" then
            return tostring(Value)
        end
    end
    return DefaultValue
end

local function LoadTable(PathList)
    if UGCGameSystem == nil or UGCGameSystem.GetTableData == nil then
        return nil
    end

    for _, Path in ipairs(PathList) do
        local Success, TableData = pcall(UGCGameSystem.GetTableData, Path)
        if Success and TableData ~= nil then
            return TableData
        end

        if UGCGameSystem.GetUGCResourcesFullPath ~= nil then
            local PathSuccess, FullPath = pcall(UGCGameSystem.GetUGCResourcesFullPath, Path)
            if PathSuccess and FullPath ~= nil then
                Success, TableData = pcall(UGCGameSystem.GetTableData, FullPath)
                if Success and TableData ~= nil then
                    return TableData
                end
            end
        end
    end

    return nil
end

local function BuildLevelName(Level)
    return "Lv" .. tostring(tonumber(Level) or 1)
end

local function SortWeapons(Left, Right)
    local LeftID = tonumber(Left.ID) or 0
    local RightID = tonumber(Right.ID) or 0
    if LeftID ~= RightID then
        return LeftID < RightID
    end
    return (tonumber(Left.WPID) or 0) < (tonumber(Right.WPID) or 0)
end

local function NormalizeWeaponRow(Row)
    local WPID = FirstNumber(Row, { "WPID", "ItemID", "ItemId", "WeaponItemID" }, nil)
    local ID = FirstNumber(Row, { "ID", "WeaponID", "WuQiID", "WQID" }, nil)
    if WPID == nil or ID == nil then
        return nil
    end

    return {
        WPID = WPID,
        ItemID = WPID,
        ID = ID,
        SeriesKey = tostring(ID),
        Name = FirstString(Row, { "Name", "WeaponName", "DisplayName" }, tostring(ID)),
        MaxLevel = FirstNumber(Row, { "MaxLevel", "MaxLvl", "LevelMax" }, 1),
        LevelItemIDs = DEFAULT_LEVEL_ITEM_IDS[ID],
        RawRow = Row,
    }
end

local function NormalizeLevelRow(Row)
    local ID = FirstNumber(Row, { "ID", "WeaponID", "WuQiID", "WQID" }, nil)
    local Level = FirstNumber(Row, { "Level", "Lv", "WeaponLevel" }, nil)
    if ID == nil or Level == nil then
        return nil
    end

    return {
        ID = ID,
        SeriesKey = tostring(ID),
        Level = Level,
        Name = FirstString(Row, { "Name", "WeaponName", "DisplayName" }, tostring(ID)),
        AttackPercent = FirstNumber(Row, { "Attack", "AttackPercent", "Atk", "AtkPercent", "Damage", "DamagePercent" }, 0),
        Success = FirstNumber(Row, { "SuccessRate", "Success", "UpRate" }, 0),
        Keep = FirstNumber(Row, { "KeepRate", "Keep" }, 0),
        Down = FirstNumber(Row, { "DownRate", "Down" }, 0),
        Destroy = FirstNumber(Row, { "DestroyRate", "Destroy" }, 0),
        HGRJ = FirstNumber(Row, { "CL_0", "HGRJ", "NeedHGRJ", "HGRJCost", "CostHGRJ", "RongGuRongJing" }, 0),
        QNHH = FirstNumber(Row, { "CL_1", "QNHH", "NeedQNHH", "QNHCost", "CostQNHH", "QianNianXingHe" }, 0),
        RawRow = Row,
    }
end

function WeaponLevelConfig.LoadFromTables()
    local WeaponTable = LoadTable(WU_QI_TABLE_PATHS)
    local LevelTable = LoadTable(WQ_LEVEL_TABLE_PATHS)

    WeaponLevelConfig.WeaponByWPID = {}
    WeaponLevelConfig.WeaponByID = {}
    WeaponLevelConfig.WeaponByItemID = {}
    WeaponLevelConfig.WeaponList = {}
    WeaponLevelConfig.LevelByID = {}
    WeaponLevelConfig.MAX_LEVEL = 1

    if WeaponTable ~= nil then
        for _, Row in pairs(WeaponTable) do
            local Weapon = NormalizeWeaponRow(Row)
            if Weapon ~= nil then
                WeaponLevelConfig.WeaponByWPID[Weapon.WPID] = Weapon
                WeaponLevelConfig.WeaponByID[Weapon.ID] = Weapon
                local LevelItemIDs = Weapon.LevelItemIDs or DEFAULT_LEVEL_ITEM_IDS[Weapon.ID]
                if LevelItemIDs ~= nil then
                    for Level, ItemID in pairs(LevelItemIDs) do
                        WeaponLevelConfig.WeaponByItemID[tonumber(ItemID)] = {
                            Weapon = Weapon,
                            Level = tonumber(Level) or 1,
                            ItemID = tonumber(ItemID),
                        }
                    end
                else
                    WeaponLevelConfig.WeaponByItemID[Weapon.WPID] = {
                        Weapon = Weapon,
                        Level = 1,
                        ItemID = Weapon.WPID,
                    }
                end
                table.insert(WeaponLevelConfig.WeaponList, Weapon)
                if Weapon.MaxLevel > WeaponLevelConfig.MAX_LEVEL then
                    WeaponLevelConfig.MAX_LEVEL = Weapon.MaxLevel
                end
            end
        end
    end

    if LevelTable ~= nil then
        for _, Row in pairs(LevelTable) do
            local LevelConfig = NormalizeLevelRow(Row)
            if LevelConfig ~= nil then
                WeaponLevelConfig.LevelByID[LevelConfig.ID] = WeaponLevelConfig.LevelByID[LevelConfig.ID] or {}
                WeaponLevelConfig.LevelByID[LevelConfig.ID][LevelConfig.Level] = LevelConfig
            end
        end
    end

    table.sort(WeaponLevelConfig.WeaponList, SortWeapons)
    WeaponLevelConfig.bLoadedTables = true
    return #WeaponLevelConfig.WeaponList > 0
end

function WeaponLevelConfig.EnsureLoaded()
    if WeaponLevelConfig.bLoadedTables ~= true then
        WeaponLevelConfig.LoadFromTables()
    end
end

function WeaponLevelConfig.Reload()
    WeaponLevelConfig.bLoadedTables = false
    return WeaponLevelConfig.LoadFromTables()
end

function WeaponLevelConfig.GetAllWeapons()
    WeaponLevelConfig.EnsureLoaded()
    return WeaponLevelConfig.WeaponList or {}
end

function WeaponLevelConfig.GetWeaponByWPID(WPID)
    WeaponLevelConfig.EnsureLoaded()
    return WeaponLevelConfig.WeaponByWPID[tonumber(WPID)]
end

function WeaponLevelConfig.GetWeaponByID(ID)
    WeaponLevelConfig.EnsureLoaded()
    return WeaponLevelConfig.WeaponByID[tonumber(ID)]
end

function WeaponLevelConfig.ResolveWeapon(IDOrWPID)
    WeaponLevelConfig.EnsureLoaded()
    local NumberValue = tonumber(IDOrWPID)
    if NumberValue == nil then
        return nil
    end
    return WeaponLevelConfig.WeaponByWPID[NumberValue] or WeaponLevelConfig.WeaponByID[NumberValue]
end

function WeaponLevelConfig.ResolveItem(ItemID)
    WeaponLevelConfig.EnsureLoaded()
    local NumberValue = tonumber(ItemID)
    if NumberValue == nil then
        return nil
    end
    local ItemInfo = WeaponLevelConfig.WeaponByItemID[NumberValue]
    if ItemInfo ~= nil then
        return ItemInfo
    end
    local Weapon = WeaponLevelConfig.ResolveWeapon(NumberValue)
    if Weapon ~= nil then
        return {
            Weapon = Weapon,
            Level = 1,
            ItemID = Weapon.WPID,
        }
    end
    return nil
end

function WeaponLevelConfig.GetLevelConfig(IDOrWPID, Level)
    local ItemInfo = WeaponLevelConfig.ResolveItem(IDOrWPID)
    local Weapon = ItemInfo ~= nil and ItemInfo.Weapon or WeaponLevelConfig.ResolveWeapon(IDOrWPID)
    local ID = Weapon ~= nil and Weapon.ID or tonumber(IDOrWPID)
    Level = math.max(1, tonumber(Level) or (ItemInfo ~= nil and ItemInfo.Level) or 1)
    local Levels = WeaponLevelConfig.LevelByID[ID]
    if Levels == nil then
        return nil
    end
    return Levels[Level]
end

function WeaponLevelConfig.GetWeaponInfo(WPID, Level)
    local ItemInfo = WeaponLevelConfig.ResolveItem(WPID)
    local Weapon = ItemInfo ~= nil and ItemInfo.Weapon or WeaponLevelConfig.GetWeaponByWPID(WPID)
    if Weapon == nil then
        return nil
    end

    Level = math.max(1, math.min(Weapon.MaxLevel, tonumber(Level) or (ItemInfo ~= nil and ItemInfo.Level) or 1))
    return {
        ItemID = ItemInfo ~= nil and ItemInfo.ItemID or Weapon.WPID,
        WPID = Weapon.WPID,
        ID = Weapon.ID,
        SeriesKey = Weapon.SeriesKey,
        Level = Level,
        LevelName = BuildLevelName(Level),
        Name = Weapon.Name,
        MaxLevel = Weapon.MaxLevel,
        Series = {
            Name = Weapon.Name,
            ItemIDs = { Weapon.WPID },
        },
        RawRow = Weapon.RawRow,
    }
end

function WeaponLevelConfig.BuildDisplayName(WPIDOrWeapon, Level)
    local Weapon = nil
    if type(WPIDOrWeapon) == "table" then
        Weapon = WPIDOrWeapon
    else
        Weapon = WeaponLevelConfig.GetWeaponByWPID(WPIDOrWeapon) or WeaponLevelConfig.GetWeaponByID(WPIDOrWeapon)
    end

    local Name = Weapon ~= nil and Weapon.Name or tostring(WPIDOrWeapon or "")
    return Name .. string.char(239, 188, 136) .. BuildLevelName(Level) .. string.char(239, 188, 137)
end

function WeaponLevelConfig.GetItemID(SeriesKeyOrID, Level)
    local Weapon = WeaponLevelConfig.GetWeaponByID(SeriesKeyOrID)
    if Weapon == nil then
        Weapon = WeaponLevelConfig.GetWeaponByWPID(LEGACY_KEY_TO_WPID[tostring(SeriesKeyOrID or "")])
    end
    if Weapon == nil then
        return nil
    end
    Level = math.max(1, tonumber(Level) or 1)
    local LevelItemIDs = Weapon.LevelItemIDs or DEFAULT_LEVEL_ITEM_IDS[Weapon.ID]
    if LevelItemIDs ~= nil and LevelItemIDs[Level] ~= nil then
        return LevelItemIDs[Level]
    end
    return Weapon.WPID
end

function WeaponLevelConfig.IsMaxLevel(WPID, Level)
    local Info = WeaponLevelConfig.GetWeaponInfo(WPID, Level)
    local Weapon = Info ~= nil and WeaponLevelConfig.GetWeaponByID(Info.ID) or nil
    if Weapon == nil then
        return true
    end
    return (tonumber(Level) or (Info ~= nil and Info.Level) or 1) >= Weapon.MaxLevel
end

function WeaponLevelConfig.GetForgeCost(WPID, Level)
    if WeaponLevelConfig.IsMaxLevel(WPID, Level) then
        return nil
    end
    local LevelConfig = WeaponLevelConfig.GetLevelConfig(WPID, Level)
    if LevelConfig == nil then
        return nil
    end
    return {
        HGRJ = ToNumber(LevelConfig.HGRJ, 0),
        QNHH = ToNumber(LevelConfig.QNHH, 0),
    }
end

function WeaponLevelConfig.GetForgeRate(WPID, Level)
    if WeaponLevelConfig.IsMaxLevel(WPID, Level) then
        return nil
    end
    local LevelConfig = WeaponLevelConfig.GetLevelConfig(WPID, Level)
    if LevelConfig == nil then
        return nil
    end
    return {
        Success = ToNumber(LevelConfig.Success, 0),
        Keep = ToNumber(LevelConfig.Keep, 0),
        Down = ToNumber(LevelConfig.Down, 0),
        Destroy = ToNumber(LevelConfig.Destroy, 0),
    }
end

function WeaponLevelConfig.GetBaseAttribute(WPID, Level)
    local LevelConfig = WeaponLevelConfig.GetLevelConfig(WPID, Level)
    if LevelConfig == nil then
        return nil
    end
    return {
        AttackPercent = ToNumber(LevelConfig.AttackPercent, 0),
    }
end

function WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponID, Level)
    WeaponLevelConfig.EnsureLoaded()
    local Levels = WeaponLevelConfig.LevelByID[tonumber(WeaponID)]
    local LevelConfig = Levels ~= nil and Levels[math.max(1, tonumber(Level) or 1)] or nil
    if LevelConfig == nil then
        return 0
    end
    return ToNumber(LevelConfig.AttackPercent, 0)
end

function WeaponLevelConfig.GetTotalAttribute(WPID, Level)
    return WeaponLevelConfig.GetBaseAttribute(WPID, Level)
end

function WeaponLevelConfig.RollForgeResult(WPID, Level)
    local Rate = WeaponLevelConfig.GetForgeRate(WPID, Level)
    if Rate == nil then
        return "Keep"
    end

    local TotalRate = (Rate.Success or 0) + (Rate.Keep or 0) + (Rate.Down or 0) + (Rate.Destroy or 0)
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
    if Roll <= (Rate.Success or 0) + (Rate.Keep or 0) + (Rate.Down or 0) then
        return "Down"
    end
    return "Destroy"
end

function WeaponLevelConfig.GetResultLevel(WPID, Level, ResultType)
    local ItemInfo = WeaponLevelConfig.ResolveItem(WPID)
    local Weapon = ItemInfo ~= nil and ItemInfo.Weapon or WeaponLevelConfig.ResolveWeapon(WPID)
    if Weapon == nil then
        return tonumber(Level) or 1
    end

    Level = tonumber(Level) or (ItemInfo ~= nil and ItemInfo.Level) or 1
    if ResultType == "Success" then
        local LevelItemIDs = Weapon.LevelItemIDs or DEFAULT_LEVEL_ITEM_IDS[Weapon.ID]
        if LevelItemIDs ~= nil then
            local NextLevel = nil
            for AvailableLevel in pairs(LevelItemIDs) do
                AvailableLevel = tonumber(AvailableLevel)
                if AvailableLevel ~= nil and AvailableLevel > Level and
                    (NextLevel == nil or AvailableLevel < NextLevel) then
                    NextLevel = AvailableLevel
                end
            end
            if NextLevel ~= nil then
                return NextLevel
            end
        end
        return math.min(Weapon.MaxLevel, Level + 1)
    end
    if ResultType == "Down" then
        return 1
    end
    if ResultType == "Destroy" then
        return 1
    end
    return Level
end

function WeaponLevelConfig.GetResultItemID(WPID, ResultType)
    local Info = WeaponLevelConfig.GetWeaponInfo(WPID)
    if Info == nil then
        return tonumber(WPID)
    end
    local ResultLevel = WeaponLevelConfig.GetResultLevel(WPID, Info.Level, ResultType)
    local Weapon = WeaponLevelConfig.GetWeaponByID(Info.ID)
    local LevelItemIDs = Weapon ~= nil and (Weapon.LevelItemIDs or DEFAULT_LEVEL_ITEM_IDS[Weapon.ID]) or nil
    if LevelItemIDs ~= nil and LevelItemIDs[ResultLevel] ~= nil then
        return LevelItemIDs[ResultLevel]
    end
    return tonumber(WPID)
end

function WeaponLevelConfig.GetAllBaseItemIDs()
    local Result = {}
    local AddedItemIDs = {}
    for _, Weapon in ipairs(WeaponLevelConfig.GetAllWeapons()) do
        local LevelItemIDs = Weapon.LevelItemIDs or DEFAULT_LEVEL_ITEM_IDS[Weapon.ID]
        local ItemID = LevelItemIDs ~= nil and LevelItemIDs[1] or Weapon.WPID
        ItemID = tonumber(ItemID)
        if ItemID ~= nil and AddedItemIDs[ItemID] ~= true then
            AddedItemIDs[ItemID] = true
            table.insert(Result, ItemID)
        end
    end
    return Result
end

return WeaponLevelConfig
