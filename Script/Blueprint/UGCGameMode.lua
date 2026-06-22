---@class UGCGameMode_C:BP_UGCGameBase_C
--Edit Below--
local UGCGameMode = {};

-- 保存玩家死亡前的背包快照，键为 PlayerKey。
local PlayerBackpackSnapshots = {};

local function SaveBackpackSnapshot(PlayerKey, PlayerPawn)
    if not PlayerKey or not PlayerPawn then
        return
    end

    local AllItemData = UGCBackPackSystem.GetAllItemData(PlayerPawn)
    local Snapshot = {}

    if AllItemData then
        for _, ItemData in pairs(AllItemData) do
            local ItemID = tonumber(ItemData.ItemID)
            local Count = tonumber(ItemData.Count) or 0
            if ItemID and Count > 0 then
                Snapshot[ItemID] = (Snapshot[ItemID] or 0) + Count
            end
        end
    end

    PlayerBackpackSnapshots[PlayerKey] = Snapshot
    ugcprint("[UGCGameMode] Backpack saved, PlayerKey=" .. tostring(PlayerKey))
end

local function RestoreBackpackSnapshot(PlayerKey, PlayerPawn)
    local Snapshot = PlayerBackpackSnapshots[PlayerKey]
    if not Snapshot or not PlayerPawn then
        return
    end

    -- 只补回新背包中缺少的数量，防止引擎已经保留的物品被重复添加。
    for ItemID, SavedCount in pairs(Snapshot) do
        local CurrentCount = UGCBackPackSystem.GetItemCount(PlayerPawn, ItemID) or 0
        local MissingCount = SavedCount - CurrentCount
        if MissingCount > 0 then
            UGCBackPackSystem.AddItem(PlayerPawn, ItemID, MissingCount)
        end
    end

    PlayerBackpackSnapshots[PlayerKey] = nil
    ugcprint("[UGCGameMode] Backpack restored, PlayerKey=" .. tostring(PlayerKey))
end

function UGCGameMode:ReceiveBeginPlay()
    UGCGenericMessageSystem.ListenGlobalMessage(
        self,
        UGCGenericMessageSystem.Messages.UGC.PlayerPawn.PawnDefeat,
        self,
        self.OnPawnDefeat
    )
end

-- 玩家登录时发初始武器（Pawn可能还没好，等1秒）
function UGCGameMode:UGC_PlayerLoginEvent(PlayerController)
    local PC = PlayerController
    UGCTimerUtility.CreateLuaTimer(1, function()
        if PC.Pawn then
            UGCBackPackSystem.AddItem(PC.Pawn, 8310000, 1)
            UGCBackPackSystem.AddItem(PC.Pawn, 8310002, 1)
            UGCBackPackSystem.AddItem(PC.Pawn, 8310003, 1)
            UGCBackPackSystem.AddItem(PC.Pawn, 8310004, 1)
            UGCBackPackSystem.AddItem(PC.Pawn, 8310005, 1)
            UGCBackPackSystem.AddItem(PC.Pawn, 8310006, 1)
        end
    end, false)
end

-- 此事件提供死亡前的旧 Pawn，必须在这里读取背包。
function UGCGameMode:UGC_PlayerKilledEvent(Killer, VictimPlayer, VictimPawn, DamageType)
    if VictimPlayer and VictimPawn then
        SaveBackpackSnapshot(VictimPlayer.PlayerKey, VictimPawn)
    end
end

-- 新 Pawn 刚生成时背包尚未完全初始化，延迟一秒再恢复。
function UGCGameMode:UGC_PlayerRespawnEvent(RespawnedController)
    local PC = RespawnedController
    local PlayerKey = PC.PlayerKey

    UGCTimerUtility.CreateLuaTimer(1, function()
        if PC and PC.Pawn then
            RestoreBackpackSnapshot(PlayerKey, PC.Pawn)
        end
    end, false)
end


function UGCGameMode:OnPawnDefeat(VictimPlayerKey, InstigatorPlayerKey, DamageType)
    -- 某些死亡方式不会触发 UGC_PlayerKilledEvent，尝试从 Controller 再保存一次。
    if not PlayerBackpackSnapshots[VictimPlayerKey] then
        local VictimController = UGCGameSystem.GetPlayerControllerByPlayerKey(VictimPlayerKey)
        if VictimController and VictimController.Pawn then
            SaveBackpackSnapshot(VictimPlayerKey, VictimController.Pawn)
        end
    end

    UGCPlayerPawnSystem.RespawnPlayer(VictimPlayerKey, 2, true)

    -- 防止个别情况下 UGC_PlayerRespawnEvent 未回调，重生完成后再尝试恢复一次。
    UGCTimerUtility.CreateLuaTimer(3, function()
        local RespawnedController =
            UGCGameSystem.GetPlayerControllerByPlayerKey(VictimPlayerKey)
        if RespawnedController and RespawnedController.Pawn then
            RestoreBackpackSnapshot(VictimPlayerKey, RespawnedController.Pawn)
        end
    end, false)
end
return UGCGameMode; 
