local TalentConfig = {}

TalentConfig.TestGrantEnabled = false
TalentConfig.TestGrantPoints = 19
TalentConfig.SkillBookItemID = 8310132
TalentConfig.SkillBookPointsPerUse = 1
TalentConfig.MaxTotalPoints = nil -- Set after the total talent-point cap is confirmed.
TalentConfig.Critical = {
    Enabled = true,
    BaseRate = 0.0,
    BaseMultiplier = 2.0
}
TalentConfig.UltimateNodeIDs = {
    [16] = true,
    [17] = true,
    [18] = true,
    [19] = true
}

-- [TalentNodeID] = {
--     ID = TalentNodeID,
--     Name = "Talent name",
--     Row = 1,
--     Column = 1,
--     Cost = 1,
--     RequireID = nil, -- nil, one node ID, or a list of node IDs
-- }
TalentConfig.Nodes = {
    [1] = {
        ID = 1,
        Name = "生命",
        Row = 1,
        Column = 8,
        Cost = 1,
        RequireID = nil,
        Effects = {
            Stats = {
                MaxHealthFlat = 100
            }
        }
    },
    [2] = {
        ID = 2,
        Name = "攻击",
        Row = 2,
        Column = 4,
        Cost = 1,
        RequireID = 1,
        Effects = {
            Stats = {
                AttackFlat = 10
            }
        }
    },
    [3] = {
        ID = 3,
        Name = "暴击",
        Row = 2,
        Column = 12,
        Cost = 1,
        RequireID = 1,
        Effects = {
            Stats = {
                CritRate = 0.1
            }
        }
    },
    [4] = {
        ID = 4,
        Name = "被动技能攻击",
        Row = 3,
        Column = 2,
        Cost = 1,
        RequireID = 2,
        Effects = {
            Stats = {
                AttackPercent = 0.1
            }
        }
    },
    [5] = {
        ID = 5,
        Name = "被动技能CD",
        Row = 3,
        Column = 6,
        Cost = 1,
        RequireID = 2
    },
    [6] = {
        ID = 6,
        Name = "被动技能暴击率",
        Row = 3,
        Column = 10,
        Cost = 1,
        RequireID = 3,
        Effects = {
            Stats = {
                CritRate = 0.1
            }
        }
    },
    [7] = {
        ID = 7,
        Name = "被动技能暴击伤害",
        Row = 3,
        Column = 14,
        Cost = 1,
        RequireID = 3,
        Effects = {
            Stats = {
                CritMultiplierFlat = 0.5
            }
        }
    },
    [8] = {
        ID = 8,
        Name = "属性加成待定节点8",
        Row = 4,
        Column = 1,
        Cost = 1,
        RequireID = 4
    },
    [9] = {
        ID = 9,
        Name = "属性加成待定节点9",
        Row = 4,
        Column = 3,
        Cost = 1,
        RequireID = 4
    },
    [10] = {
        ID = 10,
        Name = "属性加成待定节点10",
        Row = 4,
        Column = 5,
        Cost = 1,
        RequireID = 5
    },
    [11] = {
        ID = 11,
        Name = "属性加成待定节点11",
        Row = 4,
        Column = 7,
        Cost = 1,
        RequireID = 5
    },
    [12] = {
        ID = 12,
        Name = "属性加成待定节点12",
        Row = 4,
        Column = 9,
        Cost = 1,
        RequireID = 6
    },
    [13] = {
        ID = 13,
        Name = "属性加成待定节点13",
        Row = 4,
        Column = 11,
        Cost = 1,
        RequireID = 6
    },
    [14] = {
        ID = 14,
        Name = "属性加成待定节点14",
        Row = 4,
        Column = 13,
        Cost = 1,
        RequireID = 7
    },
    [15] = {
        ID = 15,
        Name = "属性加成待定节点15",
        Row = 4,
        Column = 15,
        Cost = 1,
        RequireID = 7
    },
    [16] = {
        ID = 16,
        Name = "大招待定节点16",
        Row = 5,
        Column = 2,
        Cost = 1,
        RequireID = {8, 9}
    },
    [17] = {
        ID = 17,
        Name = "大招待定节点17",
        Row = 5,
        Column = 6,
        Cost = 1,
        RequireID = {10, 11}
    },
    [18] = {
        ID = 18,
        Name = "大招待定节点18",
        Row = 5,
        Column = 10,
        Cost = 1,
        RequireID = {12, 13}
    },
    [19] = {
        ID = 19,
        Name = "大招待定节点19",
        Row = 5,
        Column = 14,
        Cost = 1,
        RequireID = {14, 15}
    }
}

return TalentConfig
