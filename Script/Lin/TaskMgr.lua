TaskMgr = TaskMgr or {}
local TitleMgr = UGCGameSystem.UGCRequire("Script.Xiao.TitleMgr")
local TaskConfigEnum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")
--[[------------------任务进度管理器----------------------------]] --
-- 使用教程：先引用，在直接调用这个方法RequestAddTaskProgress
-- 任务要调用L_Enum.AllTask.LotterySummon
-- local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
-- local L_Enum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")
--   TaskMgr:RequestAddTaskProgress(L_Enum.AllTask.KillMonster, 1)

--[[------------------活跃任务的调用方法(目前只做了活跃度没做阶段)----------------------------]] --

--[[---------------------增加任务进度-------------------------]] --
function TaskMgr:RequestAddTaskProgress(TaskConfig, AddValue)
    local PC = UGCGameSystem.GetLocalPlayerController()
    UnrealNetwork.CallUnrealRPC(PC, PC, "Server_AddTaskProgress", TaskConfig.Key, AddValue)
end

--[[----------------------服务端调用------------------------]] --
function TaskMgr:AddTaskProgressOnServer(TaskConfig, AddValue, PlayerController)
    if PlayerController == nil or PlayerController.bGMResetInProgress == true then
        return
    end
    local Component, GM, TargetPC = self:GetTaskComponents(PlayerController)

    for _, TaskLineType in ipairs({"EveryDay", "EveryWeek"}) do
        local TaskInfo = TaskConfig[TaskLineType]
        local Current = Component:GetPercentTaskProgress(TaskInfo.TaskLineName, TaskInfo.TaskIndex)

        GM:UpdateTaskProgress({
            TaskLineName = TaskInfo.TaskLineName,
            PercentTaskIndex = TaskInfo.TaskIndex,
            LevelTaskLevelIndex = 0,
            LevelTaskIndex = 0
        }, TargetPC, Current + AddValue)
    end
end

--[[----------------------给同队玩家增加任务进度------------------------]] --
function TaskMgr:AddTeamTaskProgressOnServer(TaskConfig, AddValue, PlayerController)
    if PlayerController == nil or PlayerController.PlayerKey == nil or
        PlayerController.bGMResetInProgress == true then
        return
    end

    local TeamID = UGCTeamSystem.GetTeamIDByPlayerKey(PlayerController.PlayerKey)
    if TeamID == nil then
        return
    end

    local TeamPlayerControllers = UGCTeamSystem.GetPlayerControllersByTeamID(TeamID) or {}
    for _, TeamPlayerController in ipairs(TeamPlayerControllers) do
        if TeamPlayerController ~= nil and TeamPlayerController.bGMResetInProgress ~= true then
            self:AddTaskProgressOnServer(TaskConfig, AddValue, TeamPlayerController)
            TitleMgr:OnTaskProgress(TaskConfig.Key, AddValue, TeamPlayerController)
        end
    end
end

--- 使用官方任务模板 API，将指定活跃任务线中的全部任务精确补到目标进度。
--- 只更新任务进度，不调用任何奖励领取接口。
---@param TaskLineType string "EveryDay" 或 "EveryWeek"
---@param PlayerController userdata
---@return table
function TaskMgr:CompletePercentTaskLineOnServer(TaskLineType, PlayerController)
    local Result = {
        Total = 0,
        Completed = 0,
        AlreadyCompleted = 0,
        Failed = 0
    }
    if TaskLineType ~= "EveryDay" and TaskLineType ~= "EveryWeek" then
        Result.Failed = 1
        return Result
    end

    local Component, GlobalActor, TargetPC = self:GetTaskComponents(PlayerController)
    if Component == nil or GlobalActor == nil or TargetPC == nil then
        Result.Failed = 1
        ugcprint("[GMTask] task component unavailable lineType=" .. tostring(TaskLineType))
        return Result
    end

    for _, TaskConfig in pairs(TaskConfigEnum.AllTask or {}) do
        local TaskInfo = TaskConfig[TaskLineType]
        if TaskInfo ~= nil and TaskInfo.TaskLineName ~= nil and TaskInfo.TaskIndex ~= nil and
            TaskInfo.TaskID ~= nil then
            Result.Total = Result.Total + 1

            local TargetSuccess, TargetValue = pcall(GlobalActor.GetTaskTarget, GlobalActor, TaskInfo.TaskID)
            local CurrentSuccess, CurrentValue = pcall(Component.GetPercentTaskProgress, Component,
                TaskInfo.TaskLineName, TaskInfo.TaskIndex)
            TargetValue = tonumber(TargetValue)
            CurrentValue = tonumber(CurrentValue)

            if not TargetSuccess or not CurrentSuccess or TargetValue == nil or TargetValue <= 0 or
                CurrentValue == nil then
                Result.Failed = Result.Failed + 1
                ugcprint("[GMTask] target lookup failed key=" .. tostring(TaskConfig.Key) .. " taskID=" ..
                             tostring(TaskInfo.TaskID))
            elseif CurrentValue >= TargetValue then
                Result.AlreadyCompleted = Result.AlreadyCompleted + 1
            else
                local TaskIndex = {
                    TaskLineName = TaskInfo.TaskLineName,
                    PercentTaskIndex = TaskInfo.TaskIndex,
                    LevelTaskLevelIndex = 0,
                    LevelTaskIndex = 0
                }
                local UpdateSuccess = pcall(GlobalActor.UpdateTaskProgress, GlobalActor, TaskIndex, TargetPC,
                    TargetValue)
                local VerifySuccess, NewValue = pcall(Component.GetPercentTaskProgress, Component,
                    TaskInfo.TaskLineName, TaskInfo.TaskIndex)
                if UpdateSuccess and VerifySuccess and (tonumber(NewValue) or 0) >= TargetValue then
                    Result.Completed = Result.Completed + 1
                else
                    Result.Failed = Result.Failed + 1
                    ugcprint("[GMTask] update failed key=" .. tostring(TaskConfig.Key) .. " taskID=" ..
                                 tostring(TaskInfo.TaskID) .. " target=" .. tostring(TargetValue) ..
                                 " current=" .. tostring(NewValue))
                end
            end
        end
    end
    return Result
end

--- 一次完成当前玩家的全部每日和每周任务，但不领取任何奖励。
---@param PlayerController userdata
---@return table, table
function TaskMgr:CompleteDailyWeeklyTasksOnServer(PlayerController)
    local DailyResult = self:CompletePercentTaskLineOnServer("EveryDay", PlayerController)
    local WeeklyResult = self:CompletePercentTaskLineOnServer("EveryWeek", PlayerController)
    return DailyResult, WeeklyResult
end

local RESET_TASK_LINE_TYPES = {"EveryDay", "EveryWeek"}

local function GetConfiguredTaskLineNames()
    local Names = {}
    local Count = 0
    for _, TaskConfig in pairs(TaskConfigEnum.AllTask or {}) do
        for _, TaskLineType in ipairs(RESET_TASK_LINE_TYPES) do
            local TaskInfo = TaskConfig[TaskLineType]
            if TaskInfo ~= nil and TaskInfo.TaskLineName ~= nil and Names[TaskInfo.TaskLineName] ~= true then
                Names[TaskInfo.TaskLineName] = true
                Count = Count + 1
            end
        end
    end
    return Names, Count
end

--- 重置当前玩家的每日、每周活跃任务线，包括进度、活跃度和奖励状态。
---@param PlayerController userdata
---@return boolean, string|nil
function TaskMgr:ResetDailyWeeklyTasksOnServer(PlayerController)
    local Component, _, TargetPC = self:GetTaskComponents(PlayerController)
    if Component == nil or TargetPC == nil or Component.ResetPercentTaskLine == nil then
        return false, "task_component_unavailable"
    end

    local TaskLineNames, TaskLineCount = GetConfiguredTaskLineNames()
    if TaskLineCount == 0 then
        return false, "no_configured_task_lines"
    end
    for TaskLineName in pairs(TaskLineNames) do
        local Success, Error = pcall(Component.ResetPercentTaskLine, Component, TaskLineName)
        if not Success then
            ugcprint("[GMTaskReset] reset failed line=" .. tostring(TaskLineName) ..
                         " error=" .. tostring(Error))
            return false, "reset_failed_" .. tostring(TaskLineName) .. "_error_" .. tostring(Error)
        end
    end
    return true, nil
end

---@param PlayerController userdata
---@return boolean, string|nil
function TaskMgr:VerifyDailyWeeklyTasksReset(PlayerController)
    local Component, _, TargetPC = self:GetTaskComponents(PlayerController)
    if Component == nil or TargetPC == nil or Component.GetPercentTaskProgress == nil or
        Component.GetTaskLineProgress == nil or Component.GetPercentTaskState == nil then
        return false, "task_component_unavailable"
    end

    local TaskLineNames, TaskLineCount = GetConfiguredTaskLineNames()
    if TaskLineCount == 0 then
        return false, "no_configured_task_lines"
    end
    for TaskLineName in pairs(TaskLineNames) do
        local Success, Progress = pcall(Component.GetTaskLineProgress, Component, TaskLineName)
        Progress = tonumber(Progress)
        if not Success or Progress == nil or Progress ~= 0 then
            return false, "task_line_progress_" .. tostring(TaskLineName) .. "_actual_" ..
                              tostring(Progress) .. "_callSucceeded_" .. tostring(Success)
        end

        -- ResetPercentTaskLine is the documented API that resets line progress and rewards.
        -- GetPercentTaskLineAwardStateList is not part of the public API and is absent on
        -- some PC/mobile runtimes, so verification must not depend on it.
    end

    for _, TaskConfig in pairs(TaskConfigEnum.AllTask or {}) do
        for _, TaskLineType in ipairs(RESET_TASK_LINE_TYPES) do
            local TaskInfo = TaskConfig[TaskLineType]
            if TaskInfo ~= nil then
                local Success, Progress = pcall(Component.GetPercentTaskProgress, Component,
                    TaskInfo.TaskLineName, TaskInfo.TaskIndex)
                Progress = tonumber(Progress)
                if not Success or Progress == nil or Progress ~= 0 then
                    ugcprint("[GMTaskReset] verify failed key=" .. tostring(TaskConfig.Key) ..
                                 " line=" .. tostring(TaskInfo.TaskLineName) ..
                                 " progress=" .. tostring(Progress))
                    return false, "task_progress_" .. tostring(TaskConfig.Key) .. "_actual_" ..
                                      tostring(Progress) .. "_callSucceeded_" .. tostring(Success)
                end
                local StateSuccess, TaskState = pcall(Component.GetPercentTaskState, Component,
                    TaskInfo.TaskLineName, TaskInfo.TaskIndex)
                if not StateSuccess or TaskState == nil then
                    ugcprint("[GMTaskReset] verify task state failed key=" .. tostring(TaskConfig.Key) ..
                                 " state=" .. tostring(TaskState))
                    return false, "task_state_" .. tostring(TaskConfig.Key) .. "_actual_" ..
                                      tostring(TaskState) .. "_callSucceeded_" .. tostring(StateSuccess)
                end
                -- Enum values differ between template/runtime versions. Only reject
                -- completed states that the current runtime exposes by name; never
                -- guess numeric fallback values.
                local NotClaimed = EUGCTaskState ~= nil and EUGCTaskState.NotClaimed or nil
                local HasClaimed = EUGCTaskState ~= nil and EUGCTaskState.HasClaimed or nil
                if (NotClaimed ~= nil and TaskState == NotClaimed) or
                    (HasClaimed ~= nil and TaskState == HasClaimed) then
                    ugcprint("[GMTaskReset] completed state remained after reset key=" ..
                                 tostring(TaskConfig.Key) .. " state=" .. tostring(TaskState))
                    return false, "task_completed_state_" .. tostring(TaskConfig.Key) .. "_actual_" ..
                                      tostring(TaskState)
                end
            end
        end
    end
    return true, nil
end

--[[---------------------获取任务组件-------------------------]] --
function TaskMgr:GetTaskComponents(PlayerController)
    local PC = PlayerController or UGCGameSystem.GetLocalPlayerController()
    local Component = UGCGamePartSystem.GetGamePartPlayerComponent("TaskManager", PC, "Task")
    local GM = UGCGamePartSystem.GetGamePartGlobalActor("TaskManager")
    return Component, GM, PC

end
return TaskMgr
