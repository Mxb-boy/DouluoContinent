local TitleSystem = {}

function TitleSystem:GetTitleBonus(titleID)
    return {
        Attack = 0,
        HP = 0,
    }
end

function TitleSystem:ApplyTitleBonus(playerController, oldTitleID, newTitleID)
    local oldBonus = self:GetTitleBonus(oldTitleID)
    local newBonus = self:GetTitleBonus(newTitleID)

    -- TODO:
    -- 等属性系统完成后，在这里移除旧称号加成，添加新称号加成
end

return TitleSystem