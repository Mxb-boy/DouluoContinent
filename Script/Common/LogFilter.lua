--- 日志过滤器 — 抑制框架内部高频调试日志
--- 背景:
---   1. BackpackV2 的 CompareByItemEnterTime 排序比较，每次比较 print 物品详情
---      40+ 物品排序产生 580+ 条日志（2ms 内爆发）
---   2. PacketCallbacks.update_ugc_inner_info_rsp 每 ~45 秒同步一次背包
---      每次输出 ~100 行树形结构日志，13 分钟内产生 65+ 次共 ~6500 行
--- 此模块通过包装全局 print 函数，过滤掉这些高频噪音日志
local LogFilter = {}

--- 需要过滤的消息前缀列表（精确匹配，非模式匹配）
local FilterPrefixes = {
    "CompareByItemEnterTime",
    "[PacketCallbacks.update_ugc_inner_info_rsp]",
}

--- 需要触发挥发性树形结构抑制的关键词
--- 命中后进入 SuppressTreeMode，连续的 ├─ │ └─ 开头行全部静默
--- 直到出现非树形行时自动退出
local SuppressTriggers = {
    "inner_info=",
}

local OriginalPrint = print

--- 树形结构抑制状态
local SuppressTreeMode = false

--- 检查字符串是否以树形结构字符开头（├─ │ └─）
--- 使用 byte 检测避免 UTF-8 解码开销
--- ├ = 0xE2 0x94 0x9C, │ = 0xE2 0x94 0x82, └ = 0xE2 0x94 0x94
local function IsTreeLine(s)
    local b1, b2, b3 = string.byte(s, 1, 3)
    if b1 ~= 0xE2 or b2 ~= 0x94 then
        return false
    end
    return b3 == 0x9C or b3 == 0x82 or b3 == 0x94
end

local function ShouldFilter(firstArg)
    if type(firstArg) ~= "string" then
        -- 非字符串参数，退出树形抑制模式
        SuppressTreeMode = false
        return false
    end

    -- 1. 前缀精确匹配过滤
    for i = 1, #FilterPrefixes do
        local prefix = FilterPrefixes[i]
        local startIdx = string.find(firstArg, prefix, 1, true)
        if startIdx == 1 then
            return true
        end
    end

    -- 2. 挥发性树形结构抑制
    if SuppressTreeMode then
        if IsTreeLine(firstArg) then
            return true
        end
        -- 非树形行，自动退出抑制模式
        SuppressTreeMode = false
    end

    -- 3. 检查是否需要进入树形抑制模式
    for i = 1, #SuppressTriggers do
        local trigger = SuppressTriggers[i]
        if string.find(firstArg, trigger, 1, true) then
            SuppressTreeMode = true
            return true
        end
    end

    return false
end

--- 添加过滤前缀（供其他模块扩展）
---@param prefix string 要过滤的消息前缀
function LogFilter.AddFilter(prefix)
    if type(prefix) == "string" and #prefix > 0 then
        FilterPrefixes[#FilterPrefixes + 1] = prefix
    end
end

--- 添加树形抑制触发词（供其他模块扩展）
---@param trigger string 触发词
function LogFilter.AddSuppressTrigger(trigger)
    if type(trigger) == "string" and #trigger > 0 then
        SuppressTriggers[#SuppressTriggers + 1] = trigger
    end
end

--- 包装全局 print，过滤高频框架日志
print = function(...)
    local args = {...}
    if #args > 0 and ShouldFilter(args[1]) then
        return
    end
    OriginalPrint(...)
end

return LogFilter
