---@class UGCPlayerController_C:BP_UGCPlayerController_C
---@field TaskTemplateComponent TaskTemplateComponent_C
---@field GiftPackComponent GiftPackComponent_C
---@field RankingListComponent RankingListComponent_C
---@field LotteryComponent LotteryComponent_C
---@field ShopV2Component ShopV2Component_C
---@field SignInEventComponent SignInEventComponent_C
--Edit Below--
local UGCPlayerController = {}
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local TitleSystem = UGCGameSystem.UGCRequire("Script.Blueprint.Title.TitleSystem")

local ForgeMaterialItemIDs = {
    HGRJ = 8310035,
    QNHH = 8310036,
}

function UGCPlayerController:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    --删去风向标
    UGCWidgetManagerSystem.GetMainControlUI().NavigatorPanel:SetVisibility(ESlateVisibility.Collapsed)
    UGCWidgetManagerSystem.GetMainControlUI().Image_0:SetVisibility(ESlateVisibility.Collapsed)

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

    local FeiUIPath =
        UGCMapInfoLib.GetRootLongPackagePath()
        .. "Asset/Blueprint/UI/Fei.Fei_C"
    local FeiUIClass = UE.LoadClass(FeiUIPath)

    if FeiUIClass == nil then
        ugcprint("[UGCPlayerController] Fei UI class load failed: " .. FeiUIPath)
        return
    end

    self.FeiUIInstance = UserWidget.NewWidgetObjectBP(self, FeiUIClass)
    if self.FeiUIInstance == nil then
        ugcprint("[UGCPlayerController] Fei UI create failed")
        return
    end

    self.FeiUIInstance:AddToViewport()
    ugcprint("[UGCPlayerController] Fei UI created")
end

	  function UGCPlayerController:GetAvailableServerRPCs()
	      return "Server_TeleportToSpawn",
              "Server_UpdateRankingListScore",
              "Server_ClearAllRankingListData",
              "Client_BroadcastPlantMessage",
              "Client_ForgeWeaponResult",
              "Server_ForgeWeapon",
              "Server_EquipTitle",
              "Server_BeginFlyState",
              "Server_EndFlyState",
              "Server_FlyMove",
              "Server_StopFlyMove"
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
function UGCPlayerController:Server_BeginFlyState()
    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.BeginFly == nil then
        return
    end

    pawn:BeginFly()
end

function UGCPlayerController:Server_EndFlyState()
    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.EndFly == nil then
        return
    end

    pawn:EndFly()
end

local FLY_SPEED = 3600

function UGCPlayerController:Server_FlyMove(DirX, DirY, DirZ, DeltaTime)
    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.K2_GetActorLocation == nil or pawn.K2_SetActorLocation == nil then
        return
    end

    local MovementComponent = pawn.CharacterMovement or pawn.MovementComponent
    if MovementComponent ~= nil then
        if MovementComponent.SetMovementMode ~= nil then
            pcall(MovementComponent.SetMovementMode, MovementComponent, 5)
        end
        if MovementComponent.GravityScale ~= nil then
            MovementComponent.GravityScale = 0
        end
        if MovementComponent.Velocity ~= nil then
            MovementComponent.Velocity = Vector.New(0, 0, 0)
        end
    end

    DirX = tonumber(DirX) or 0
    DirY = tonumber(DirY) or 0
    DirZ = tonumber(DirZ) or 0
    DeltaTime = tonumber(DeltaTime) or 0.016

    if DeltaTime <= 0 or DeltaTime > 0.1 then
        DeltaTime = 0.016
    end

    local Length = math.sqrt(DirX * DirX + DirY * DirY + DirZ * DirZ)
    if Length <= 0.01 then
        return
    end

    DirX = DirX / Length
    DirY = DirY / Length
    DirZ = DirZ / Length

    local Location = pawn:K2_GetActorLocation()
    if Location == nil then
        return
    end

    local Distance = FLY_SPEED * DeltaTime
    local NewLocation = Vector.New(
        Location.X + DirX * Distance,
        Location.Y + DirY * Distance,
        Location.Z + DirZ * Distance
    )

    pawn:K2_SetActorLocation(NewLocation, true, nil, true)
end

function UGCPlayerController:Server_StopFlyMove()
    local pawn = self:K2_GetPawn()
    if pawn == nil then
        return
    end

    local MovementComponent = pawn.CharacterMovement or pawn.MovementComponent
    if MovementComponent == nil then
        return
    end

    if MovementComponent.GravityScale ~= nil then
        MovementComponent.GravityScale = 1
    end
    if MovementComponent.Velocity ~= nil then
        MovementComponent.Velocity = Vector.New(0, 0, 0)
    end
    if MovementComponent.SetMovementMode ~= nil then
        pcall(MovementComponent.SetMovementMode, MovementComponent, 1)
    end
end

local function GetVirtualItemManager()
    if UGCGamePartSystem ~= nil
        and UGCGamePartSystem.IsGamePartLoaded ~= nil
        and UGCGamePartSystem.IsGamePartLoaded("VirtualItemManager")
    then
        return UGCGamePartSystem.GetGamePartGlobalActor("VirtualItemManager")
    end

    if UGCBlueprintFunctionLibrary ~= nil and UGCGameSystem.GameState ~= nil then
        return UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager")
    end

    return nil
end

local function GetPlayerPawn(PlayerController)
    if PlayerController.Pawn ~= nil then
        return PlayerController.Pawn
    end
    if PlayerController.K2_GetPawn ~= nil then
        return PlayerController:K2_GetPawn()
    end
    return nil
end

local function GetItemCount(PlayerController, ItemID)
    local BackpackCount = 0
    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackPackSystem ~= nil and UGCBackPackSystem.GetItemCount ~= nil then
        BackpackCount = tonumber(UGCBackPackSystem.GetItemCount(Pawn, ItemID)) or 0
    end

    local VirtualCount = 0
    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil and VirtualItemManager.GetItemNum ~= nil then
        local Success, Result = pcall(VirtualItemManager.GetItemNum, VirtualItemManager, ItemID, PlayerController)
        if Success and Result ~= nil then
            VirtualCount = tonumber(Result) or 0
        end
    end

    if BackpackCount > VirtualCount then
        return BackpackCount
    end

    return VirtualCount
end

local function AddItem(PlayerController, ItemID, Count)
    Count = tonumber(Count) or 0
    if Count <= 0 then
        return true
    end

    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackPackSystem ~= nil and UGCBackPackSystem.AddItem ~= nil then
        local Success, Result = pcall(UGCBackPackSystem.AddItem, Pawn, ItemID, Count)
        if Success and Result ~= false then
            return true
        end
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil and VirtualItemManager.AddVirtualItem ~= nil then
        local Success, Result = pcall(VirtualItemManager.AddVirtualItem, VirtualItemManager, PlayerController, ItemID, Count)
        if Success and Result ~= false then
            return true
        end
    end

    return false
end

local function RemoveItem(PlayerController, ItemID, Count)
    Count = tonumber(Count) or 0
    if Count <= 0 then
        return true
    end

    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackPackSystem ~= nil then
        local FunctionNames = { "RemoveItem", "RemoveItemByItemID", "DeleteItem", "SubItem" }
        for _, FunctionName in ipairs(FunctionNames) do
            local Func = UGCBackPackSystem[FunctionName]
            if Func ~= nil then
                local Success, Result = pcall(Func, Pawn, ItemID, Count)
                if Success and Result ~= false then
                    return true
                end
            end
        end

        if UGCBackPackSystem.AddItem ~= nil then
            local Success = pcall(UGCBackPackSystem.AddItem, Pawn, ItemID, -Count)
            if Success then
                return true
            end
        end
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil then
        local VirtualCount = 0
        if VirtualItemManager.GetItemNum ~= nil then
            local CountSuccess, CountResult =
                pcall(VirtualItemManager.GetItemNum, VirtualItemManager, ItemID, PlayerController)
            if CountSuccess then
                VirtualCount = tonumber(CountResult) or 0
            end
        end

        local Func = VirtualItemManager.RemoveVirtualItem or VirtualItemManager.RemoveItem
        if Func ~= nil and VirtualCount >= Count then
            local Success, Result = pcall(Func, VirtualItemManager, PlayerController, ItemID, Count)
            if Success and Result ~= false then
                return true
            end
        end
    end

    return false
end

function UGCPlayerController:Server_ForgeWeapon(ItemID)
    ItemID = tonumber(ItemID)
    local Cost = WeaponLevelConfig.GetForgeCost(ItemID)
    if ItemID == nil or Cost == nil then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Invalid item: " .. tostring(ItemID))
        return
    end

    if GetItemCount(self, ItemID) <= 0 then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Weapon not found: " .. tostring(ItemID))
        return
    end

    if GetItemCount(self, ForgeMaterialItemIDs.HGRJ) < (Cost.HGRJ or 0)
        or GetItemCount(self, ForgeMaterialItemIDs.QNHH) < (Cost.QNHH or 0)
    then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Material not enough")
        return
    end

    local ResultType = WeaponLevelConfig.RollForgeResult(ItemID)
    local ResultItemID = WeaponLevelConfig.GetResultItemID(ItemID, ResultType)

    if not RemoveItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0) then
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove HGRJ failed")
        return
    end
    if not RemoveItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0) then
        AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
        ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove QNHH failed")
        return
    end

    if ResultItemID ~= ItemID then
        if not RemoveItem(self, ItemID, 1) then
            AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
            AddItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0)
            ugcprint("[UGCPlayerController:Server_ForgeWeapon] Remove old weapon failed")
            return
        end
        if not AddItem(self, ResultItemID, 1) then
            AddItem(self, ItemID, 1)
            AddItem(self, ForgeMaterialItemIDs.HGRJ, Cost.HGRJ or 0)
            AddItem(self, ForgeMaterialItemIDs.QNHH, Cost.QNHH or 0)
            ugcprint("[UGCPlayerController:Server_ForgeWeapon] Add new weapon failed")
            return
        end
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_ForgeWeaponResult", ResultType, ItemID, ResultItemID)

    ugcprint("[UGCPlayerController:Server_ForgeWeapon] result=" .. tostring(ResultType)
        .. ", from=" .. tostring(ItemID) .. ", to=" .. tostring(ResultItemID))
end

function UGCPlayerController:Client_ForgeWeaponResult(ResultType, OldItemID, ResultItemID)
    if self.MainUIInstance == nil or self.MainUIInstance.UI10Instance == nil then
        ugcprint("[UGCPlayerController:Client_ForgeWeaponResult] UI10 instance is nil")
        return
    end

    local UI10Instance = self.MainUIInstance.UI10Instance
    if UI10Instance.OnForgeWeaponResult ~= nil then
        UI10Instance:OnForgeWeaponResult(ResultType, OldItemID, ResultItemID)
    end
end

--装备相关
function UGCPlayerController:Server_EquipTitle(titleID)
    titleID = tonumber(titleID) or 0

    if titleID < 1 or titleID > 15 then
        return
    end

    local pawn = self:K2_GetPawn()
    if pawn == nil then
        return
    end

    local oldTitleID = pawn.EquippedTitleID or 0

    if oldTitleID == titleID then
        return
    end

    pawn.EquippedTitleID = titleID

    -- 刷新头顶称号
    local titleActor = pawn.PlayerTitleActor
    if (titleActor == nil or not UE.IsValid(titleActor))
        and pawn.EnsurePlayerTitleActor ~= nil then
        titleActor = pawn:EnsurePlayerTitleActor()
    end

    if titleActor and UE.IsValid(titleActor) and titleActor.SetTitle then
        titleActor:SetTitle(titleID)
    end

    -- 预留属性
    TitleSystem:ApplyTitleBonus(self, oldTitleID, titleID)
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
