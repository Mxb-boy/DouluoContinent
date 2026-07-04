local Ma_NumShow = {}

local Units = {
    { Value = 1000000000000, Text = "兆" },
    { Value = 100000000, Text = "亿" },
    { Value = 10000, Text = "万" },
}

function Ma_NumShow.Format(value)
    local number = tonumber(value) or 0
    local absNumber = math.abs(number)

    for _, unit in ipairs(Units) do
        if absNumber >= unit.Value then
            return string.format("%.1f%s", number / unit.Value, unit.Text)
        end
    end

    return tostring(number)
end

Ma_NumShow.GetNumShow = Ma_NumShow.Format

return Ma_NumShow
