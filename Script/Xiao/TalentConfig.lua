local TalentConfig = {}

TalentConfig.TestGrantEnabled = false
TalentConfig.TestGrantPoints = 19
TalentConfig.SkillBookItemID = 8310132
TalentConfig.SkillBookShopItemID = 1058
TalentConfig.SkillBookPointsPerUse = 1
TalentConfig.SignInSkillBookReward = {
    EventID = 10086,
    ItemID = TalentConfig.SkillBookItemID,
    DisplayItemID = TalentConfig.SkillBookShopItemID,
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
        Name = "坚体",
        Description = "最大生命值永久增加100点。",
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
        Name = "战锋",
        Description = "攻击力永久增加10点。",
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
        Name = "锐目",
        Description = "暴击率永久提升10%。\n初始暴击伤害倍率为2倍。",
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
        Name = "战意",
        Description = "造成伤害时，有2%概率\n使攻击力提升10%。",
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
        Name = "生息",
        Description = "造成伤害时，有2%概率\n恢复10%最大生命值。",
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
        Name = "洞察",
        Description = "造成伤害时，有2%概率\n使暴击率提升10%。",
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
        Name = "致命",
        Description = "造成伤害时，有2%概率\n使暴击伤害倍率增加0.5。",
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
        Name = "迅捷",
        Description = "大招的冷却时间缩短50%。",
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
        Name = "强攻",
        Description = "攻击力永久提升10%。",
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
        Name = "玄体",
        Description = "最大生命值永久提升15%。",
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
        Name = "回春",
        Description = "使概率生命恢复的恢复量\n由10%提升至15%最大生命值。",
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
        Description = "暴击率永久提升10%。",
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
        Name = "破绽",
        Description = "使概率暴击率增益的效果\n由10%提升至20%。",
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
        Name = "摧城",
        Description = "暴击伤害倍率永久增加0.5。",
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
        Name = "绝杀",
        Description = "使概率暴伤增益的效果\n由0.5提升至1.0。",
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
