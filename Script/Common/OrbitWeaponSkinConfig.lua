local OrbitWeaponSkinConfig = {}

OrbitWeaponSkinConfig.TABLE_PATH = "Asset/Data/Table/Customized/XzwqConfig.XzwqConfig"
OrbitWeaponSkinConfig.ROW_NAMES = {
    "NewRow", "NewRow_0", "NewRow_1", "NewRow_2", "NewRow_3", "NewRow_4",
    "NewRow_5", "NewRow_6", "NewRow_7", "NewRow_8", "NewRow_9", "NewRow_10"
}

local FIELD_NAMES = {
    LT = {"LT", "LT_57_C4A07EC8493C3BBE5B13DE8A07B71B64"},
    SJ = {"SJ", "SJ_60_BC78DCF84A74D006EC12A5A4235142BB"}
}

local function SafeGetField(Row, FieldName)
    if Row == nil then
        return nil
    end
    local Success, Value = pcall(function()
        return Row[FieldName]
    end)
    return Success and Value or nil
end

local function GetField(Row, FieldName)
    for _, CandidateName in ipairs(FIELD_NAMES[FieldName] or {FieldName}) do
        local Value = SafeGetField(Row, CandidateName)
        if Value ~= nil then
            return Value
        end
    end
    return nil
end

local function GetAssetPath(Value)
    local Text = tostring(Value or "")
    local AssetPath = string.match(Text, "(/Game/[%w_/%._%-]+)")
        or string.match(Text, "(Asset/[%w_/%._%-]+)")
    if AssetPath ~= nil and string.sub(AssetPath, 1, 6) == "Asset/" then
        return UGCGameSystem.GetUGCResourcesFullPath(AssetPath)
    end
    return AssetPath
end

function OrbitWeaponSkinConfig.GetRow(SkinIndex)
    SkinIndex = math.floor(tonumber(SkinIndex) or 0)
    local RowName = OrbitWeaponSkinConfig.ROW_NAMES[SkinIndex]
    if RowName == nil then
        return nil
    end
    local FullPath = UGCGameSystem.GetUGCResourcesFullPath(OrbitWeaponSkinConfig.TABLE_PATH)
    local Success, ConfigTable = pcall(UGCGameSystem.GetTableData, FullPath)
    return Success and ConfigTable ~= nil and ConfigTable[RowName] or nil
end

function OrbitWeaponSkinConfig.GetPaths(SkinIndex)
    local Row = OrbitWeaponSkinConfig.GetRow(SkinIndex)
    if Row == nil then
        return nil, nil
    end
    local WeaponClassPath = GetAssetPath(GetField(Row, "LT"))
    if WeaponClassPath ~= nil and string.sub(WeaponClassPath, -2) ~= "_C" then
        local PackagePath, ObjectName = string.match(WeaponClassPath, "^(.*)%.([^%.]+)$")
        if PackagePath ~= nil and ObjectName ~= nil then
            WeaponClassPath = PackagePath .. "." .. ObjectName .. "_C"
        end
    end
    return WeaponClassPath, GetAssetPath(GetField(Row, "SJ"))
end

return OrbitWeaponSkinConfig
