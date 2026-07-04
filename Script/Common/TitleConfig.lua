local TitleConfig = {}

TitleConfig.Titles = {
    [1]  = { TextToGet = "战力达到：****", BonusText = "攻击+1%\n生命+1%", Bonus = { AttackPercent = 1, HPPercent = 1 } },
    [2]  = { TextToGet = "战力达到：****", BonusText = "攻击+2%\n生命+2%", Bonus = { AttackPercent = 2, HPPercent = 2 } },
    [3]  = { TextToGet = "战力达到：****", BonusText = "攻击+3%\n生命+3%", Bonus = { AttackPercent = 3, HPPercent = 3 } },
    [4]  = { TextToGet = "战力达到：****", BonusText = "攻击+4%\n生命+4%", Bonus = { AttackPercent = 4, HPPercent = 4 } },
    [5]  = { TextToGet = "消费1千绿洲币", BonusText = "攻击+5%\n生命+5%", Bonus = { AttackPercent = 5, HPPercent = 5 } },
    [6]  = { TextToGet = "消费1万绿洲币", BonusText = "攻击+8%\n生命+8%", Bonus = { AttackPercent = 8, HPPercent = 8 } },
    [7]  = { TextToGet = "死亡复活累计666次", BonusText = "攻击+3%\n生命+3%", Bonus = { AttackPercent = 3, HPPercent = 3 } },
    [8]  = { TextToGet = "通关副本1", BonusText = "攻击+1%\n生命+1%", Bonus = { AttackPercent = 1, HPPercent = 1 } },
    [9]  = { TextToGet = "通关副本2", BonusText = "攻击+1.5%\n生命+1.5%", Bonus = { AttackPercent = 1.5, HPPercent = 1.5 } },
    [10] = { TextToGet = "通关副本3", BonusText = "攻击+2%\n生命+2%", Bonus = { AttackPercent = 2, HPPercent = 2 } },
    [11] = { TextToGet = "通关副本4", BonusText = "攻击+2.5%\n生命+2.5%", Bonus = { AttackPercent = 2.5, HPPercent = 2.5 } },
    [12] = { TextToGet = "通关副本5", BonusText = "攻击+3%\n生命+3%", Bonus = { AttackPercent = 3, HPPercent = 3 } },
    [13] = { TextToGet = "通关副本6", BonusText = "攻击+3.5%\n生命+3.5%", Bonus = { AttackPercent = 3.5, HPPercent = 3.5 } },
    [14] = { TextToGet = "连续签到7天", BonusText = "攻击+2%\n生命+2%", Bonus = { AttackPercent = 2, HPPercent = 2 } },
    [15] = { TextToGet = "连续签到21天", BonusText = "攻击+4.5%\n生命+4.5%", Bonus = { AttackPercent = 4.5, HPPercent = 4.5 } },
}

TitleConfig.MaxTitleID = 15

function TitleConfig.GetTitle(titleID)
    return TitleConfig.Titles[tonumber(titleID) or 0]
end

function TitleConfig.GetTitleBonus(titleID)
    local config = TitleConfig.GetTitle(titleID)
    local bonus = config and config.Bonus or nil
    return {
        AttackPercent = bonus and bonus.AttackPercent or 0,
        HPPercent = bonus and bonus.HPPercent or 0,
    }
end

TitleConfig.GetTitleAttributeBonus = TitleConfig.GetTitleBonus

function TitleConfig.GetUnlockedTitleBonus(unlockedTitles)
    unlockedTitles = unlockedTitles or {}
    local result = {
        AttackPercent = 0,
        HPPercent = 0,
    }

    for id = 1, TitleConfig.MaxTitleID do
        if unlockedTitles[id] then
            local bonus = TitleConfig.GetTitleBonus(id)
            result.AttackPercent = result.AttackPercent + bonus.AttackPercent
            result.HPPercent = result.HPPercent + bonus.HPPercent
        end
    end

    return result
end

function TitleConfig.GetUnlockedTitleBonusByList(unlockedTitleIDs)
    local unlockedTitles = {}
    for _, titleID in ipairs(unlockedTitleIDs or {}) do
        unlockedTitles[tonumber(titleID) or 0] = true
    end

    return TitleConfig.GetUnlockedTitleBonus(unlockedTitles)
end

TitleConfig.GetUnlockedTitleAttributeBonus = TitleConfig.GetUnlockedTitleBonus

return TitleConfig
