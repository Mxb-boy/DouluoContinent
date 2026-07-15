TaskMgr = TaskMgr or {}
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

--[[---------------------获取组件方法-------------------------]] --
function TaskMgr:GetTaskComponents(PlayerController)
    local PC = PlayerController or UGCGameSystem.GetLocalPlayerController()
    local Component = UGCGamePartSystem.GetGamePartPlayerComponent("TaskManager", PC, "Task")
    local GM = UGCGamePartSystem.GetGamePartGlobalActor("TaskManager")
    return Component, GM, PC

end
return TaskMgr
