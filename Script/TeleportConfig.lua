-- ============================================================
-- 传送点配置表 — 按区域序号排列，坐标已通过 MCP 从编辑器提取
-- 修改 POWER_REQUIREMENTS 即可调整各区域战力门槛
-- 修改 POINT_LOCATIONS 可调整传送坐标（从编辑器 MCP 获取）
-- ============================================================

local TeleportConfig = {}

-- 传送点坐标（X, Y, Z），通过 MCP ue_py 从编辑器提取
-- 运行时直接使用，无需查找 BlockingVolume
local POINT_LOCATIONS = {
    { x = 20230, y = 32230,  z = 99  },  -- cj1.BlockingVolume4  第一块区域
    { x = 20260, y = 49350,  z = 109 },  -- cj2.BlockingVolume7  第二块区域
    { x = 20300, y = 63020,  z = 109 },  -- cj2.BlockingVolume11 第三块区域
    { x = 20348, y = 69469,  z = 450 },  -- cj2.SM_decodoor      第四块区域
    { x = 20250, y = 86130,  z = 109 },  -- cj3.BlockingVolume26 第五块区域
    { x = 20348, y = 109649, z = 450 },  -- cj3.SM_decodoor8     第六块区域
    { x = 20280, y = 126440, z = 109 },  -- cj4.BlockingVolume33 第七块区域
    { x = 20378, y = 149959, z = 450 },  -- cj4.SM_decodoor10    第八块区域
    { x = 20290, y = 166680, z = 109 },  -- cj5.BlockingVolume42 第九块区域
    { x = 20388, y = 190189, z = 450 },  -- cj5.SM_decodoor11    第十块区域
}

-- 各区域战力门槛，与 POINT_LOCATIONS 一一对应
-- 第1个 > 0 即可，往后递增
local POWER_REQUIREMENTS = {
       0,          -- 第一块区域
       1234550,    -- 第二块区域
       5000000,    -- 第三块区域
       10000000,   -- 第四块区域
       20000000,   -- 第五块区域
       35000000,   -- 第六块区域
       50000000,   -- 第七块区域
       75000000,   -- 第八块区域
       100000000,  -- 第九块区域
       150000000,  -- 第十块区域
}

-- 区域显示名称
local POINT_NAMES = {
    "第一块区域",
    "第二块区域",
    "第三块区域",
    "第四块区域",
    "第五块区域",
    "第六块区域",
    "第七块区域",
    "第八块区域",
    "第九块区域",
    "第十块区域",
}

--- 获取传送点总数
function TeleportConfig.GetCount()
    return #POINT_LOCATIONS
end

--- 获取第 index（1-based）个传送点的配置
--- @return { name, power, x, y, z }
function TeleportConfig.GetPoint(index)
    local loc = POINT_LOCATIONS[index]
    return {
        name  = POINT_NAMES[index],
        power = POWER_REQUIREMENTS[index],
        x = loc.x,
        y = loc.y,
        z = loc.z,
    }
end

--- 获取第 index（1-based）个传送点的坐标
--- @return { x, y, z } or nil
function TeleportConfig.GetLocation(index)
    return POINT_LOCATIONS[index]
end

return TeleportConfig
