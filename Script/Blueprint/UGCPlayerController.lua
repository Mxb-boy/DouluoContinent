local UGCPlayerController = {}
 local L_Event = UGCGameSystem.UGCRequire('Script.Lin.L_Event')

  function UGCPlayerController:ReceiveBeginPlay()
	      L_Event:AddListener("OnStartPoint", self.OnStartPoint, self)
	  end

	  function UGCPlayerController:GetAvailableServerRPCs()
	      return "Server_TeleportToSpawn"
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

	   function UGCPlayerController:OnStartPoint(bornPointID)
	      if self.HasAuthority ~= nil and self:HasAuthority() == false then
	          UnrealNetwork.CallUnrealRPC(self, self, "Server_TeleportToSpawn", bornPointID)
	          return
	      end

	      TeleportToSpawn(self, bornPointID)
	  end


	  function UGCPlayerController:Server_TeleportToSpawn(bornPointID)
	      TeleportToSpawn(self, bornPointID)
	  end




return UGCPlayerController