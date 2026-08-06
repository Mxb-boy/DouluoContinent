local GM = {}
local PlayerInitialData = UGCGameSystem.UGCRequire("Script.Common.PlayerInitialData")
local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
local TitleConfig = UGCGameSystem.UGCRequire("Script.Common.TitleConfig")

local PLAYER_SKILL_1_PATH = "Asset/Blueprint/Prefabs/Skills/Lin/PlayerSkill/PlayerSkill_1.PlayerSkill_1_C"
local RESET_RETRY_DELAY = 0.5
local RESET_CLEAR_MAX_ATTEMPTS = 6
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
    return CurFuncList
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

    if type(Skills) ~= "table" then
        Skills = {Skills}
    end
    for _, SkillInstance in pairs(Skills) do
        pcall(UGCPersistEffectSystem.RemoveSkillInstance, PlayerPawn, SkillInstance)
    end
end

local function ScheduleResetStep(Callback)
    UGCTimerUtility.CreateLuaTimer(RESET_RETRY_DELAY, function()
        local Success, Error = pcall(Callback)
        if not Success then
            for PlayerKey, Transaction in pairs(ResetTransactions) do
                FailReset(Transaction.PlayerController, PlayerKey, "stage_exception_" .. tostring(Error))
                break
            end
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
    if Transaction ~= nil and Transaction.BackpackCleared and PlayerPawn ~= nil then
        local GrantCallSucceeded, Granted = pcall(PlayerInitialData.Grant, PlayerPawn)
        local Verified = false
        if GrantCallSucceeded and Granted then
            local VerifyCallSucceeded, VerifyResult = pcall(PlayerInitialData.VerifyGrant, PlayerPawn)
            Verified = VerifyCallSucceeded and VerifyResult == true
        end
        ugcprint("[GMReset] compensation player=" .. tostring(PlayerKey) ..
                     " granted=" .. tostring(GrantCallSucceeded and Granted) .. " verified=" .. tostring(Verified))
    end
    ResetTransactions[PlayerKey] = nil
    if PlayerController ~= nil and (UE.IsValid == nil or UE.IsValid(PlayerController)) then
        PlayerController.bGMResetInProgress = false
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
            "玩家数据重置失败，请查看日志后重试")
    end
    ugcprint("[GMReset] failed player=" .. tostring(PlayerKey) .. " reason=" .. tostring(Reason))
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

    local PlayerPawn = GetPlayerPawn(PlayerController)
    local PlayerState = PlayerController and PlayerController.PlayerState or nil
    local PlayerKey = PlayerController ~= nil and PlayerController.PlayerKey ~= nil and
                          tostring(PlayerController.PlayerKey) or nil
    if PlayerController == nil or PlayerPawn == nil or PlayerState == nil or PlayerKey == nil then
        ugcprint("[GMReset] rejected: PlayerController, Pawn or PlayerState is nil")
        return
    end
    if PlayerState.bArchiveLoaded ~= true or PlayerState.ResetProgressionToDefaults == nil then
        ugcprint("[GMReset] rejected: player archive is not ready")
        return
    end
    if ResetTransactions[PlayerKey] ~= nil or PlayerController.bGMResetInProgress == true then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
            "玩家数据正在重置，请勿重复点击")
        ugcprint("[GMReset] rejected: reset already in progress player=" .. PlayerKey)
        return
    end

    local Transaction = {
        PlayerController = PlayerController,
        RemovedItemInstances = 0,
        BackpackCleared = false
    }
    ResetTransactions[PlayerKey] = Transaction
    PlayerController.bGMResetInProgress = true
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_PlayerDataResetStarted")
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
        "正在重置玩家数据，请稍候")
    ugcprint("[GMReset] request player=" .. PlayerKey)

    local ClearBackpackStep
    local ResetArchiveStep
    local ResetTasksStep
    local GrantItemsStep

    ClearBackpackStep = function(Attempt)
        local ActiveTransaction, ActivePawn = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil or ActivePawn == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_clear")
            return
        end

        local Cleared, RemovedCount, Remaining = PlayerInitialData.ClearBackpack(ActivePawn)
        ActiveTransaction.RemovedItemInstances = ActiveTransaction.RemovedItemInstances +
                                                     (tonumber(RemovedCount) or 0)
        if Cleared then
            ActiveTransaction.BackpackCleared = true
            ugcprint("[GMReset] backpack cleared player=" .. PlayerKey ..
                         " attempts=" .. tostring(Attempt))
            ResetArchiveStep(1)
            return
        end
        if Attempt >= RESET_CLEAR_MAX_ATTEMPTS then
            FailReset(PlayerController, PlayerKey,
                "backpack_remaining_" .. tostring(Remaining ~= nil and #Remaining or -1))
            return
        end
        ScheduleResetStep(function()
            ClearBackpackStep(Attempt + 1)
        end)
    end

    ResetArchiveStep = function(Attempt)
        local ActiveTransaction, _, ActiveState = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil or ActiveState == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_archive")
            return
        end

        local Saved, Reason = ActiveState:ResetProgressionToDefaults()
        if Saved then
            ugcprint("[GMReset] archive defaults verified player=" .. PlayerKey ..
                         " attempts=" .. tostring(Attempt))
            ResetTasksStep(1)
            return
        end
        if Attempt >= RESET_ARCHIVE_MAX_ATTEMPTS then
            FailReset(PlayerController, PlayerKey, "archive_" .. tostring(Reason))
            return
        end
        ScheduleResetStep(function()
            ResetArchiveStep(Attempt + 1)
        end)
    end

    ResetTasksStep = function(Attempt)
        local ActiveTransaction = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_tasks")
            return
        end

        local Requested, RequestReason = TaskMgr:ResetDailyWeeklyTasksOnServer(PlayerController)
        if not Requested then
            if Attempt >= RESET_TASK_MAX_ATTEMPTS then
                FailReset(PlayerController, PlayerKey, "tasks_" .. tostring(RequestReason))
            else
                ScheduleResetStep(function()
                    ResetTasksStep(Attempt + 1)
                end)
            end
            return
        end

        ScheduleResetStep(function()
            local VerifyTransaction = GetActiveResetContext(PlayerController, PlayerKey)
            if VerifyTransaction == nil then
                FailReset(PlayerController, PlayerKey, "player_context_lost_during_task_verify")
                return
            end
            local Verified, VerifyReason = TaskMgr:VerifyDailyWeeklyTasksReset(PlayerController)
            if Verified then
                ugcprint("[GMReset] task lines verified player=" .. PlayerKey ..
                             " attempts=" .. tostring(Attempt))
                GrantItemsStep(1)
            elseif Attempt >= RESET_TASK_MAX_ATTEMPTS then
                FailReset(PlayerController, PlayerKey, "tasks_" .. tostring(VerifyReason))
            else
                ResetTasksStep(Attempt + 1)
            end
        end)
    end

    GrantItemsStep = function(Attempt)
        local ActiveTransaction, ActivePawn, ActiveState = GetActiveResetContext(PlayerController, PlayerKey)
        if ActiveTransaction == nil or ActivePawn == nil or ActiveState == nil then
            FailReset(PlayerController, PlayerKey, "player_context_lost_during_grant")
            return
        end

        PlayerInitialData.Grant(ActivePawn)
        ScheduleResetStep(function()
            local VerifyTransaction, VerifyPawn, VerifyState =
                GetActiveResetContext(PlayerController, PlayerKey)
            if VerifyTransaction == nil or VerifyPawn == nil or VerifyState == nil then
                FailReset(PlayerController, PlayerKey, "player_context_lost_during_grant_verify")
                return
            end

            local Verified, Mismatches = PlayerInitialData.VerifyGrant(VerifyPawn)
            if not Verified then
                if Attempt >= RESET_GRANT_MAX_ATTEMPTS then
                    local First = Mismatches ~= nil and Mismatches[1] or nil
                    local Detail = First ~= nil and
                                       (tostring(First.ItemID) .. "_" .. tostring(First.Actual) .. "_of_" ..
                                           tostring(First.Expected)) or "unknown"
                    FailReset(PlayerController, PlayerKey, "initial_items_" .. Detail)
                else
                    GrantItemsStep(Attempt + 1)
                end
                return
            end

            FinalizeServerState(PlayerController, VerifyPawn, VerifyState)
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
                "玩家数据已重置，即将返回大厅")
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_PlayerDataReset")
            ugcprint("[GMReset] completed player=" .. PlayerKey ..
                         " removedItemInstances=" .. tostring(ActiveTransaction.RemovedItemInstances) ..
                         " grantAttempts=" .. tostring(Attempt))
            ResetTransactions[PlayerKey] = nil
            UGCTimerUtility.CreateLuaTimer(8, function()
                if PlayerController ~= nil and (UE.IsValid == nil or UE.IsValid(PlayerController)) then
                    PlayerController.bGMResetInProgress = false
                end
            end, false)
        end)
    end

    local StartSucceeded, StartError = pcall(ClearBackpackStep, 1)
    if not StartSucceeded then
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
