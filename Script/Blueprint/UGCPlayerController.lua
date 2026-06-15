local UGCPlayerController = {}

  function UGCPlayerController:ReceiveBeginPlay()
	  end
	  function UGCPlayerController:GetAvailableServerRPCs()
	      return "Server_TeleportToSpawn", "Client_BroadcastPlantMessage"
	  end

	  local function TeleportToSpawn(self, bornPointID)
	      local pawn = self:K2_GetPawn()
	      if not pawn then return false end

	      local PlayerStartManagerComponentClass = ScriptGameplayStatics.FindClass("PlayerStartManagerComponent")
	      if PlayerStartManagerComponentClass == nil or UGCGameSystem.GameMode == nil then
	          return false
	      end

	      local PlayerStartManagerComponent = UGCGameSystem.GameMode:GetComponentByClass(PlayerStartManagerComponentClass)
	      if PlayerStartManagerComponent == nil then
	          return false
	      end

	      local PlayerStart = PlayerStartManagerComponent:FindPlayerStartByBornPointID(bornPointID, false)
	      if PlayerStart == nil then
	          return false
	      end

	      local loc = PlayerStart:K2_GetActorLocation()
	      UGCPlayerControllerSystem.TeleportTo(self, loc.X, loc.Y, loc.Z + 100)
	      return true
	  end

	  function UGCPlayerController:Server_TeleportToSpawn(bornPointID)
	      TeleportToSpawn(self, bornPointID)
	  end

function UGCPlayerController:Client_BroadcastPlantMessage(UID,level)
--[[------------------客户端收到全服通知----------------------------]]--
    UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.Test_01,UID,level)
end


return UGCPlayerController
