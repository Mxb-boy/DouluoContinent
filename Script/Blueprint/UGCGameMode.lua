---@class UGCGameMode_C:BP_UGCGameBase_C
--Edit Below--
local UGCGameMode = {};

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
            UGCBackPackSystem.AddItem(PC.Pawn, 831602104, 1)
            --UGCBackPackSystem.AddItem(PC.Pawn, 301001, 90)
        end
    end, false)
end

-- 玩家重生时发武器
function UGCGameMode:UGC_PlayerRespawnEvent(RespawnedController)
    if RespawnedController.Pawn then
        UGCBackPackSystem.AddItem(RespawnedController.Pawn, 831602104, 1)
        --UGCBackPackSystem.AddItem(RespawnedController.Pawn, 301001, 90)
    end
end

function UGCGameMode:OnPawnDefeat(VictimPlayerKey, InstigatorPlayerKey, DamageType)
    UGCPlayerPawnSystem.RespawnPlayer(VictimPlayerKey, 2, true)
end
return UGCGameMode;