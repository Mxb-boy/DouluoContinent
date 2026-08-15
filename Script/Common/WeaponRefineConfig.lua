local WeaponRefineConfig = {}

WeaponRefineConfig.TABLE_PATH = "Asset/Data/Table/Customized/gjConfig.gjConfig"
WeaponRefineConfig.STARDUST_ITEM_ID = 8310134
WeaponRefineConfig.MAX_GUN_COUNT = 8

local FIELD_NAMES = {
    Attack = {"TAK", "TAK_22_E925F48B4B1EE84561F1309EEE8B57EC"},
    AttackRange = {"TAK_Q", "TAK_Q_23_93FCAF52488217850EE04F983D549FAA"},
    AttackSpeedRange = {"AS_Q", "AS_Q_24_741E2C33455CD9D957E6D5A7B8360017"},
    GunIndex = {"BH", "BH_20_C3D0D0054939B24F311037A0BA2534D2"},
    Tier = {"num", "num_28_444748B64BAE08E0EFF247B0F703CAA8"}
}

local function SafeGet(Row, Name)
    local Success, Value = pcall(function()
        return Row[Name]
    end)
    return Success and Value or nil
end

local function GetField(Row, FieldName)
    for _, Name in ipairs(FIELD_NAMES[FieldName] or {FieldName}) do
        local Value = SafeGet(Row, Name)
        if Value ~= nil then
            return Value
        end
    end
    return nil
end

local function ParseRange(Value)
    local MinText, MaxText = string.match(tostring(Value or ""),
        "^%s*([%d%.]+)%s*%-%s*([%d%.]+)%s*$")
    local MinValue = tonumber(MinText)
    local MaxValue = tonumber(MaxText)
    if MinValue == nil or MaxValue == nil then
        return nil, nil
    end
    if MinValue > MaxValue then
        MinValue, MaxValue = MaxValue, MinValue
    end
    return MinValue, MaxValue
end

local function Round2(Value)
    return math.floor((tonumber(Value) or 0) * 100 + 0.5) / 100
end

function WeaponRefineConfig.LoadRows(bForceReload)
    if WeaponRefineConfig.Rows ~= nil and bForceReload ~= true then
        return WeaponRefineConfig.Rows
    end

    local FullPath = UGCGameSystem.GetUGCResourcesFullPath(WeaponRefineConfig.TABLE_PATH)
    local Success, DataTable = pcall(UGCGameSystem.GetTableData, FullPath)
    if not Success or DataTable == nil then
        ugcprint("[WeaponRefine] gjConfig load failed: " .. tostring(FullPath))
        return nil
    end

    local Rows = {}
    for _, Row in pairs(DataTable) do
        local GunIndex = math.floor(tonumber(GetField(Row, "GunIndex")) or 0)
        local Tier = math.floor(tonumber(GetField(Row, "Tier")) or 0)
        if GunIndex >= 1 and GunIndex <= WeaponRefineConfig.MAX_GUN_COUNT and
            Tier >= 1 and Tier <= WeaponRefineConfig.MAX_GUN_COUNT then
            local AttackMin, AttackMax = ParseRange(GetField(Row, "AttackRange"))
            local SpeedMin, SpeedMax = ParseRange(GetField(Row, "AttackSpeedRange"))
            if AttackMin ~= nil and SpeedMin ~= nil then
                Rows[GunIndex] = Rows[GunIndex] or {}
                Rows[GunIndex][Tier] = {
                    GunIndex = GunIndex,
                    Tier = Tier,
                    Cost = Tier,
                    DefaultAttack = tonumber(GetField(Row, "Attack")) or
                        (AttackMin + AttackMax) * 0.5,
                    DefaultAttackSpeed = (SpeedMin + SpeedMax) * 0.5,
                    AttackMin = AttackMin,
                    AttackMax = AttackMax,
                    AttackSpeedMin = SpeedMin,
                    AttackSpeedMax = SpeedMax
                }
            end
        end
    end
    WeaponRefineConfig.Rows = Rows
    return Rows
end

function WeaponRefineConfig.GetRow(GunIndex, UnlockedCount)
    GunIndex = math.max(1, math.min(WeaponRefineConfig.MAX_GUN_COUNT,
        math.floor(tonumber(GunIndex) or 1)))
    UnlockedCount = math.max(1, math.min(WeaponRefineConfig.MAX_GUN_COUNT,
        math.floor(tonumber(UnlockedCount) or 1)))
    local Rows = WeaponRefineConfig.LoadRows(false)
    return Rows ~= nil and Rows[GunIndex] ~= nil and Rows[GunIndex][UnlockedCount] or nil
end

function WeaponRefineConfig.GetCurrentStats(PlayerState, GunIndex, UnlockedCount)
    local Row = WeaponRefineConfig.GetRow(GunIndex, UnlockedCount)
    if Row == nil then
        return nil, nil, nil
    end
    local Saved = PlayerState ~= nil and PlayerState.GetWeaponRefineStat ~= nil and
        PlayerState:GetWeaponRefineStat(GunIndex) or nil
    local Attack = Saved ~= nil and tonumber(Saved.Attack) or Row.DefaultAttack
    local AttackSpeed = Saved ~= nil and tonumber(Saved.AttackSpeed) or Row.DefaultAttackSpeed
    return Round2(Attack), Round2(AttackSpeed), Row
end

function WeaponRefineConfig.Roll(Row)
    if Row == nil then
        return nil, nil
    end
    local Attack = Row.AttackMin + (Row.AttackMax - Row.AttackMin) * math.random()
    local AttackSpeed = Row.AttackSpeedMin +
        (Row.AttackSpeedMax - Row.AttackSpeedMin) * math.random()
    return Round2(Attack), Round2(AttackSpeed)
end

function WeaponRefineConfig.FormatNumber(Value)
    local Text = string.format("%.2f", tonumber(Value) or 0)
    Text = string.gsub(Text, "0+$", "")
    return string.gsub(Text, "%.$", "")
end

return WeaponRefineConfig
