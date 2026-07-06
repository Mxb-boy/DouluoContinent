--[[-------------------这里放角色状态，重连后可以恢复数据---------------------------]] --
local UGCPlayerState = {
    HunHuan = 1, -- 大魂环
    Probability_Bonus = 100, -- 掉落倍率
    RegenPercent = 5, -- 战场回血：每秒恢复百分比（默认5%）
    HP = -1, -- 上一次离场时保存的血量，-1 表示从未存档
    -- 跨对局存档: 被 SaveToArchive 消费
    YXWD_InvincibleBuff = 0,
    YXWD_InvincibleBuffActive = false,
    YXWD_InvincibleBuffToken = 0,
    LotteryState = {},
    UnlockedTitles = {},
    EquippedTitleID = 0,
    AutoPickButtonHidden = 0,
    AutoAttackButtonHidden = 0,
    FeiButton0Hidden = 0,
    ArchiveUID = nil,
    bArchiveLoaded = false, -- 服务器侧标志：LoadFromArchive 成功后置 true

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
table.insert(ARCHIVE_KEYS, { key = "UnlockedTitles", field = "UnlockedTitles", default = {} })
table.insert(ARCHIVE_KEYS, { key = "EquippedTitleID", field = "EquippedTitleID", default = 0 })
table.insert(ARCHIVE_KEYS, { key = "Probability_Bonus", field = "Probability_Bonus", default = 100 })

function UGCPlayerState:GetReplicatedProperties()
    return {"HunHuan", "Probability_Bonus", "RegenPercent", "HP", "YXWD_InvincibleBuff", "LotteryState", "BaseAttack",
            "BaseMaxHp", "AutoPickButtonHidden", "AutoAttackButtonHidden", "UnlockedTitles", "EquippedTitleID", "FeiButton0Hidden"}
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
    self.bArchiveLoaded = true

    local ArchiveData = UGCPlayerStateSystem.GetPlayerArchiveData(UID, 1)
    if ArchiveData == nil then
        return
    end

    -- 加载过程中锁定 SaveToArchive，防止 Setter 中尚未还原的字段默认值被写入存档造成数据损坏
    self.bLoadingArchive = true

    for _, entry in ipairs(ARCHIVE_KEYS) do
        local val = ArchiveData[entry.key]
        if val ~= nil then
            local setterName = "Set" .. entry.field
            if self[setterName] then
                -- pcall 保护：单个 Setter 失败不影响其他字段加载，且确保锁一定能释放
                local ok, err = pcall(self[setterName], self, val)
                if not ok then
                    print(string.format("[UGCPlayerState] LoadFromArchive: %s failed for key %s: %s",
                        setterName, entry.key, tostring(err)))
                end
            end
        end
    end

    -- 无论循环中是否出错，都必须释放锁，否则后续所有 SaveToArchive 会被永久拦截
    self.bLoadingArchive = false
    self:SaveToArchive()
end

--- 将注册表中所有字段的最新值写入官方存档系统（chunk 1）
--- 自动使用 LoadFromArchive 时缓存的 UID
function UGCPlayerState:SaveToArchive()
    -- 加载存档期间禁止写入，防止 Setter 将尚未还原的字段默认值写入存档，导致数据损坏
    if self.bLoadingArchive then
        return
    end

    local UID = self.ArchiveUID
    if UID == nil or UID == 0 then
        return
    end

    local data = {}
    for _, entry in ipairs(ARCHIVE_KEYS) do
        -- 显式 nil 检查，避免 `or` 将合法的 false 值误覆盖为默认值
        local v = self[entry.field]
        if v == nil then
            v = entry.default
        end
        data[entry.key] = v
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

function UGCPlayerState:GetFeiButton0Hidden()
    return tonumber(self.FeiButton0Hidden) == 1
end

function UGCPlayerState:SetFeiButton0Hidden(value)
    self.FeiButton0Hidden = (value == true or tonumber(value) == 1) and 1 or 0
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
    -- 浅拷贝断开与存档系统内部 table 的引用，避免后续修改影响存档缓存
    if type(value) == "table" then
        local copy = {}
        for k, v in pairs(value) do
            copy[k] = v
        end
        self.LotteryState = copy
    else
        self.LotteryState = {}
    end
    self:SaveToArchive()
end

function UGCPlayerState:GetUnlockedTitles()
    self.UnlockedTitles = self.UnlockedTitles or {}
    return self.UnlockedTitles
end

function UGCPlayerState:SetUnlockedTitles(value)
    -- 浅拷贝断开引用
    if type(value) == "table" then
        local copy = {}
        for k, v in pairs(value) do
            copy[k] = v
        end
        self.UnlockedTitles = copy
    else
        self.UnlockedTitles = {}
    end
    self:SaveToArchive()
end

function UGCPlayerState:IsTitleUnlocked(titleID)
    titleID = tonumber(titleID) or 0
    local unlockedTitles = self:GetUnlockedTitles()
    return unlockedTitles[titleID] == true or unlockedTitles[tostring(titleID)] == true
end

function UGCPlayerState:SetTitleUnlocked(titleID)
    titleID = tonumber(titleID) or 0
    if titleID < 1 then
        return
    end

    local unlockedTitles = self:GetUnlockedTitles()
    unlockedTitles[titleID] = true
    self:SetUnlockedTitles(unlockedTitles)
end

function UGCPlayerState:GetEquippedTitleID()
    return tonumber(self.EquippedTitleID) or 0
end

function UGCPlayerState:SetEquippedTitleID(value)
    self.EquippedTitleID = tonumber(value) or 0
    self:SaveToArchive()
end

function UGCPlayerState:SaveCurrentHP(playerPawn)
    if playerPawn == nil then
        return
    end
    if not self.bArchiveLoaded then
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
    return tonumber(self.Probability_Bonus) or 100
end

function UGCPlayerState:SetProbability_Bonus(value)
    self.Probability_Bonus = tonumber(value) or 100
    self:SaveToArchive()
end

return UGCPlayerState
