--[[-------------------这里放角色状态，重连后可以恢复数据---------------------------]] --
local UGCPlayerState = {
    HunHuan = 1, -- 大魂环
    Probability_Bonus = 0, -- 掉落加成，比如本来掉落概率是20%,这个值是20，那就是20*1.2
    RegenPercent = 5, -- 战场回血：每秒恢复百分比（默认5%）
    HP = -1, -- 上一次离场时保存的血量，-1 表示从未存档
    -- 跨对局存档: 被 SaveToArchive 消费
    YXWD_InvincibleBuff = 0,
    YXWD_InvincibleBuffActive = false,
    YXWD_InvincibleBuffToken = 0,
    LotteryState = {},
    AutoPickButtonHidden = 0,
    AutoAttackButtonHidden = 0,
    ArchiveUID = nil,

    BaseAttack = 40, -- 基础攻击力
    BaseMaxHp = 100 -- 基础最大血量
}

-- ============================================================
-- 跨对局存档注册表（chunk 1）
-- 新增持久化数据只需在下面加一行即可：
--   { key = "存档键名", field = "PlayerState 字段名", default = 默认值 }
-- ============================================================
local ARCHIVE_KEYS = {{
    key = "HunHuan",
    field = "HunHuan",
    default = 1
}, {
    key = "RegenPercent",
    field = "RegenPercent",
    default = 5
}, {
    key = "HP",
    field = "HP",
    default = -1
}, {
    key = "YXWD_InvincibleBuff",
    field = "YXWD_InvincibleBuff",
    default = 0
}, {
    key = "LotteryState",
    field = "LotteryState",
    default = {}
}, {
    key = "BaseAttack",
    field = "BaseAttack",
    default = 40
}, {
    key = "BaseMaxHp",
    field = "BaseMaxHp",
    default = 100
} -- 示例: { key = "Gold",    field = "Gold",    default = 0 },
}

table.insert(ARCHIVE_KEYS, { key = "AutoPickButtonHidden", field = "AutoPickButtonHidden", default = 0 })
table.insert(ARCHIVE_KEYS, { key = "AutoAttackButtonHidden", field = "AutoAttackButtonHidden", default = 0 })

function UGCPlayerState:GetReplicatedProperties()
    return {"HunHuan", "Probability_Bonus", "RegenPercent", "HP", "YXWD_InvincibleBuff", "LotteryState", "BaseAttack",
            "BaseMaxHp", "AutoPickButtonHidden", "AutoAttackButtonHidden"}
end

-- ------ 跨对局存档 ------ --

--- 从官方存档系统加载数据到 PlayerState 各字段（chunk 1）
--- @param UID number 玩家 UID（由 GameMode 在登录时传入）
function UGCPlayerState:LoadFromArchive(UID)
    UID = tonumber(UID)
    if UID == nil or UID == 0 then
        return
    end

    self.ArchiveUID = UID

    local ArchiveData = UGCPlayerStateSystem.GetPlayerArchiveData(UID, 1)
    if ArchiveData == nil then
        return
    end

    for _, entry in ipairs(ARCHIVE_KEYS) do
        local val = ArchiveData[entry.key]
        if val ~= nil then
            -- 走 Setter 触发 CallRefreshZhanli 等副作用，同时 Setter 内会调用 SaveToArchive 写回
            local setterName = "Set" .. entry.field
            if self[setterName] then
                self[setterName](self, val)
            end
        end
    end
end

--- 将注册表中所有字段的最新值写入官方存档系统（chunk 1）
--- 自动使用 LoadFromArchive 时缓存的 UID
function UGCPlayerState:SaveToArchive()
    local UID = self.ArchiveUID
    if UID == nil or UID == 0 then
        return
    end

    local data = {}
    for _, entry in ipairs(ARCHIVE_KEYS) do
        data[entry.key] = self[entry.field] or entry.default
    end

    UGCPlayerStateSystem.SavePlayerArchiveData(UID, data, 1)
end

-- ------ 属性读写 ------ --

function UGCPlayerState:GetHunHuan()
    return self.HunHuan
end

function UGCPlayerState:SetHunHuan(value)
    self.HunHuan = value
    self:SaveToArchive()
end

function UGCPlayerState:GetRegenPercent()
    return self.RegenPercent
end

function UGCPlayerState:SetRegenPercent(value)
    self.RegenPercent = value or 5
    self:SaveToArchive()
end

function UGCPlayerState:GetHP()
    return self.HP
end

function UGCPlayerState:SetHP(value)
    self.HP = value or -1
    self:SaveToArchive()
end

---@param playerPawn userdata 玩家 Pawn
function UGCPlayerState:GetBaseAttack()
    return self.BaseAttack
end

function UGCPlayerState:SetBaseAttack(value)
    self.BaseAttack = tonumber(value) or 40
    self:SaveToArchive()
end

function UGCPlayerState:GetBaseMaxHp()
    return self.BaseMaxHp
end

function UGCPlayerState:SetBaseMaxHp(value)
    self.BaseMaxHp = tonumber(value) or 100
    self:SaveToArchive()
end

function UGCPlayerState:GetAutoPickButtonHidden()
    return tonumber(self.AutoPickButtonHidden) == 1
end

function UGCPlayerState:SetAutoPickButtonHidden(value)
    self.AutoPickButtonHidden = (value == true or tonumber(value) == 1) and 1 or 0
    self:SaveToArchive()
end

function UGCPlayerState:GetAutoAttackButtonHidden()
    return tonumber(self.AutoAttackButtonHidden) == 1
end

function UGCPlayerState:SetAutoAttackButtonHidden(value)
    self.AutoAttackButtonHidden = (value == true or tonumber(value) == 1) and 1 or 0
    self:SaveToArchive()
end

function UGCPlayerState:GetYXWD_InvincibleBuff()
    return tonumber(self.YXWD_InvincibleBuff) == 1
end

function UGCPlayerState:SetYXWD_InvincibleBuff(value)
    self.YXWD_InvincibleBuff = (value == true or tonumber(value) == 1) and 1 or 0
    if self.YXWD_InvincibleBuff == 1 then
        self.YXWD_InvincibleBuffActive = true
    end
    self:SaveToArchive()
end

function UGCPlayerState:SetYXWD_InvincibleBuffActive(value)
    self.YXWD_InvincibleBuffActive = (value == true or tonumber(value) == 1)
end

function UGCPlayerState:IsYXWDInvincibleBuffActive()
    return self.YXWD_InvincibleBuffActive == true
end

function UGCPlayerState:GetLotteryState()
    if self.LotteryState == nil then
        self.LotteryState = {}
    end
    return self.LotteryState
end

function UGCPlayerState:SetLotteryState(value)
    self.LotteryState = value or {}
    self:SaveToArchive()
end

function UGCPlayerState:SaveCurrentHP(playerPawn)
    if playerPawn == nil then
        return
    end
    local hp = UGCPawnAttrSystem.GetHealth(playerPawn)
    if hp ~= nil and hp > 0 then
        self:SetHP(hp)
    end
end

--- 将存档中的血量恢复应用到 Pawn（不会超过当前最大血量）
---@param playerPawn userdata 玩家 Pawn
function UGCPlayerState:RestoreHP(playerPawn)
    if playerPawn == nil then
        return
    end
    if self.HP == nil or self.HP <= 0 then
        return
    end

    local maxHP = UGCPawnAttrSystem.GetHealthMax(playerPawn)
    if maxHP == nil or maxHP <= 0 then
        return
    end

    local targetHP = math.min(self.HP, maxHP)
    UGCPawnAttrSystem.SetHealth(playerPawn, targetHP)
end

function UGCPlayerState:GetProbability_Bonus()
    return self.Probability_Bonus
end

function UGCPlayerState:AddProbability_Bonus(value)
    self.Probability_Bonus = math.min((self.Probability_Bonus or 0) + (value or 0), 100)

end

return UGCPlayerState
