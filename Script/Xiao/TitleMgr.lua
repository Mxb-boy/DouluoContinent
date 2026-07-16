local TitleMgr = {}

--[[
称号条件只在这里负责归类，暂时不执行解锁：
1. Value：读取玩家当前值进行判断，例如战力、累计签到天数。
2. Progress：需要累计并持久化的进度，例如总抽奖次数、总击杀数。
3. Event：事件发生时直接完成，例如首次通关指定副本。
4. Direct：由外部途径直接调用 UnlockTitle，例如抽奖获得称号道具。

Relation = "Any" 表示多个条件满足任意一个即可解锁。
]] --
TitleMgr.RuleType = {
    Value = "Value",
    Progress = "Progress",
    Event = "Event",
    Direct = "Direct"
}

TitleMgr.Rules = {
    [1] = {
        Relation = "Any",
        Conditions = {{Type = "Value", Source = "CombatPower", Target = 20000}}
    },
    [2] = {
        Relation = "Any",
        Conditions = {{Type = "Value", Source = "CombatPower", Target = 200000000}}
    },
    [3] = {
        Relation = "Any",
        Conditions = {{Type = "Value", Source = "CombatPower", Target = 128000000000}}
    },
    [4] = {
        Relation = "Any",
        Conditions = {{Type = "Value", Source = "CombatPower", Target = 180000000000000}}
    },
    [5] = {
        Relation = "Any",
        Conditions = {{Type = "Progress", Source = "LotteryCount", Target = 5}}
    },
    [6] = {
        Relation = "Any",
        Conditions = {{Type = "Progress", Source = "LotteryCount", Target = 10}}
    },
    [7] = {
        Relation = "Any",
        Conditions = {{Type = "Direct", Source = "LotteryTitleItem"}}
    },
    [8] = {
        Relation = "Any",
        Conditions = {{Type = "Event", Source = "DungeonClear", DungeonID = 1}}
    },
    [9] = {
        Relation = "Any",
        Conditions = {{Type = "Event", Source = "DungeonClear", DungeonID = 2}}
    },
    [10] = {
        Relation = "Any",
        Conditions = {{Type = "Event", Source = "DungeonClear", DungeonID = 3}}
    },
    [11] = {
        Relation = "Any",
        Conditions = {{Type = "Event", Source = "DungeonClear", DungeonID = 4}}
    },
    [12] = {
        Relation = "Any",
        Conditions = {{Type = "Event", Source = "DungeonClear", DungeonID = 5}}
    },
    [13] = {
        Relation = "Any",
        Conditions = {{Type = "Direct", Source = "LotteryTitleItem"}}
    },
    [14] = {
        Relation = "Any",
        Conditions = {{Type = "Value", Source = "SignInDays", EventID = 10086, Target = 7}}
    },
    [15] = {
        Relation = "Any",
        Conditions = {{Type = "Progress", Source = "KillMonsterCount", Target = 10000}}
    }
}

function TitleMgr:GetRule(titleID)
    return self.Rules[tonumber(titleID) or 0]
end

function TitleMgr:GetConditions(titleID)
    local rule = self:GetRule(titleID)
    return rule and rule.Conditions or nil
end

-- 战力口径与突破、传送功能保持一致：攻击力 + 最大生命值。
function TitleMgr:GetCombatPower(playerController)
    if playerController == nil or playerController.K2_GetPawn == nil then
        return 0
    end

    local playerPawn = playerController:K2_GetPawn()
    if playerPawn == nil then
        return 0
    end

    local attackPower = tonumber(UGCAttributeSystem.GetGameAttributeValue(playerPawn, "AttackPower")) or 0
    local maxHP = tonumber(UGCPawnAttrSystem.GetHealthMax(playerPawn)) or 0
    return math.max(0, attackPower + maxHP)
end

-- LotteryState 按奖池保存 Round；累加所有奖池即可得到总有效抽奖次数。
function TitleMgr:GetLotteryCount(playerController)
    local playerState = playerController and playerController.PlayerState or nil
    if playerState == nil then
        return 0
    end

    local lotteryState = playerState.GetLotteryState and playerState:GetLotteryState() or playerState.LotteryState
    if type(lotteryState) ~= "table" then
        return 0
    end

    local total = 0
    for _, poolState in pairs(lotteryState) do
        if type(poolState) == "table" then
            total = total + math.max(0, tonumber(poolState.Round) or 0)
        end
    end
    return total
end

-- 官方签到模板的 DayNum 是累计签到天数；EventID 由签到活动配置决定。
function TitleMgr:GetSignInDays(playerController, eventID)
    eventID = tonumber(eventID) or 0
    if playerController == nil or eventID <= 0 then
        return 0
    end

    if SignInEventManager == nil then
        UGCGameSystem.UGCRequire(
            "ExtendResource.SignInEvent.OfficialPackage.Script.SignInEvent.SignInEventManager"
        )
    end
    if SignInEventManager == nil or SignInEventManager.GetEventDayNum == nil then
        return 0
    end

    return math.max(0, tonumber(SignInEventManager:GetEventDayNum(eventID, playerController)) or 0)
end

function TitleMgr:GetKillMonsterCount(playerController)
    local playerState = playerController and playerController.PlayerState or nil
    if playerState == nil then
        return math.max(0, tonumber(playerController and playerController.KillMonsterCount) or 0)
    end

    if playerState.GetKillMonsterCount ~= nil then
        return playerState:GetKillMonsterCount()
    end
    return math.max(0, tonumber(playerState.KillMonsterCount) or 0)
end

-- 统一读取规则中的数据源；尚未接入的数据源暂时返回 nil。
function TitleMgr:GetSourceValue(source, playerController, condition)
    if source == "CombatPower" then
        return self:GetCombatPower(playerController)
    elseif source == "LotteryCount" then
        return self:GetLotteryCount(playerController)
    elseif source == "SignInDays" then
        return self:GetSignInDays(playerController, condition and condition.EventID)
    elseif source == "KillMonsterCount" then
        return self:GetKillMonsterCount(playerController)
    end
    return nil
end

function TitleMgr:GetProgress(titleID, playerController)
    local conditions = self:GetConditions(titleID)
    for _, condition in ipairs(conditions or {}) do
        if condition.Type == self.RuleType.Value or condition.Type == self.RuleType.Progress then
            local current = self:GetSourceValue(condition.Source, playerController, condition)
            local target = tonumber(condition.Target)
            if current ~= nil and target ~= nil then
                return math.max(0, tonumber(current) or 0), math.max(0, target), condition.Source
            end
        end
    end
    return nil, nil, nil
end

-- 判断单个条件。eventContext 用于副本通关、抽奖称号道具等即时事件。
-- 返回值：是否满足、当前值、目标值。
function TitleMgr:IsConditionMet(condition, playerController, eventContext)
    if type(condition) ~= "table" then
        return false, nil, nil
    end

    local conditionType = condition.Type
    if conditionType == self.RuleType.Value or conditionType == self.RuleType.Progress then
        local current = self:GetSourceValue(condition.Source, playerController, condition)
        local target = tonumber(condition.Target) or 0
        if current == nil then
            return false, nil, target
        end
        return current >= target, current, target
    end

    if conditionType == self.RuleType.Event or conditionType == self.RuleType.Direct then
        if type(eventContext) ~= "table" or eventContext.Source ~= condition.Source then
            return false, nil, nil
        end
        if condition.DungeonID ~= nil and tonumber(eventContext.DungeonID) ~= tonumber(condition.DungeonID) then
            return false, nil, nil
        end
        return true, 1, 1
    end

    return false, nil, nil
end

-- 判断称号的条件组合。Relation 默认为 Any；All 表示全部条件都要满足。
function TitleMgr:CanUnlock(titleID, playerController, eventContext)
    local rule = self:GetRule(titleID)
    local conditions = rule and rule.Conditions or nil
    if type(conditions) ~= "table" or #conditions == 0 then
        return false
    end

    if rule.Relation == "All" then
        for _, condition in ipairs(conditions) do
            if not self:IsConditionMet(condition, playerController, eventContext) then
                return false
            end
        end
        return true
    end

    for _, condition in ipairs(conditions) do
        if self:IsConditionMet(condition, playerController, eventContext) then
            return true
        end
    end
    return false
end

-- 服务端统一解锁入口。实际存档和客户端同步继续复用 PlayerController:UnlockTitle。
-- 返回 true 表示本次新解锁成功；已经拥有或条件不足都返回 false。
function TitleMgr:CheckAndUnlock(titleID, playerController, eventContext)
    titleID = tonumber(titleID) or 0
    if self:GetRule(titleID) == nil or playerController == nil then
        return false
    end

    local playerState = playerController.PlayerState
    if playerState == nil then
        return false
    end

    local isUnlocked = false
    if playerState.IsTitleUnlocked ~= nil then
        isUnlocked = playerState:IsTitleUnlocked(titleID)
    else
        local unlockedTitles = playerState.UnlockedTitles or {}
        isUnlocked = unlockedTitles[titleID] == true or unlockedTitles[tostring(titleID)] == true
    end
    if isUnlocked or not self:CanUnlock(titleID, playerController, eventContext) then
        return false
    end

    if playerController.UnlockTitle == nil then
        return false
    end
    playerController:UnlockTitle(titleID)
    return true
end

function TitleMgr:CheckCombatPowerTitles(playerController)
    local unlockedTitleIDs = {}
    for titleID = 1, 4 do
        if self:CheckAndUnlock(titleID, playerController) then
            table.insert(unlockedTitleIDs, titleID)
        end
    end
    return unlockedTitleIDs
end

function TitleMgr:AddKillMonsterProgress(playerController, addValue)
    if playerController == nil then
        return false
    end

    local playerState = playerController.PlayerState
    if playerState == nil or playerState.SetKillMonsterCount == nil then
        return false
    end

    local current = self:GetKillMonsterCount(playerController)
    local target = self.Rules[15].Conditions[1].Target
    if current < target then
        local nextValue = math.min(target, current + math.max(0, tonumber(addValue) or 0))
        if nextValue > current then
            playerState:SetKillMonsterCount(nextValue)
            playerController.KillMonsterCount = nextValue
            UnrealNetwork.CallUnrealRPC(playerController, playerController, "Client_SyncKillMonsterCount", nextValue)
        end
    end

    return self:CheckAndUnlock(15, playerController)
end

function TitleMgr:OnTaskProgress(taskKey, addValue, playerController)
    if taskKey == "KillMonster" then
        return self:AddKillMonsterProgress(playerController, addValue)
    end
    return false
end

function TitleMgr:OnDungeonClear(playerController, dungeonID)
    dungeonID = tonumber(dungeonID) or 0
    if playerController == nil or playerController.PlayerKey == nil or dungeonID < 1 or dungeonID > 5 then
        return false
    end

    local teamID = UGCTeamSystem.GetTeamIDByPlayerKey(playerController.PlayerKey)
    if teamID == nil then
        return false
    end

    local eventContext = {Source = "DungeonClear", DungeonID = dungeonID}
    local titleID = dungeonID + 7
    local hasUnlocked = false
    local teamPlayerControllers = UGCTeamSystem.GetPlayerControllersByTeamID(teamID) or {}
    for _, teamPlayerController in ipairs(teamPlayerControllers) do
        hasUnlocked = self:CheckAndUnlock(titleID, teamPlayerController, eventContext) or hasUnlocked
    end
    return hasUnlocked
end

return TitleMgr
