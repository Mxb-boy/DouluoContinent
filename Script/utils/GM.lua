local GM = {}
local PlayerInitialData = UGCGameSystem.UGCRequire("Script.Common.PlayerInitialData")
local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
local TitleConfig = UGCGameSystem.UGCRequire("Script.Common.TitleConfig")
local GMResetLog = UGCGameSystem.UGCRequire("Script.Common.GMResetLog")

local PLAYER_SKILL_1_PATH = "Asset/Blueprint/Prefabs/Skills/Lin/PlayerSkill/PlayerSkill_1.PlayerSkill_1_C"
local RESET_RETRY_DELAY = 0.5
local RESET_CLEAR_MAX_ATTEMPTS = 128
local RESET_CLEAR_MAX_STALLED_ATTEMPTS = 4
local RESET_ARCHIVE_MAX_ATTEMPTS = 3
local RESET_TASK_MAX_ATTEMPTS = 3
local RESET_GRANT_MAX_ATTEMPTS = 4
local ResetTransactions = {}
local FailReset

local function GetTitleOptionText()
    local Options = {}
    for TitleID = 1, TitleConfig.MaxTitleID do
        local Config = TitleConfig.GetTitle(TitleID)
        if Config ~= nil then
            table.insert(Options, tostring(TitleID) .. ". " .. tostring(Config.Name))
        end
    end
    return "称号ID对照：\n" .. table.concat(Options, "\n")
end

function GM:Register(DebugUI)
    local UGCGMUI = require("client.ingame.ugc.ugc_gmui")
    local CurFuncList = {}

    CurFuncList["调试"] = {
        ["玩家数据重置"] = {
            {UGCGMUI.ItemTypeEnum.Button, { {"重置当前玩家数据"}, {"清空当前玩家养成和背包，并重新发放初始物资"} },
             "S_ResetCurrentPlayerData"}
        },
        ["一键完成任务"] = {
            {UGCGMUI.ItemTypeEnum.Button, { {"完成每日和每周任务"}, {"完成当前玩家全部每日、每周任务，不自动领取奖励"} },
             "S_CompleteDailyWeeklyTasks"}
        },
        ["自定义获取称号"] = {
            {UGCGMUI.ItemTypeEnum.TextInput, { {"获取并解锁称号", "输入称号ID（1-15）"}, {GetTitleOptionText()} },
             "S_GrantCustomTitle"}
        }
    }
    CurFuncList["调试"]["运行日志"] = {
        {UGCGMUI.ItemTypeEnum.Button, { {"打开运行日志"}, {"查看当前客户端和服务端Lua日志"} },
         "C_OpenRuntimeLog"},
        {UGCGMUI.ItemTypeEnum.TextInput,
         { {"搜索运行日志", "输入关键词后过滤当前日志"}, {"输入关键词后打开过滤结果"} },
         "C_SearchRuntimeLog"},
        {UGCGMUI.ItemTypeEnum.Button, { {"清空运行日志"}, {"清空当前客户端日志缓存"} },
         "C_ClearRuntimeLog"}
    }
    return CurFuncList
end

function GM:C_OpenRuntimeLog(Param)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if PlayerController ~= nil and PlayerController.OpenRuntimeLogConsole ~= nil then
        PlayerController:OpenRuntimeLogConsole("")
    end
end

function GM:C_SearchRuntimeLog(Param)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if PlayerController ~= nil and PlayerController.OpenRuntimeLogConsole ~= nil then
        PlayerController:OpenRuntimeLogConsole(tostring(Param or ""))
    end
end

function GM:C_ClearRuntimeLog(Param)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if PlayerController ~= nil and PlayerController.ClearRuntimeLogs ~= nil then
        PlayerController:ClearRuntimeLogs()
    end
end

GM.C_OpenGMResetLog = GM.C_OpenRuntimeLog
GM.C_SearchGMResetLog = GM.C_SearchRuntimeLog
GM.C_ClearGMResetLog = GM.C_ClearRuntimeLog

local function LogReset(PlayerController, Level, Stage, Message)
    GMResetLog.Emit(PlayerController, Level, Stage, Message)
end

local function GetPlayerPawn(PlayerController)
    if PlayerController == nil then
        return nil
    end
    if UGCGameSystem.GetPlayerPawnByPlayerController ~= nil then
        local Pawn = UGCGameSystem.GetPlayerPawnByPlayerController(PlayerController)
        if Pawn ~= nil then
            return Pawn
        end
    end
    return PlayerController.Pawn or
               (PlayerController.K2_GetPawn ~= nil and PlayerController:K2_GetPawn() or nil)
end

local function RemoveLevelSkill(PlayerPawn)
    if PlayerPawn == nil or UGCPersistEffectSystem == nil or
        UGCPersistEffectSystem.GetSkillsByClass == nil or UGCPersistEffectSystem.RemoveSkillInstance == nil then
        return
    end

    local SkillClassPath = UGCGameSystem.GetUGCResourcesFullPath(PLAYER_SKILL_1_PATH)
    local Success, Skills = pcall(UGCPersistEffectSystem.GetSkillsByClass, PlayerPawn, SkillClassPath)
    if not Success or Skills == nil then
        return
    end

    local SkillInstances = {}
    local CountSucceeded, SkillCount = pcall(function()
        return #Skills
    end)
    if CountSucceeded and tonumber(SkillCount) ~= nil then
        for Index = 1, tonumber(SkillCount) do
            local ReadSucceeded, SkillInstance = pcall(function()
                return Skills[Index]
            end)
            if ReadSucceeded and SkillInstance ~= nil then
                table.insert(SkillInstances, SkillInstance)
            end
        end
    elseif Skills ~= nil then
        table.insert(SkillInstances, Skills)
    end

    -- Release the engine array wrapper before removals mutate the source array.
    Skills = nil
    for _, SkillInstance in ipairs(SkillInstances) do
        pcall(UGCPersistEffectSystem.RemoveSkillInstance, PlayerPawn, SkillInstance)
    end
end

local function ScheduleResetStep(PlayerController, PlayerKey, Stage, Callback)
    UGCTimerUtility.CreateLuaTimer(RESET_RETRY_DELAY, function()
        local Success, Error = pcall(Callback)
        if not Success then
            LogReset(PlayerController, "ERROR", Stage, "exception=" .. tostring(Error))
            FailReset(PlayerController, PlayerKey, "stage_exception_" .. tostring(Stage))
        end
    end, false)
end

local function GetActiveResetContext(PlayerController, PlayerKey)
    local Transaction = ResetTransactions[PlayerKey]
    if Transaction == nil or Transaction.PlayerController ~= PlayerController or
        PlayerController == nil or (UE.IsValid ~= nil and not UE.IsValid(PlayerController)) then
        return nil, nil, nil
    end
    local PlayerPawn = GetPlayerPawn(PlayerController)
    local PlayerState = PlayerController.PlayerState
    if PlayerPawn == nil or PlayerState == nil then
        return Transaction, nil, nil
    end
    return Transaction, PlayerPawn, PlayerState
end

FailReset = function(PlayerController, PlayerKey, Reason)
    local Transaction, PlayerPawn = GetActiveResetContext(PlayerController, PlayerKey)
    local BackpackWasModified = Transaction ~= nil and
                                    (Transaction.BackpackCleared == true or
                                        (tonumber(Transaction.RemoveRequests) or 0) > 0)
    if BackpackWasModified and PlayerPawn ~= nil then
        local GrantCallSucceeded, Granted = pcall(PlayerInitialData.Grant, PlayerPawn)
        local Verified = false
        if GrantCallSucceeded and Granted then
            local VerifyCallSucceeded, VerifyResult = pcall(PlayerInitialData.VerifyGrant, PlayerPawn)
            Verified = VerifyCallSucceeded and VerifyResult == true
        end
        LogReset(PlayerController, Verified and "WARN" or "ERROR", "compensation",
            "grant=" .. tostring(GrantCallSucceeded and Granted) .. " verified=" .. tostring(Verified))
    end
    ResetTransactions[PlayerKey] = nil
    if PlayerController ~= nil and (UE.IsValid == nil or UE.IsValid(PlayerController)) then
        PlayerController.bGMResetInProgress = false
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
            "玩家数据重置失败，请查看日志后重试")
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_PlayerDataResetFailed")
    end
    local RemovedCount = Transaction ~= nil and Transaction.RemoveRequests or 0
    LogReset(PlayerController, "ERROR", "failed",
        "reason=" .. tostring(Reason) .. " removedItemInstances=" .. tostring(RemovedCount))
end

local function FinalizeServerState(PlayerController, PlayerPawn, PlayerState)
    PlayerController.ProbabilityBonusPermanent = nil
    PlayerController.ProbabilityBonusPermanentValue = nil
    PlayerController.ProbabilityBonusRemainingSeconds = 0
    PlayerController.ProbabilityBonusTimedValue = nil
    if UGCTimerUtility.RemoveLuaTimerByName ~= nil then
        UGCTimerUtility.RemoveLuaTimerByName("ProbabilityBonus_" .. tostring(PlayerController.PlayerKey))
    end

    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
        PlayerState:SetYXWD_InvincibleBuffActive(false)
    else
        PlayerState.YXWD_InvincibleBuffActive = false
    end
    PlayerState.YXWD_InvincibleBuffToken = (tonumber(PlayerState.YXWD_InvincibleBuffToken) or 0) + 1

    PlayerPawn.EquippedTitleID = 0
    PlayerController.EquippedTitleID = 0
    PlayerController.UnlockedTitles = {}
    local TitleActor = PlayerPawn.PlayerTitleActor
    if TitleActor ~= nil and UE.IsValid(TitleActor) and TitleActor.SetTitle ~= nil then
        TitleActor:SetTitle(0)
    end
    RemoveLevelSkill(PlayerPawn)

    local BaseAttack = PlayerState.GetBaseAttack ~= nil and tonumber(PlayerState:GetBaseAttack()) or 40
    local BaseMaxHp = PlayerState.GetBaseMaxHp ~= nil and tonumber(PlayerState:GetBaseMaxHp()) or 100
    UGCAttributeSystem.SetGameAttributeValue(PlayerPawn, "AttackPower", BaseAttack)
    UGCPawnAttrSystem.SetHealthMax(PlayerPawn, BaseMaxHp)
    UGCPawnAttrSystem.SetHealth(PlayerPawn, BaseMaxHp)
end

--- 服务端 GM：只重置点击按钮的当前玩家。
function GM:S_ResetCurrentPlayerData(Param, PlayerController)
    if not UGCGameSystem.IsServer() then
        return
    end

    LogReset(PlayerController, "INFO", "request",
        "gm reset request received param=" .. tostring(Param))

    local PlayerPawn = GetPlayerPawn(PlayerController)
    local PlayerState = PlayerController and PlayerController.PlayerState or nil
    local PlayerKey = PlayerController ~= nil and PlayerController.PlayerKey ~= nil and
                          tostring(PlayerController.PlayerKey) or nil
    if PlayerController == nil or PlayerPawn == nil or PlayerState == nil or PlayerKey == nil then
        LogReset(PlayerController, "ERROR", "validation", "player_controller_pawn_or_state_nil")
        return
    end
    if PlayerState.bArchiveLoaded ~= true or PlayerState.ResetProgressionToDefaults == nil then
        LogReset(PlayerController, "ERROR", "validation", "archive_not_ready")
        return
    end
    if ResetTransactions[PlayerKey] ~= nil or PlayerController.bGMResetInProgress == true then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
            "玩家数据正在重置，请勿重复点击")
        LogReset(PlayerController, "WARN", "validation", "reset_already_in_progress")
        return
    end

    local Transaction = {
        PlayerController = PlayerController,
        RemoveRequests = 0,
        BackpackCleared = false,
        LastBackpackRemaining = nil,
        ClearStalledAttempts = 0
    }
    ResetTransactions[PlayerKey] = Transaction
    PlayerController.bGMResetInProgress = true
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_PlayerDataResetStarted")
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
        "正在重置玩家数据，请稍候")
    LogReset(PlayerController, "INFO", "start",
        "reset transaction accepted previousLevel=" .. tostring(PlayerState.PlayerLevel) ..
            " previousExp=" .. tostring(PlayerState.PlayerExp) ..
            " archiveLoaded=" .. tostring(PlayerState.bArchiveLoaded))

    local ClearBackpackStep
    local ResetArchiveStep
    local ResetTasksStep
    local GrantItemsStep

    ClearBackpackStep = function(Attempt, VerifyOnly)
        LogReset(PlayerController, "INFO", "backpack_clear",
            "attempt=" .. tostring(Attempt) .. " verifyOnly=" .. tostring(VerifyOnly == true))
        local ActiveTransaction, ActivePawn = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil or ActivePawn == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_clear")
            return
        end

        local Cleared, RemovedCount, RemainingCount, Detail =
            PlayerInitialData.ClearBackpack(ActivePawn, VerifyOnly)
        ActiveTransaction.RemoveRequests = ActiveTransaction.RemoveRequests + (tonumber(RemovedCount) or 0)
        if ActiveTransaction.LastBackpackRemaining ~= nil and RemainingCount >= 0 and
            RemainingCount >= ActiveTransaction.LastBackpackRemaining then
            ActiveTransaction.ClearStalledAttempts = ActiveTransaction.ClearStalledAttempts + 1
        else
            ActiveTransaction.ClearStalledAttempts = 0
        end
        ActiveTransaction.LastBackpackRemaining = RemainingCount
        LogReset(PlayerController, Cleared and "INFO" or "WARN", "backpack_clear",
            "attempt=" .. tostring(Attempt) .. " cleared=" .. tostring(Cleared) ..
                " removeRequests=" .. tostring(RemovedCount) .. " remaining=" ..
                tostring(RemainingCount) .. " stalled=" ..
                tostring(ActiveTransaction.ClearStalledAttempts) .. " detail=" .. tostring(Detail))
        if Cleared then
            ActiveTransaction.BackpackCleared = true
            ResetArchiveStep(1)
            return
        end
        if ActiveTransaction.ClearStalledAttempts >= RESET_CLEAR_MAX_STALLED_ATTEMPTS then
            FailReset(PlayerController, PlayerKey,
                "backpack_stalled_" .. tostring(RemainingCount) .. "_" .. tostring(Detail))
            return
        end
        if VerifyOnly == true then
            FailReset(PlayerController, PlayerKey,
                "backpack_attempt_limit_remaining_" .. tostring(RemainingCount))
            return
        end
        if Attempt >= RESET_CLEAR_MAX_ATTEMPTS then
            ScheduleResetStep(PlayerController, PlayerKey, "backpack_final_verify", function()
                ClearBackpackStep(Attempt + 1, true)
            end)
            return
        end
        ScheduleResetStep(PlayerController, PlayerKey, "backpack_retry", function()
            ClearBackpackStep(Attempt + 1)
        end)
    end

    ResetArchiveStep = function(Attempt)
        LogReset(PlayerController, "INFO", "archive_reset", "attempt=" .. tostring(Attempt))
        local ActiveTransaction, _, ActiveState = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil or ActiveState == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_archive")
            return
        end

        local Saved, Reason = ActiveState:ResetProgressionToDefaults()
        LogReset(PlayerController, Saved and "INFO" or "WARN", "archive_reset",
            "attempt=" .. tostring(Attempt) .. " verified=" .. tostring(Saved) ..
                " reason=" .. tostring(Reason))
        if Saved then
            ResetTasksStep(1)
            return
        end
        if Attempt >= RESET_ARCHIVE_MAX_ATTEMPTS then
            FailReset(PlayerController, PlayerKey, "archive_" .. tostring(Reason))
            return
        end
        ScheduleResetStep(PlayerController, PlayerKey, "archive_retry", function()
            ResetArchiveStep(Attempt + 1)
        end)
    end

    ResetTasksStep = function(Attempt)
        LogReset(PlayerController, "INFO", "tasks_reset", "attempt=" .. tostring(Attempt))
        local ActiveTransaction = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_tasks")
            return
        end

        local Requested, RequestReason = TaskMgr:ResetDailyWeeklyTasksOnServer(PlayerController)
        LogReset(PlayerController, Requested and "INFO" or "WARN", "tasks_reset",
            "attempt=" .. tostring(Attempt) .. " requested=" .. tostring(Requested) ..
                " reason=" .. tostring(RequestReason))
        if not Requested then
            if Attempt >= RESET_TASK_MAX_ATTEMPTS then
                FailReset(PlayerController, PlayerKey, "tasks_" .. tostring(RequestReason))
            else
                ScheduleResetStep(PlayerController, PlayerKey, "tasks_retry", function()
                    ResetTasksStep(Attempt + 1)
                end)
            end
            return
        end

        ScheduleResetStep(PlayerController, PlayerKey, "tasks_verify", function()
            local VerifyTransaction = GetActiveResetContext(PlayerController, PlayerKey)
            if VerifyTransaction == nil then
                FailReset(PlayerController, PlayerKey, "player_context_lost_during_task_verify")
                return
            end
            local Verified, VerifyReason = TaskMgr:VerifyDailyWeeklyTasksReset(PlayerController)
            LogReset(PlayerController, Verified and "INFO" or "WARN", "tasks_verify",
                "attempt=" .. tostring(Attempt) .. " verified=" .. tostring(Verified) ..
                    " reason=" .. tostring(VerifyReason))
            if Verified then
                GrantItemsStep(1)
            elseif Attempt >= RESET_TASK_MAX_ATTEMPTS then
                FailReset(PlayerController, PlayerKey, "tasks_" .. tostring(VerifyReason))
            else
                ResetTasksStep(Attempt + 1)
            end
        end)
    end

    GrantItemsStep = function(Attempt)
        LogReset(PlayerController, "INFO", "initial_items_grant", "attempt=" .. tostring(Attempt))
        local ActiveTransaction, ActivePawn, ActiveState = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil or ActivePawn == nil or ActiveState == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_grant")
            return
        end

        local GrantCallSucceeded, GrantResult = pcall(PlayerInitialData.Grant, ActivePawn)
        LogReset(PlayerController, GrantCallSucceeded and GrantResult and "INFO" or "WARN",
            "initial_items_grant", "attempt=" .. tostring(Attempt) .. " callSucceeded=" ..
                tostring(GrantCallSucceeded) .. " result=" .. tostring(GrantResult))
        if not GrantCallSucceeded then
            FailReset(PlayerController, PlayerKey, "initial_items_grant_exception")
            return
        end
        ScheduleResetStep(PlayerController, PlayerKey, "initial_items_verify", function()
            local VerifyTransaction, VerifyPawn, VerifyState =
                GetActiveResetContext(PlayerController, PlayerKey)
            if VerifyTransaction == nil or VerifyPawn == nil or VerifyState == nil then
                FailReset(PlayerController, PlayerKey, "player_context_lost_during_grant_verify")
                return
            end

            local Verified, Mismatches = PlayerInitialData.VerifyGrant(VerifyPawn)
            local First = Mismatches ~= nil and Mismatches[1] or nil
            local MismatchDetail = First ~= nil and
                                       (" itemID=" .. tostring(First.ItemID) .. " actual=" ..
                                           tostring(First.Actual) .. " expected=" .. tostring(First.Expected)) or ""
            LogReset(PlayerController, Verified and "INFO" or "WARN", "initial_items_verify",
                "attempt=" .. tostring(Attempt) .. " verified=" .. tostring(Verified) ..
                    " mismatchCount=" .. tostring(Mismatches ~= nil and #Mismatches or 0) .. MismatchDetail)
            if not Verified then
                if Attempt >= RESET_GRANT_MAX_ATTEMPTS then
                    local Detail = First ~= nil and
                                       (tostring(First.ItemID) .. "_" .. tostring(First.Actual) .. "_of_" ..
                                           tostring(First.Expected)) or "unknown"
                    FailReset(PlayerController, PlayerKey, "initial_items_" .. Detail)
                else
                    GrantItemsStep(Attempt + 1)
                end
                return
            end

            LogReset(PlayerController, "INFO", "finalize", "applying server runtime defaults")
            FinalizeServerState(PlayerController, VerifyPawn, VerifyState)
            LogReset(PlayerController, "INFO", "finalize", "server runtime defaults applied")
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
                "玩家数据已重置，请手动返回大厅")
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_PlayerDataReset")
            LogReset(PlayerController, "INFO", "completed",
                "removeRequests=" .. tostring(ActiveTransaction.RemoveRequests) ..
                    " grantAttempts=" .. tostring(Attempt) ..
                    " finalLevel=1 finalExp=0 returningToLobby=false")
            ResetTransactions[PlayerKey] = nil
            UGCTimerUtility.CreateLuaTimer(8, function()
                if PlayerController ~= nil and (UE.IsValid == nil or UE.IsValid(PlayerController)) then
                    PlayerController.bGMResetInProgress = false
                    LogReset(PlayerController, "INFO", "cleanup", "resetInProgress=false transactionReleased=true")
                end
            end, false)
        end)
    end

    local StartSucceeded, StartError = pcall(ClearBackpackStep, 1)
    if not StartSucceeded then
        LogReset(PlayerController, "ERROR", "start", "exception=" .. tostring(StartError))
        FailReset(PlayerController, PlayerKey, "stage_exception_" .. tostring(StartError))
    end
end

--- 服务端 GM：将点击按钮玩家的每日、每周任务补到目标进度，不领取奖励。
function GM:S_CompleteDailyWeeklyTasks(Param, PlayerController)
    if not UGCGameSystem.IsServer() then
        return
    end
    if PlayerController == nil or PlayerController.bGMResetInProgress == true then
        ugcprint("[GMTask] rejected: PlayerController is nil")
        return
    end

    local DailyResult, WeeklyResult = TaskMgr:CompleteDailyWeeklyTasksOnServer(PlayerController)
    local FailedCount = (DailyResult.Failed or 0) + (WeeklyResult.Failed or 0)
    if FailedCount > 0 then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
            "任务完成操作部分失败，请查看服务端日志")
        ugcprint("[GMTask] partially failed player=" .. tostring(PlayerController.PlayerKey) ..
                     " dailyFailed=" .. tostring(DailyResult.Failed) ..
                     " weeklyFailed=" .. tostring(WeeklyResult.Failed))
        return
    end

    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
        "每日和每周任务已全部完成，请手动领取奖励")
    ugcprint("[GMTask] completed player=" .. tostring(PlayerController.PlayerKey) ..
                 " dailyUpdated=" .. tostring(DailyResult.Completed) ..
                 " dailyAlready=" .. tostring(DailyResult.AlreadyCompleted) ..
                 " weeklyUpdated=" .. tostring(WeeklyResult.Completed) ..
                 " weeklyAlready=" .. tostring(WeeklyResult.AlreadyCompleted))
end

local function ShowTitleToast(PlayerController, Message)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast", Message)
    end
end

--- 服务端 GM：校验称号 ID，并为当前玩家直接解锁称号，不自动装备。
function GM:S_GrantCustomTitle(Param, PlayerController)
    if not UGCGameSystem.IsServer() then
        return
    end
    if PlayerController == nil or PlayerController.PlayerKey == nil or
        PlayerController.bGMResetInProgress == true then
        ugcprint("[GMTitle] grant rejected: PlayerController or PlayerKey is nil")
        return
    end

    local TitleID = tonumber(Param)
    if TitleID == nil or TitleID ~= math.floor(TitleID) or TitleID < 1 or TitleID > TitleConfig.MaxTitleID then
        ShowTitleToast(PlayerController, "称号ID无效，请输入1-" .. tostring(TitleConfig.MaxTitleID) .. "的整数")
        ugcprint("[GMTitle] grant rejected player=" .. tostring(PlayerController.PlayerKey) ..
                     " param=" .. tostring(Param))
        return
    end

    local Config = TitleConfig.GetTitle(TitleID)
    if Config == nil then
        ShowTitleToast(PlayerController, "找不到对应称号配置")
        ugcprint("[GMTitle] grant rejected player=" .. tostring(PlayerController.PlayerKey) ..
                     " titleID=" .. tostring(TitleID) .. " config=nil")
        return
    end

    local PlayerKey = tostring(PlayerController.PlayerKey)
    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil or PlayerState.IsTitleUnlocked == nil or PlayerController.UnlockTitle == nil then
        ShowTitleToast(PlayerController, "称号系统尚未就绪，请稍后重试")
        ugcprint("[GMTitle] grant rejected player=" .. PlayerKey .. " titleID=" .. tostring(TitleID) ..
                     " reason=title_system_not_ready")
        return
    end

    if PlayerState:IsTitleUnlocked(TitleID) then
        ShowTitleToast(PlayerController, "已经拥有称号“" .. tostring(Config.Name) .. "”")
        ugcprint("[GMTitle] grant skipped player=" .. PlayerKey .. " titleID=" .. tostring(TitleID) ..
                     " reason=already_unlocked")
        return
    end

    PlayerController:UnlockTitle(TitleID)
    if not PlayerState:IsTitleUnlocked(TitleID) then
        ShowTitleToast(PlayerController, "称号发放失败，请查看服务端日志")
        ugcprint("[GMTitle] grant failed player=" .. PlayerKey .. " titleID=" .. tostring(TitleID))
        return
    end

    ShowTitleToast(PlayerController, "称号“" .. tostring(Config.Name) .. "”已发放，请在称号界面装备")
    ugcprint("[GMTitle] completed player=" .. PlayerKey .. " titleID=" .. tostring(TitleID) ..
                 " titleName=" .. tostring(Config.Name))
end

return GM
