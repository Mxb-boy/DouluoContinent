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
    if PlayerController == nil or PlayerController.PlayerKey == nil then
        return
    end

    local TeamID = UGCTeamSystem.GetTeamIDByPlayerKey(PlayerController.PlayerKey)
    if TeamID == nil then
        return
    end

    local TeamPlayerControllers = UGCTeamSystem.GetPlayerControllersByTeamID(TeamID) or {}
    for _, TeamPlayerController in ipairs(TeamPlayerControllers) do
        self:AddTaskProgressOnServer(TaskConfig, AddValue, TeamPlayerController)
        TitleMgr:OnTaskProgress(TaskConfig.Key, AddValue, TeamPlayerController)
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

--[[---------------------获取任务组件-------------------------]] --
function TaskMgr:GetTaskComponents(PlayerController)
    local PC = PlayerController or UGCGameSystem.GetLocalPlayerController()
    local Component = UGCGamePartSystem.GetGamePartPlayerComponent("TaskManager", PC, "Task")
    local GM = UGCGamePartSystem.GetGamePartGlobalActor("TaskManager")
    return Component, GM, PC

end
return TaskMgr
