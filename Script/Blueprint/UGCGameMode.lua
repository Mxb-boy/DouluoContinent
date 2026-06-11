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

function UGCGameMode:OnPawnDefeat(VictimPlayerKey, InstigatorPlayerKey, DamageType)
    UGCPlayerPawnSystem.RespawnPlayer(VictimPlayerKey, 2, true)
end
return UGCGameMode;