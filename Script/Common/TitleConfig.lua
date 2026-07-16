local TitleConfig = {}

TitleConfig.Titles = {
    [1]  = { Name = "昆仑勇者", TextToGet = "战力达到：2万", BonusText = "攻击+1%\n生命+1%", Bonus = { AttackPercent = 1, HPPercent = 1 } },
    [2]  = { Name = "昆仑之主", TextToGet = "战力达到：2亿", BonusText = "攻击+2%\n生命+2%", Bonus = { AttackPercent = 2, HPPercent = 2 } },
    [3]  = { Name = "昆仑神使", TextToGet = "战力达到：1280亿", BonusText = "攻击+3%\n生命+3%", Bonus = { AttackPercent = 3, HPPercent = 3 } },
    [4]  = { Name = "睥睨天下", TextToGet = "战力达到：180万亿", BonusText = "攻击+4%\n生命+4%", Bonus = { AttackPercent = 4, HPPercent = 4 } },
    [5]  = { Name = "黄金之乡", TextToGet = "抽奖5次", BonusText = "攻击+5%\n生命+5%", Bonus = { AttackPercent = 5, HPPercent = 5 } },
    [6]  = { Name = "富甲一方", TextToGet = "抽奖10次", BonusText = "攻击+8%\n生命+8%", Bonus = { AttackPercent = 8, HPPercent = 8 } },
    [7]  = { Name = "丹青妙手", TextToGet = "称号奖池", BonusText = "攻击+3%\n生命+3%", Bonus = { AttackPercent = 3, HPPercent = 3 } },
    [8]  = { Name = "翡翠山谷", TextToGet = "通关副本1", BonusText = "攻击+1%\n生命+1%", Bonus = { AttackPercent = 1, HPPercent = 1 } },
    [9]  = { Name = "荒古无双", TextToGet = "通关副本2", BonusText = "攻击+1.5%\n生命+1.5%", Bonus = { AttackPercent = 1.5, HPPercent = 1.5 } },
    [10] = { Name = "威震四海", TextToGet = "通关副本3", BonusText = "攻击+2%\n生命+2%", Bonus = { AttackPercent = 2, HPPercent = 2 } },
    [11] = { Name = "神山圣尊", TextToGet = "通关副本4", BonusText = "攻击+2.5%\n生命+2.5%", Bonus = { AttackPercent = 2.5, HPPercent = 2.5 } },
    [12] = { Name = "九天天罡", TextToGet = "通关副本5", BonusText = "攻击+3%\n生命+3%", Bonus = { AttackPercent = 3, HPPercent = 3 } },
    [13] = { Name = "不周霸主", TextToGet = "称号奖池大奖", BonusText = "攻击+15%\n生命+15%", Bonus = { AttackPercent = 15, HPPercent = 15 } },
    [14] = { Name = "冲关达人", TextToGet = "签到7天", BonusText = "攻击+2%\n生命+2%", Bonus = { AttackPercent = 2, HPPercent = 2 } },
    [15] = { Name = "冲关至尊", TextToGet = "击败一万只怪物", BonusText = "攻击+4.5%\n生命+4.5%", Bonus = { AttackPercent = 4.5, HPPercent = 4.5 } },
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
        if unlockedTitles[id] or unlockedTitles[tostring(id)] then
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
