--[[
    回血系统：玩家离开 Battlefield 标签区域后，
    等待 DELAY_SECONDS 秒开始每秒恢复 RegenPercent% 最大生命值。
    满血自动停止，再次进入区域取消回血。

    优化：使用单个命名循环定时器替代递归创建定时器，
    减少定时器对象数量，方便统一清理。
]]
local RegenSystem = {
    -- 离开触发器后等待时间（秒）
    DELAY_SECONDS = 3,
    -- 回血间隔（秒）
    REGEN_INTERVAL = 1,
}

-- 每个玩家的 Timer Token，用于取消/覆盖旧 Timer
RegenSystem.__Tokens = {}  -- [playerPawn] = { delay = n, regen = n }

-- API: 玩家进入战场区域（取消回血）
function RegenSystem.OnEnterBattlefield(playerPawn)
    RegenSystem:_cancel(playerPawn)
end

-- API: 玩家离开战场区域（启动倒计时）
function RegenSystem.OnExitBattlefield(playerPawn)
    RegenSystem:_cancel(playerPawn)
    RegenSystem:_startDelay(playerPawn)
end

-- API: 玩家离场/死亡时清理
function RegenSystem.Cleanup(playerPawn)
    RegenSystem:_cancel(playerPawn)
end

-- ────── 内部实现 ──────

function RegenSystem:_getTimerName(playerPawn)
    return "Regen_" .. tostring(playerPawn)
end

function RegenSystem:_startDelay(playerPawn)
    local tokens = RegenSystem:_getTokens(playerPawn)
    tokens.delay = (tokens.delay or 0) + 1
    local token = tokens.delay

    local pawn = playerPawn
    UGCTimerUtility.CreateLuaTimer(RegenSystem.DELAY_SECONDS, function()
        if pawn == nil or not UE.IsValid(pawn) then return end
        local t = RegenSystem.__Tokens[pawn]
        if t == nil or t.delay ~= token then return end  -- 已取消
        RegenSystem:_startRegen(pawn)
    end, false)
end

function RegenSystem:_startRegen(playerPawn)
    local playerState = playerPawn.PlayerState
    if playerState == nil then return end

    local regenPercent = playerState.GetRegenPercent and playerState:GetRegenPercent()
    if regenPercent == nil or regenPercent <= 0 then return end

    local tokens = RegenSystem:_getTokens(playerPawn)
    tokens.regen = (tokens.regen or 0) + 1
    local token = tokens.regen

    -- 使用单个命名循环定时器替代递归创建
    local pawn = playerPawn
    local timerName = RegenSystem:_getTimerName(pawn)
    UGCTimerUtility.RemoveLuaTimerByName(timerName)

    UGCTimerUtility.CreateLuaTimer(RegenSystem.REGEN_INTERVAL, function()
        if pawn == nil or not UE.IsValid(pawn) then
            UGCTimerUtility.RemoveLuaTimerByName(timerName)
            return
        end
        local t = RegenSystem.__Tokens[pawn]
        if t == nil or t.regen ~= token then  -- 已取消
            UGCTimerUtility.RemoveLuaTimerByName(timerName)
            return
        end

        local currentHP = UGCPawnAttrSystem.GetHealth(pawn)
        local maxHP = UGCPawnAttrSystem.GetHealthMax(pawn)

        if currentHP >= maxHP then
            RegenSystem:_cancel(pawn)
            UGCTimerUtility.RemoveLuaTimerByName(timerName)
            return
        end

        local heal = maxHP * (regenPercent / 100)
        local newHP = math.min(currentHP + heal, maxHP)
        UGCPawnAttrSystem.SetHealth(pawn, newHP)
    end, true, timerName)
end

function RegenSystem:_cancel(playerPawn)
    local t = RegenSystem.__Tokens[playerPawn]
    if t ~= nil then
        -- Token 自增使旧 Timer 回调失效
        t.delay = (t.delay or 0) + 1
        t.regen = (t.regen or 0) + 1
        RegenSystem.__Tokens[playerPawn] = nil
    end
    -- 主动移除命名定时器
    UGCTimerUtility.RemoveLuaTimerByName(RegenSystem:_getTimerName(playerPawn))
end

function RegenSystem:_getTokens(playerPawn)
    if RegenSystem.__Tokens[playerPawn] == nil then
        RegenSystem.__Tokens[playerPawn] = { delay = 0, regen = 0 }
    end
    return RegenSystem.__Tokens[playerPawn]
end

return RegenSystem
