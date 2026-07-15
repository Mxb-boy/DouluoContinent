L_Enum = L_Enum or {}

local AllTask = {
    OnlineTime = {
        Key = "OnlineTime",
        Name = "在线挂机",
        EveryDay = {
            TaskLineName = "每日任务",
            TaskIndex = 1,
            TaskID = 1001
        },
        EveryWeek = {
            TaskLineName = "每周任务",
            TaskIndex = 1,
            TaskID = 2001
        }
    },
    KillMonster = {
        Key = "KillMonster",
        Name = "击杀任意岛屿怪物",
        EveryDay = {
            TaskLineName = "每日任务",
            TaskIndex = 2,
            TaskID = 1002
        },
        EveryWeek = {
            TaskLineName = "每周任务",
            TaskIndex = 2,
            TaskID = 2002
        }
    },
    TowerPass = {
        Key = "TowerPass",
        Name = "爬塔通关",
        EveryDay = {
            TaskLineName = "每日任务",
            TaskIndex = 3,
            TaskID = 1003
        },
        EveryWeek = {
            TaskLineName = "每周任务",
            TaskIndex = 3,
            TaskID = 2003
        }
    },
    UseHunHuan = {
        Key = "UseHunHuan",
        Name = "吞噬星环",
        EveryDay = {
            TaskLineName = "每日任务",
            TaskIndex = 4,
            TaskID = 1004
        },
        EveryWeek = {
            TaskLineName = "每周任务",
            TaskIndex = 4,
            TaskID = 2004
        }
    },
    LotterySummon = {
        Key = "LotterySummon",
        Name = "抽奖召唤",
        EveryDay = {
            TaskLineName = "每日任务",
            TaskIndex = 5,
            TaskID = 1005
        },
        EveryWeek = {
            TaskLineName = "每周任务",
            TaskIndex = 5,
            TaskID = 2005
        }
    }
}

L_Enum.AllTask = AllTask

return L_Enum
