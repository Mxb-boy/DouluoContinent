local TalentConfig = {}

TalentConfig.TestGrantEnabled = false
TalentConfig.TestGrantPoints = 19
TalentConfig.SkillBookItemID = 8310132
TalentConfig.SkillBookShopItemID = 1058
TalentConfig.SkillBookPointsPerUse = 1
TalentConfig.SignInSkillBookReward = {
    EventID = 10086,
    ItemID = TalentConfig.SkillBookItemID,
    Count = 1
}
TalentConfig.ResetPotionItemID = 8310136
TalentConfig.ResetPotionShopItemID = 1062
TalentConfig.ResetPotionConsumeCount = 1
TalentConfig.MaxTotalPoints = 69
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
TalentConfig.SkillCooldownTags = {
    "TalentSkillWeapon",
    "TalentSkillUltimate"
}
TalentConfig.PassiveBuffs = {
    Attack = {
        Chance = 0.02,
        Path = "/Douluo/Asset/Blueprint/Prefabs/Buffs/TalentPassiveAttack.TalentPassiveAttack_C",
        AttackPercent = 0.1
    },
    Heal = {
        Chance = 0.02,
        Path = "/Douluo/Asset/Blueprint/Prefabs/Buffs/TalentPassiveHeal.TalentPassiveHeal_C",
        HealMaxHealthPercent = 0.1
    },
    CritRate = {
        Chance = 0.02,
        Path = "/Douluo/Asset/Blueprint/Prefabs/Buffs/TalentPassiveCritRate.TalentPassiveCritRate_C",
        CritRate = 0.1
    },
    CritDamage = {
        Chance = 0.02,
        Path = "/Douluo/Asset/Blueprint/Prefabs/Buffs/TalentPassiveCritDamage.TalentPassiveCritDamage_C",
        CritMultiplierFlat = 0.5
    }
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
        Cost = 2,
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
        Cost = 2,
        RequireID = 1,
        Effects = {
            Stats = {
                CritRate = 0.1
            }
        }
    },
    [4] = {
        ID = 4,
        Name = "概率攻击增益",
        Row = 3,
        Column = 2,
        Cost = 3,
        RequireID = 2,
        Effects = {
            PassiveBuffKey = "Attack"
        }
    },
    [5] = {
        ID = 5,
        Name = "概率生命恢复",
        Row = 3,
        Column = 6,
        Cost = 3,
        RequireID = 2,
        Effects = {
            PassiveBuffKey = "Heal"
        }
    },
    [6] = {
        ID = 6,
        Name = "概率暴击率增益",
        Row = 3,
        Column = 10,
        Cost = 3,
        RequireID = 3,
        Effects = {
            PassiveBuffKey = "CritRate"
        }
    },
    [7] = {
        ID = 7,
        Name = "概率暴伤增益",
        Row = 3,
        Column = 14,
        Cost = 3,
        RequireID = 3,
        Effects = {
            PassiveBuffKey = "CritDamage"
        }
    },
    [8] = {
        ID = 8,
        Name = "冷却缩减",
        Row = 4,
        Column = 1,
        Cost = 4,
        RequireID = 4,
        Effects = {
            SkillCooldownMultiplier = 0.5
        }
    },
    [9] = {
        ID = 9,
        Name = "攻击强化",
        Row = 4,
        Column = 3,
        Cost = 4,
        RequireID = 4,
        Effects = {
            Stats = {
                AttackPercent = 0.1
            }
        }
    },
    [10] = {
        ID = 10,
        Name = "生命强化",
        Row = 4,
        Column = 5,
        Cost = 4,
        RequireID = 5,
        Effects = {
            Stats = {
                MaxHealthPercent = 0.15
            }
        }
    },
    [11] = {
        ID = 11,
        Name = "愈合强化",
        Row = 4,
        Column = 7,
        Cost = 4,
        RequireID = 5,
        Effects = {
            PassiveBuffStats = {
                Heal = {
                    HealMaxHealthPercent = 0.05
                }
            }
        }
    },
    [12] = {
        ID = 12,
        Name = "精准",
        Row = 4,
        Column = 9,
        Cost = 4,
        RequireID = 6,
        Effects = {
            Stats = {
                CritRate = 0.1
            }
        }
    },
    [13] = {
        ID = 13,
        Name = "暴击增幅",
        Row = 4,
        Column = 11,
        Cost = 4,
        RequireID = 6,
        Effects = {
            PassiveBuffStats = {
                CritRate = {
                    CritRate = 0.1
                }
            }
        }
    },
    [14] = {
        ID = 14,
        Name = "毁灭",
        Row = 4,
        Column = 13,
        Cost = 4,
        RequireID = 7,
        Effects = {
            Stats = {
                CritMultiplierFlat = 0.5
            }
        }
    },
    [15] = {
        ID = 15,
        Name = "暴伤增幅",
        Row = 4,
        Column = 15,
        Cost = 4,
        RequireID = 7,
        Effects = {
            PassiveBuffStats = {
                CritDamage = {
                    CritMultiplierFlat = 0.5
                }
            }
        }
    },
    [16] = {
        ID = 16,
        Name = "激光",
        Row = 5,
        Column = 2,
        Cost = 5,
        RequireID = {8, 9},
        Effects = {
            UltimateSkillPath = "Asset/Blueprint/Prefabs/Skills/TF/jg.jg_C"
        }
    },
    [17] = {
        ID = 17,
        Name = "践踏",
        Row = 5,
        Column = 6,
        Cost = 5,
        RequireID = {10, 11},
        Effects = {
            UltimateSkillPath = "Asset/Blueprint/Prefabs/Skills/TF/JT.JT_C"
        }
    },
    [18] = {
        ID = 18,
        Name = "拔刀斩",
        Row = 5,
        Column = 10,
        Cost = 5,
        RequireID = {12, 13},
        Effects = {
            UltimateSkillPath = "Asset/Blueprint/Prefabs/Skills/TF/JT_2.JT_2_C"
        }
    },
    [19] = {
        ID = 19,
        Name = "如来神掌",
        Row = 5,
        Column = 14,
        Cost = 5,
        RequireID = {14, 15},
        Effects = {
            UltimateSkillPath = "Asset/Blueprint/Prefabs/Skills/TF/RLSZ.RLSZ_C"
        }
    }
}

return TalentConfig
