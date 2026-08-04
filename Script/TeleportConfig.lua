-- ============================================================
-- 传送点配置表 — 按区域序号排列，坐标已通过 MCP 从编辑器提取
-- 修改 POWER_REQUIREMENTS 即可调整各区域战力门槛
-- 修改 POINT_LOCATIONS 可调整传送坐标（从编辑器 MCP 获取）
-- 修改 CELL_IMAGE_PATHS 可调整各区域 cell 背景图
-- ============================================================

local TeleportConfig = {}

-- 传送点坐标（X, Y, Z），通过 MCP ue_py 从编辑器提取
-- 运行时直接使用，无需查找 BlockingVolume
local POINT_LOCATIONS = {
    { x = 20230, y = 32230,  z = 99  },  -- cj1.BlockingVolume4  第一块区域
    { x = 20260, y = 49350,  z = 109 },  -- cj2.BlockingVolume7  第二块区域
    { x = 20300, y = 63020,  z = 109 },  -- cj2.BlockingVolume11 第三块区域
    { x = 20348, y = 69169,  z = 450 },  -- cj2.SM_decodoor      第四块区域
    { x = 20250, y = 86130,  z = 109 },  -- cj3.BlockingVolume26 第五块区域
    { x = 20348, y = 109349, z = 450 },  -- cj3.SM_decodoor8     第六块区域
    { x = 20280, y = 126440, z = 109 },  -- cj4.BlockingVolume33 第七块区域
    { x = 20378, y = 140659, z = 450 },  -- cj4.SM_decodoor10    第八块区域
    { x = 20290, y = 166680, z = 109 },  -- cj5.BlockingVolume42 第九块区域
    { x = 153441.234375, y = 89125.09375, z = 1462.835205078125 },  -- jianz.NewWorld_Rock_SurfaceStone494 第十块区域
}

-- 各区域 cell 的 Image_194 背景图，与 POINT_LOCATIONS 一一对应
local CELL_IMAGE_PATHS = {
    'Asset/ui/UIxin/bg01.bg01',
    'Asset/ui/UIxin/bg02.bg02',
    'Asset/ui/UIxin/bg03.bg03',
    'Asset/ui/UIxin/bg04.bg04',
    'Asset/ui/UIxin/bg05.bg05',
    'Asset/ui/UIxin/bg06.bg06',
    'Asset/ui/UIxin/bg07.bg07',
    'Asset/ui/UIxin/bg08.bg08',
    'Asset/ui/UIxin/bg09.bg09',
    'Asset/ui/UIxin/bg10.bg10',
}

-- 各区域战力门槛，与 POINT_LOCATIONS 一一对应
-- 第1个 > 0 即可，往后递增
local POWER_REQUIREMENTS = {
       0,    -- 第一块区域
       0,    -- 第二块区域
       0,    -- 第三块区域
       0,   -- 第四块区域
       0,   -- 第五块区域
       0,   -- 第六块区域
       0,   -- 第七块区域
       0,   -- 第八块区域
       0,  -- 第九块区域
       0,  -- 第十块区域
}

-- 各区域推荐战力：value 用于红色提示判断，text 用于 TextBlock_0 显示
-- 推荐战力不参与传送限制判断
local RECOMMENDED_POWER = {
    { value = 0, text = "0" },
    { value = 3500, text = "3500" },
    { value = 22000, text = "2.2万" },
    { value = 37000, text = "3.7万" },
    { value = 3587000, text = "358.7万" },
    { value = 530000000, text = "5.3亿" },
    { value = 8587000000, text = "85.87亿" },
    { value = 256264000000, text = "2562.64亿" },
    { value = 3840000000000, text = "3.84兆" },
    { value = 320000000000000, text = "0.032京" },
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
--- @return { name, power, recommendedPower, recommendedPowerText, imagePath, x, y, z }
function TeleportConfig.GetPoint(index)
    local loc = POINT_LOCATIONS[index]
    local recommended = RECOMMENDED_POWER[index]
    return {
        name = POINT_NAMES[index],
        power = POWER_REQUIREMENTS[index],
        recommendedPower = recommended.value,
        recommendedPowerText = recommended.text,
        imagePath = CELL_IMAGE_PATHS[index],
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
