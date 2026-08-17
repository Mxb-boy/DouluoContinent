local WeaponRefineConfig = {}

WeaponRefineConfig.TABLE_PATH = "Asset/Data/Table/Customized/gjConfig.gjConfig"
WeaponRefineConfig.STARDUST_ITEM_ID = 8310134
WeaponRefineConfig.ATTRIBUTE_LOCK_ITEM_ID = 8310135
WeaponRefineConfig.ATTRIBUTE_LOCK_SHOP_ITEM_ID = 1061
WeaponRefineConfig.REFINE_COST = 100
WeaponRefineConfig.MAX_SKIN_COUNT = 12
WeaponRefineConfig.MAX_WEAPON_COUNT = 8
-- 兼容仍用旧名称表示“周围武器数量”的调用。
WeaponRefineConfig.MAX_GUN_COUNT = WeaponRefineConfig.MAX_WEAPON_COUNT
-- 未解锁枪位仍参与整组武器的旋转速度计算，每个枪位固定提供 4。
WeaponRefineConfig.LOCKED_SLOT_ROTATION_SPEED = 4
WeaponRefineConfig.SLOT_UNLOCK_LEVELS = {10, 20, 30, 40, 50, 60, 70, 80}

function WeaponRefineConfig.GetWeaponUnlockLevel(WeaponIndex)
    WeaponIndex = math.floor(tonumber(WeaponIndex) or 0)
    return WeaponRefineConfig.SLOT_UNLOCK_LEVELS[WeaponIndex]
end

function WeaponRefineConfig.IsWeaponUnlocked(WeaponIndex, PlayerLevel)
    local RequiredLevel = WeaponRefineConfig.GetWeaponUnlockLevel(WeaponIndex)
    return RequiredLevel ~= nil and (tonumber(PlayerLevel) or 0) >= RequiredLevel
end

function WeaponRefineConfig.GetUnlockedWeaponCount(PlayerLevel)
    local Count = 0
    for WeaponIndex = 1, WeaponRefineConfig.MAX_WEAPON_COUNT do
        if WeaponRefineConfig.IsWeaponUnlocked(WeaponIndex, PlayerLevel) then
            Count = WeaponIndex
        else
            break
        end
    end
    return Count
end

local FIELD_NAMES = {
    Attack = {"TAK", "TAK_22_E925F48B4B1EE84561F1309EEE8B57EC"},
    AttackRange = {"TAK_Q", "TAK_Q_23_93FCAF52488217850EE04F983D549FAA"},
    AttackSpeedRange = {"AS_Q", "AS_Q_24_741E2C33455CD9D957E6D5A7B8360017"},
    SkinIndex = {"BH", "BH_20_C3D0D0054939B24F311037A0BA2534D2"},
    WeaponIndex = {"num", "num_28_444748B64BAE08E0EFF247B0F703CAA8"}
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
        local SkinIndex = math.floor(tonumber(GetField(Row, "SkinIndex")) or 0)
        local WeaponIndex = math.floor(tonumber(GetField(Row, "WeaponIndex")) or 0)
        if SkinIndex >= 1 and SkinIndex <= WeaponRefineConfig.MAX_SKIN_COUNT and
            WeaponIndex >= 1 and WeaponIndex <= WeaponRefineConfig.MAX_WEAPON_COUNT then
            local AttackMin, AttackMax = ParseRange(GetField(Row, "AttackRange"))
            local SpeedMin, SpeedMax = ParseRange(GetField(Row, "AttackSpeedRange"))
            if AttackMin ~= nil and SpeedMin ~= nil then
                Rows[SkinIndex] = Rows[SkinIndex] or {}
                Rows[SkinIndex][WeaponIndex] = {
                    SkinIndex = SkinIndex,
                    WeaponIndex = WeaponIndex,
                    Cost = WeaponRefineConfig.REFINE_COST,
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

function WeaponRefineConfig.GetRow(SkinIndex, WeaponIndex)
    SkinIndex = math.floor(tonumber(SkinIndex) or 0)
    WeaponIndex = math.floor(tonumber(WeaponIndex) or 0)
    if SkinIndex < 1 or SkinIndex > WeaponRefineConfig.MAX_SKIN_COUNT or
        WeaponIndex < 1 or WeaponIndex > WeaponRefineConfig.MAX_WEAPON_COUNT then
        return nil
    end
    local Rows = WeaponRefineConfig.LoadRows(false)
    return Rows ~= nil and Rows[SkinIndex] ~= nil and Rows[SkinIndex][WeaponIndex] or nil
end

function WeaponRefineConfig.GetCurrentStats(PlayerState, SkinIndex, WeaponIndex)
    local Row = WeaponRefineConfig.GetRow(SkinIndex, WeaponIndex)
    if Row == nil then
        return nil, nil, nil
    end
    local Saved = PlayerState ~= nil and PlayerState.GetWeaponRefineStat ~= nil and
        PlayerState:GetWeaponRefineStat(SkinIndex, WeaponIndex) or nil
    local Attack = Saved ~= nil and tonumber(Saved.Attack) or Row.DefaultAttack
    local AttackSpeed = Saved ~= nil and tonumber(Saved.AttackSpeed) or Row.DefaultAttackSpeed
    return Round2(Attack), Round2(AttackSpeed), Row
end

function WeaponRefineConfig.GetDamagePercents(PlayerState, SkinIndex, UnlockedCount)
    local Result = {}
    UnlockedCount = math.max(0, math.min(WeaponRefineConfig.MAX_WEAPON_COUNT,
        math.floor(tonumber(UnlockedCount) or 0)))
    for WeaponIndex = 1, UnlockedCount do
        local Attack = WeaponRefineConfig.GetCurrentStats(PlayerState, SkinIndex, WeaponIndex)
        if Attack ~= nil then
            Result[WeaponIndex] = Attack
        end
    end
    return Result
end

-- 整组旋转速度 = 8 个枪位速度之和：已解锁读取该枪位攻速，未解锁固定为 4。
function WeaponRefineConfig.GetRotationSpeed(PlayerState, SkinIndex, UnlockedCount)
    UnlockedCount = math.max(0, math.min(WeaponRefineConfig.MAX_WEAPON_COUNT,
        math.floor(tonumber(UnlockedCount) or 0)))
    local TotalSpeed = 0
    for WeaponIndex = 1, WeaponRefineConfig.MAX_WEAPON_COUNT do
        local SlotSpeed = WeaponRefineConfig.LOCKED_SLOT_ROTATION_SPEED
        if WeaponIndex <= UnlockedCount then
            local _, AttackSpeed = WeaponRefineConfig.GetCurrentStats(
                PlayerState, SkinIndex, WeaponIndex)
            SlotSpeed = tonumber(AttackSpeed) or SlotSpeed
        end
        TotalSpeed = TotalSpeed + math.max(0, SlotSpeed)
    end
    return Round2(TotalSpeed)
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
