local Ma_NumShow = {}
local ProjectRootPath = UGCMapInfoLib.GetRootLongPackagePath()

local Units = {
    { Value = 1e20, Text = "垓", ImagePath = ProjectRootPath .. 'Asset/Blueprint/Ma/NEW/GAI.GAI' },
    { Value = 1e16, Text = "京", ImagePath = ProjectRootPath .. 'Asset/Blueprint/Ma/NEW/JIN.JIN' },
    { Value = 1e12, Text = "兆", ImagePath = ProjectRootPath .. 'Asset/Blueprint/Ma/NEW/ZAO.ZAO' },
    { Value = 100000000, Text = "亿", ImagePath = ProjectRootPath .. 'Asset/Blueprint/Ma/NEW/YI.YI' },
    { Value = 10000, Text = "万", ImagePath = ProjectRootPath .. 'Asset/Blueprint/Ma/NEW/WAN.WAN' },
}

local function TruncateNumber(value, DecimalCount)
    local Number = tonumber(value) or 0
    local Scale = 10 ^ (tonumber(DecimalCount) or 0)
    if Number >= 0 then
        return math.floor(Number * Scale) / Scale
    end
    return math.ceil(Number * Scale) / Scale
end

function Ma_NumShow.GetNumShowData(value)
    local number = tonumber(value) or 0
    local absNumber = math.abs(number)

    for _, unit in ipairs(Units) do
        if absNumber >= unit.Value then
            return string.format("%.1f", TruncateNumber(number / unit.Value, 1)), unit.Text, unit.ImagePath
        end
    end

    return tostring(TruncateNumber(number, 0)), nil, nil
end

function Ma_NumShow.Format(value)
    local numberText, unitText = Ma_NumShow.GetNumShowData(value)
    if unitText ~= nil then
        return numberText .. unitText
    end

    return numberText
end

Ma_NumShow.GetNumShow = Ma_NumShow.Format

return Ma_NumShow
