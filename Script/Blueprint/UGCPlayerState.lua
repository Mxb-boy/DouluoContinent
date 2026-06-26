--[[-------------------这里放角色状态，重连后可以恢复数据---------------------------]]--
local UGCPlayerState = {
    HunHuan=1,--大魂环
    HunHuan_Little=1,--小等级

    -- 跨对局存档: 被 SaveToArchive 消费
    ArchiveUID=nil,
}

-- ============================================================
-- 跨对局存档注册表（chunk 1）
-- 新增持久化数据只需在下面加一行即可：
--   { key = "存档键名", field = "PlayerState 字段名", default = 默认值 }
-- ============================================================
local ARCHIVE_KEYS = {
    { key = "HunHuan", field = "HunHuan", default = 1 },
    { key = "HunHuan_Little", field = "HunHuan_Little", default = 1 },
    -- 示例: { key = "Gold",    field = "Gold",    default = 0 },
}

function UGCPlayerState:GetReplicatedProperties()
    return {
        "HunHuan",
        "HunHuan_Little",
    }
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

function UGCPlayerState:GetHunHuan_Little()
    return self.HunHuan_Little
end

function UGCPlayerState:SetHunHuan(value)
     self.HunHuan=value
    self:CallRefreshZhanli()
    self:SaveToArchive()
end

function UGCPlayerState:SetHunHuan_Little(value)
     self.HunHuan_Little=value
    self:CallRefreshZhanli()
    self:SaveToArchive()
end

function  UGCPlayerState:CallRefreshZhanli()
    local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if playerPawn ~= nil then
        UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(playerPawn, L_Enum_Event.Enum.ReFreshZhanLi_01)
    end
end


return UGCPlayerState
