---@class UGCPlayerController_C:BP_UGCPlayerController_C
---@field TaskTemplateComponent TaskTemplateComponent_C
---@field GiftPackComponent GiftPackComponent_C
---@field RankingListComponent RankingListComponent_C
---@field LotteryComponent LotteryComponent_C
---@field ShopV2Component ShopV2Component_C
---@field SignInEventComponent SignInEventComponent_C
--Edit Below--
local UGCPlayerController = {}

function UGCPlayerController:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)

    -- Create UI only on the client.
    if self:HasAuthority() then
        return
    end

    -- Prevent duplicate MainUI instances.
    if self.MainUIInstance ~= nil then
        return
    end

    local MainUIPath =
        UGCMapInfoLib.GetRootLongPackagePath()
        .. "Asset/Blueprint/UI/UI02.UI02_C"
    local MainUIClass = UE.LoadClass(MainUIPath)

    if MainUIClass == nil then
        ugcprint("[UGCPlayerController] MainUI class load failed: " .. MainUIPath)
        return
    end

    self.MainUIInstance = UserWidget.NewWidgetObjectBP(self, MainUIClass)
    if self.MainUIInstance == nil then
        ugcprint("[UGCPlayerController] MainUI create failed")
        return
    end

    self.MainUIInstance:AddToViewport()
    ugcprint("[UGCPlayerController] MainUI created")
end

	  function UGCPlayerController:GetAvailableServerRPCs()
	      return "Server_TeleportToSpawn",
              "Server_UpdateRankingListScore",
              "Server_ClearAllRankingListData",
              "Client_BroadcastPlantMessage"
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

-- WBP_RankingListBtn 更新排行榜服务端--要走官方测试按钮暂时没开
function UGCPlayerController:Server_UpdateRankingListScore(UID, RankID, Score, IsIncremental)
    local RankingListGlobalActor = UGCGamePartSystem.GetGamePartGlobalActor("RankingListManager")
    if RankingListGlobalActor == nil then
        ugcprint("[UGCPlayerController:Server_UpdateRankingListScore] RankingListManager global actor is nil")
        return
    end

    local bIncremental = tonumber(IsIncremental) == 1
    RankingListGlobalActor:UpdateScore(self, tonumber(UID), tonumber(RankID), tonumber(Score), bIncremental)
end

-- 排行榜清除数据请求服务端--要走官方测试按钮暂时没开
function UGCPlayerController:Server_ClearAllRankingListData()
    local RankingListGlobalActor = UGCGamePartSystem.GetGamePartGlobalActor("RankingListManager")
    if RankingListGlobalActor == nil then
        ugcprint("[UGCPlayerController:Server_ClearAllRankingListData] RankingListManager global actor is nil")
        return
    end

    RankingListGlobalActor:PIEClearAllRankListData()
end

function UGCPlayerController:Client_BroadcastPlantMessage(UID,level)
--[[------------------客户端收到全服通知----------------------------]]--
    UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.Test_01,UID,level)
end


return UGCPlayerController
