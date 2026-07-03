---@class UGCPlayerController_C:BP_UGCPlayerController_C
---@field TaskTemplateComponent TaskTemplateComponent_C
---@field GiftPackComponent GiftPackComponent_C
---@field RankingListComponent RankingListComponent_C
---@field LotteryComponent LotteryComponent_C
---@field ShopV2Component ShopV2Component_C
---@field SignInEventComponent SignInEventComponent_C
-- Edit Below--
local UGCPlayerController = {}
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local RealmConfig = UGCGameSystem.UGCRequire("Script.Common.RealmConfig")
local LotteryConfig = UGCGameSystem.UGCRequire("Script.Common.LotteryConfig")
local TitleSystem = UGCGameSystem.UGCRequire("Script.Blueprint.Title.TitleSystem")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")
local L_Enum_Event = UGCGameSystem.UGCRequire("Script.Lin.L_Enum_Event")
local ForgeMaterialItemIDs = {
    HGRJ = 8310035,
    QNHH = 8310036
}

function UGCPlayerController:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)

    -- 注册补偿系统委托
    self:RegisterCompensationDelegates()

    -- 删去风向标
    local MainUI = UGCWidgetManagerSystem.GetMainControlUI()
    if MainUI then
        MainUI.NavigatorPanel:SetVisibility(ESlateVisibility.Collapsed)
        MainUI.Image_0:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- Create UI only on the client.
    if self:HasAuthority() then
        return
    end

    -- Prevent duplicate MainUI instances.
    if self.MainUIInstance ~= nil then
        return
    end

    local MainUIPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/UI02.UI02_C"
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

    local FeiUIPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/Fei.Fei_C"
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
    return "Server_TeleportToSpawn", "Server_TeleportToLocation", "Server_UpdateRankingListScore",
        "Server_ClearAllRankingListData", "Client_BroadcastPlantMessage", "Client_ForgeWeaponResult",
        "Server_ForgeWeapon", "Server_AddShopItemToBackpackV2", "Server_EquipTitle", "Server_BeginFlyState",
        "Server_EndFlyState", "Server_FlyMove", "Server_StopFlyMove", "Server_UpdateWeaponAttackBonus",
        "Server_AddProbabilityBonus", "Client_ProbabilityBonusChanged", "Client_BreakRealmResult", "Server_BreakRealm",
        "Server_SetAutoPickEnabled", "Client_YXWDInvincibleBuffChanged", "Server_SetYXWDInvincibleBuffActive",
        "Client_YXWDInvincibleActiveChanged", "Server_RequestLottery", "Client_LotteryResult", "Client_RefreshProperty",
        "Server_SetFinalMaxHp", "Server_SetFinalAttack"
end

local function TeleportToSpawn(self, bornPointID)
    local pawn = self:K2_GetPawn()
    if not pawn then
        return false
    end

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

--- 传送玩家到指定坐标
---@param x number
---@param y number
---@param z number
function UGCPlayerController:Server_TeleportToLocation(x, y, z)
    UGCPlayerControllerSystem.TeleportTo(self, x, y, z)
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
    local NewLocation = Vector.New(Location.X + DirX * Distance, Location.Y + DirY * Distance,
        Location.Z + DirZ * Distance)

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

function UGCPlayerController:Server_UpdateWeaponAttackBonus(ItemID)
    ItemID = tonumber(ItemID)
    if WeaponLevelConfig.GetWeaponInfo(ItemID) == nil then
        return
    end

    local pawn = self:K2_GetPawn()
    if pawn == nil or pawn.ApplyWeaponAttackBonusByItemID == nil then
        return
    end

    pawn:ApplyWeaponAttackBonusByItemID(ItemID, nil, nil, nil, false)
end

local function GetVirtualItemManager()
    if UGCGamePartSystem ~= nil and UGCGamePartSystem.IsGamePartLoaded ~= nil and
        UGCGamePartSystem.IsGamePartLoaded("VirtualItemManager") then
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
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        BackpackCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(Pawn, ItemID)) or 0
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
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.AddItemV2 ~= nil then
        local Success, Result = pcall(UGCBackpackSystemV2.AddItemV2, Pawn, ItemID, Count)
        print("[ShopV2:SERVER] BackpackV2 path: OK=" .. tostring(Success) .. " Result=" .. tostring(Result))
        if Success and Result ~= false and Result ~= 0 then
            if WeaponLevelConfig.GetWeaponInfo(ItemID) ~= nil and Pawn.RefreshWeaponAttackBonus ~= nil then
                Pawn:RefreshWeaponAttackBonus(true)
                if Pawn.ForceRefreshPropertySnapshot ~= nil then
                    Pawn:ForceRefreshPropertySnapshot()
                end
            end
            return true
        end
    else
        print("[ShopV2:SERVER] BackpackV2 path: UNAVAILABLE (Pawn=" .. tostring(Pawn) .. " BPS=" ..
                  tostring(UGCBackpackSystemV2) .. ")")
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil and VirtualItemManager.AddVirtualItem ~= nil then
        local Success, Result = pcall(VirtualItemManager.AddVirtualItem, VirtualItemManager, PlayerController, ItemID,
            Count)
        print("[ShopV2:SERVER] Virtual path: OK=" .. tostring(Success) .. " Result=" .. tostring(Result))
        if Success and Result ~= false then
            if Pawn ~= nil and WeaponLevelConfig.GetWeaponInfo(ItemID) ~= nil and Pawn.RefreshWeaponAttackBonus ~= nil then
                Pawn:RefreshWeaponAttackBonus(true)
                if Pawn.ForceRefreshPropertySnapshot ~= nil then
                    Pawn:ForceRefreshPropertySnapshot()
                end
            end
            return true
        end
    end

    print("[ShopV2:SERVER] All paths FAILED")
    return false
end

local function RemoveItem(PlayerController, ItemID, Count)
    Count = tonumber(Count) or 0
    if Count <= 0 then
        return true
    end

    local Pawn = GetPlayerPawn(PlayerController)
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.RemoveItemV2 ~= nil then
        local Success, Result = pcall(UGCBackpackSystemV2.RemoveItemV2, Pawn, ItemID, Count)
            if Success and Result ~= false and Result ~= 0 then
            return true
        end
    end

    local VirtualItemManager = GetVirtualItemManager()
    if VirtualItemManager ~= nil then
        local VirtualCount = 0
        if VirtualItemManager.GetItemNum ~= nil then
            local CountSuccess, CountResult = pcall(VirtualItemManager.GetItemNum, VirtualItemManager, ItemID,
                PlayerController)
            if CountSuccess then
                VirtualCount = tonumber(CountResult) or 0
            end
        end

        local Func = VirtualItemManager.RemoveVirtualItem or VirtualItemManager.RemoveItem
        if Func ~= nil and VirtualCount >= Count then
            local Success, Result = pcall(Func, VirtualItemManager, PlayerController, ItemID, Count)
            if Success and Result ~= false and Result ~= 0 then
                return true
            end
        end
    end

    return false
end

--- 商城购买后通过 V2 API 把物品加到背包，并清理虚拟物品（必须在服务端执行）
---@param BackpackItemID number 背包物品ID
---@param Num number 数量
---@param VirtualItemID number 源虚拟物品ID（用于清理）
function UGCPlayerController:Server_AddShopItemToBackpackV2(BackpackItemID, Num, VirtualItemID)
    BackpackItemID = tonumber(BackpackItemID)
    Num = tonumber(Num) or 1
    VirtualItemID = tonumber(VirtualItemID)
    if BackpackItemID == nil or Num <= 0 then
        print("[ShopV2:SERVER] Invalid params: " .. tostring(BackpackItemID) .. " x " .. tostring(Num))
        return
    end
    local PlayerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(self)
    if PlayerPawn == nil then
        print("[ShopV2:SERVER] PlayerPawn nil")
        return
    end
    local before = UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, BackpackItemID)
    print("[ShopV2:SERVER] BEFORE AddItemV2: ItemID=" .. tostring(BackpackItemID) .. " count=" .. tostring(before))
    local ret = UGCBackpackSystemV2.AddItemV2(PlayerPawn, BackpackItemID, Num)
    local after = UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, BackpackItemID)
    print("[ShopV2:SERVER] AFTER AddItemV2: ret=" .. tostring(ret) .. " count=" .. tostring(after))

    -- BugFix: 返回值为 0 表示添加失败（如背包满）
    if ret == 0 then
        print("[ShopV2:SERVER] AddItemV2 FAILED (ret=0), keeping virtual item as fallback")
        return
    end

    -- AddItemV2 成功后，在服务端清理源虚拟物品（避免客户端调用 RemoveVirtualItem 无效）
    if VirtualItemID ~= nil then
        local VirtualItemManager = UGCGamePartSystem.GetGamePartGlobalActor("VirtualItemManager")
        if VirtualItemManager then
            local rmOK, rmErr =
                pcall(VirtualItemManager.RemoveVirtualItem, VirtualItemManager, self, VirtualItemID, Num)
            print("[ShopV2:SERVER] RemoveVirtualItem(VItemID=" .. tostring(VirtualItemID) .. " x " .. tostring(Num) ..
                      ") ok=" .. tostring(rmOK) .. " err=" .. tostring(rmErr))
        end
    end
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

    if GetItemCount(self, ForgeMaterialItemIDs.HGRJ) < (Cost.HGRJ or 0) or GetItemCount(self, ForgeMaterialItemIDs.QNHH) <
        (Cost.QNHH or 0) then
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

    ugcprint(
        "[UGCPlayerController:Server_ForgeWeapon] result=" .. tostring(ResultType) .. ", from=" .. tostring(ItemID) ..
            ", to=" .. tostring(ResultItemID))
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

    local Pawn = GetPlayerPawn(self)
    if Pawn ~= nil and Pawn.RefreshWeaponAttackBonus ~= nil then
        Pawn:RefreshWeaponAttackBonus(true)
        if Pawn.ForceRefreshPropertySnapshot ~= nil then
            Pawn:ForceRefreshPropertySnapshot()
        end
    end
end
-- 突破
local function GetRealmLevel(PlayerController)
    return tonumber(PlayerController.RealmLevel) or 1
end

local function SetRealmLevel(PlayerController, Level)
    PlayerController.RealmLevel = math.max(1, math.min(RealmConfig.MaxLevel, tonumber(Level) or 1))
end

local function GetRealmFailCount(PlayerController, Level)
    PlayerController.RealmFailCounts = PlayerController.RealmFailCounts or {}
    return tonumber(PlayerController.RealmFailCounts[Level]) or 0
end

local function SetRealmFailCount(PlayerController, Level, Count)
    PlayerController.RealmFailCounts = PlayerController.RealmFailCounts or {}
    PlayerController.RealmFailCounts[Level] = math.max(0, tonumber(Count) or 0)
end

local function HasRealmNeedItems(PlayerController, Config)
    for _, Item in ipairs(Config.NeedItems or {}) do
        local ItemID = tonumber(Item.ItemID)
        local NeedCount = tonumber(Item.Count) or 0
        if ItemID ~= nil and GetItemCount(PlayerController, ItemID) < NeedCount then
            return false, Item
        end
    end

    return true, nil
end

local function RemoveRealmNeedItems(PlayerController, Config)
    local RemovedItems = {}
    for _, Item in ipairs(Config.NeedItems or {}) do
        local ItemID = tonumber(Item.ItemID)
        local NeedCount = tonumber(Item.Count) or 0
        if ItemID ~= nil and NeedCount > 0 then
            if not RemoveItem(PlayerController, ItemID, NeedCount) then
                for _, RemovedItem in ipairs(RemovedItems) do
                    AddItem(PlayerController, RemovedItem.ItemID, RemovedItem.Count)
                end
                return false, Item
            end

            table.insert(RemovedItems, {
                ItemID = ItemID,
                Count = NeedCount
            })
        end
    end

    return true, nil
end

function UGCPlayerController:Server_BreakRealm(TargetLevel)
    TargetLevel = tonumber(TargetLevel)
    local CurrentLevel = GetRealmLevel(self)
    local ExpectedLevel = CurrentLevel + 1

    if TargetLevel ~= ExpectedLevel or TargetLevel == nil or TargetLevel > RealmConfig.MaxLevel then
        ugcprint("[UGCPlayerController:Server_BreakRealm] invalid target=" .. tostring(TargetLevel) .. ", current=" ..
                     tostring(CurrentLevel))
        return
    end

    local Config = RealmConfig.Get(TargetLevel)
    if Config == nil then
        return
    end

    local FailCount = GetRealmFailCount(self, TargetLevel)
    local HasItems, MissingItem = HasRealmNeedItems(self, Config)
    if not HasItems then
        ugcprint("[UGCPlayerController:Server_BreakRealm] item not enough: " ..
                     tostring(MissingItem and MissingItem.Name or "nil") .. ", target=" .. tostring(TargetLevel))
        UnrealNetwork.CallUnrealRPC(self, self, "Client_BreakRealmResult", false, CurrentLevel, TargetLevel, FailCount,
            0, false)
        return
    end

    local RemoveSuccess, RemoveFailedItem = RemoveRealmNeedItems(self, Config)
    if not RemoveSuccess then
        ugcprint("[UGCPlayerController:Server_BreakRealm] remove item failed: " ..
                     tostring(RemoveFailedItem and RemoveFailedItem.Name or "nil") .. ", target=" ..
                     tostring(TargetLevel))
        UnrealNetwork.CallUnrealRPC(self, self, "Client_BreakRealmResult", false, CurrentLevel, TargetLevel, FailCount,
            0, false)
        return
    end

    local Success, IsGuaranteed, UsedRate = RealmConfig.RollBreakResult(TargetLevel, FailCount, 0)
    local NewLevel = CurrentLevel

    if Success then
        NewLevel = TargetLevel
        SetRealmLevel(self, NewLevel)
        SetRealmFailCount(self, TargetLevel, 0)

        local PlayerPawn = self:K2_GetPawn()
        local PlayerState = PlayerPawn and PlayerPawn.PlayerState
        if PlayerState ~= nil and PlayerState.SetHunHuan ~= nil then
            PlayerState:SetHunHuan(NewLevel)
        end
        if PlayerPawn ~= nil and PlayerPawn.RefreshSoulMesh ~= nil then
            PlayerPawn:RefreshSoulMesh(NewLevel, true)
        end
    else
        FailCount = FailCount + 1
        SetRealmFailCount(self, TargetLevel, FailCount)
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_BreakRealmResult", Success, NewLevel, TargetLevel, FailCount,
        UsedRate, IsGuaranteed)

    ugcprint("[UGCPlayerController:Server_BreakRealm] target=" .. tostring(TargetLevel) .. ", success=" ..
                 tostring(Success) .. ", rate=" .. tostring(UsedRate) .. ", guaranteed=" .. tostring(IsGuaranteed) ..
                 ", failCount=" .. tostring(FailCount))
end

function UGCPlayerController:Client_BreakRealmResult(Success, NewLevel, TargetLevel, FailCount, UsedRate, IsGuaranteed)
    self.RealmLevel = tonumber(NewLevel) or self.RealmLevel

    if Success then
        local PlayerPawn = self:K2_GetPawn()
        if PlayerPawn ~= nil and PlayerPawn.RefreshSoulMesh ~= nil then
            PlayerPawn:RefreshSoulMesh(NewLevel)
        end
    end

    if self.MainUIInstance ~= nil and self.MainUIInstance.RefreshRealmNameText ~= nil then
        self.MainUIInstance:RefreshRealmNameText()
    end

    if self.MainUIInstance == nil or self.MainUIInstance.UI08Instance == nil then
        ugcprint("[UGCPlayerController:Client_BreakRealmResult] UI08 instance is nil")
        return
    end

    local UI08Instance = self.MainUIInstance.UI08Instance
    if UI08Instance.OnRealmBreakResult ~= nil then
        UI08Instance:OnRealmBreakResult(Success, NewLevel, TargetLevel, FailCount, UsedRate, IsGuaranteed)
    elseif UI08Instance.OnRealmLevelChanged ~= nil then
        UI08Instance:OnRealmLevelChanged(NewLevel)
    end
end

-- 装备相关
-- Lottery
local function GetLotteryState(PlayerController, LotteryType)
    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil then
        return nil
    end

    local State = PlayerState.GetLotteryState and PlayerState:GetLotteryState() or PlayerState.LotteryState
    if State == nil then
        State = {}
        PlayerState.LotteryState = State
    end

    local Key = tostring(LotteryType)
    if State[Key] == nil then
        State[Key] = {
            Round = 0,
            Completed = false,
            OwnedAwards = {},
            GrandPrize = false
        }
    end

    State[Key].OwnedAwards = State[Key].OwnedAwards or {}
    return State[Key], State
end

local function SaveLotteryState(PlayerController, State)
    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil then
        return
    end

    if PlayerState.SetLotteryState ~= nil then
        PlayerState:SetLotteryState(State)
    else
        PlayerState.LotteryState = State
        if PlayerState.SaveToArchive ~= nil then
            PlayerState:SaveToArchive()
        end
    end
end

local function GetRemainingAwards(Pool, LotteryState)
    local Awards = {}
    for Index, Award in ipairs(Pool.Awards or {}) do
        if LotteryState.OwnedAwards[tostring(Index)] ~= true then
            table.insert(Awards, {
                Index = Index,
                Award = Award,
                IsGrandPrize = false
            })
        end
    end

    if LotteryState.GrandPrize ~= true then
        table.insert(Awards, {
            Index = 0,
            Award = Pool.GrandPrize,
            IsGrandPrize = true
        })
    end

    return Awards
end

local function RollAward(Candidates)
    local TotalWeight = 0
    for _, Candidate in ipairs(Candidates) do
        TotalWeight = TotalWeight + (tonumber(Candidate.Award.Weight) or 0)
    end

    if TotalWeight <= 0 then
        return Candidates[1]
    end

    local Roll = math.random(1, TotalWeight)
    local Acc = 0
    for _, Candidate in ipairs(Candidates) do
        Acc = Acc + (tonumber(Candidate.Award.Weight) or 0)
        if Roll <= Acc then
            return Candidate
        end
    end

    return Candidates[#Candidates]
end

local function GrantLotteryAward(PlayerController, Award)
    if Award == nil then
        return true
    end

    local ItemID = tonumber(Award.ItemID) or 0
    local Count = tonumber(Award.Count) or 1
    if ItemID <= 0 then
        return true
    end

    return AddItem(PlayerController, ItemID, Count)
end

local function AddLotteryAwardToList(ItemList, Award)
    local ItemID = tonumber(Award and Award.ItemID) or 0
    if ItemID > 0 then
        table.insert(ItemList, {
            ItemID = ItemID,
            ItemNum = tonumber(Award.Count) or 1
        })
    end
end

function UGCPlayerController:Server_RequestLottery(LotteryType, SlotIndex)
    LotteryType = tonumber(LotteryType) or 0
    local Pool = LotteryConfig.GetPool(LotteryType)
    if Pool == nil then
        ugcprint("[UGCPlayerController:Server_RequestLottery] invalid type=" .. tostring(LotteryType))
        UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -1, 0, 0, 0, {})
        return
    end

    local LotteryState, AllLotteryState = GetLotteryState(self, LotteryType)
    if LotteryState == nil then
        return
    end

    if LotteryState.Completed == true and not LotteryConfig.CanDrawCompletedPool() then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -2, 0, 0, 1, {})
        return
    end

    local NextRound = (tonumber(LotteryState.Round) or 0) + 1
    local Cost = LotteryConfig.GetRoundCost(NextRound)
    if (tonumber(LotteryConfig.CostItemID) or 0) > 0 then
        if GetItemCount(self, LotteryConfig.CostItemID) < Cost then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -3, 0, 0, 0, {})
            return
        end
        if not RemoveItem(self, LotteryConfig.CostItemID, Cost) then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -4, 0, 0, 0, {})
            return
        end
    end

    local Candidate = nil
    if LotteryConfig.IsGrandPrizeRound(LotteryType, NextRound) and LotteryState.GrandPrize ~= true then
        Candidate = {
            Index = 0,
            Award = Pool.GrandPrize,
            IsGrandPrize = true
        }
    else
        local Candidates = GetRemainingAwards(Pool, LotteryState)
        if #Candidates <= 0 then
            LotteryState.Completed = true
            SaveLotteryState(self, AllLotteryState)
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -2, 0, 0, 1, {})
            return
        end
        Candidate = RollAward(Candidates)
    end

    local Award = Candidate.Award
    local ItemList = {}
    if Candidate.IsGrandPrize then
        if not GrantLotteryAward(self, Award) then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -5, 0, 0, 0, {})
            return
        end
        AddLotteryAwardToList(ItemList, Award)

        LotteryState.GrandPrize = true
        local AllMissingAwardsGranted = true
        if LotteryConfig.GrantMissingAwardsOnGrandPrize then
            for Index, MissingAward in ipairs(Pool.Awards or {}) do
                if LotteryState.OwnedAwards[tostring(Index)] ~= true then
                    if GrantLotteryAward(self, MissingAward) then
                        LotteryState.OwnedAwards[tostring(Index)] = true
                        AddLotteryAwardToList(ItemList, MissingAward)
                    else
                        AllMissingAwardsGranted = false
                    end
                end
            end
        end
        if LotteryConfig.CompleteOnGrandPrize and AllMissingAwardsGranted then
            LotteryState.Completed = true
        end
    else
        if not GrantLotteryAward(self, Award) then
            UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, -5, 0, 0, 0, {})
            return
        end
        AddLotteryAwardToList(ItemList, Award)
        LotteryState.OwnedAwards[tostring(Candidate.Index)] = true
    end

    LotteryState.Round = NextRound
    SaveLotteryState(self, AllLotteryState)

    UnrealNetwork.CallUnrealRPC(self, self, "Client_LotteryResult", LotteryType, Candidate.Index,
        tonumber(Award.ItemID) or 0, tonumber(Award.Count) or 1, LotteryState.Completed and 1 or 0, ItemList)
end

function UGCPlayerController:Client_LotteryResult(LotteryType, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
    if self.UI14Instance ~= nil and self.UI14Instance.OnLotteryResult ~= nil then
        self.UI14Instance:OnLotteryResult(LotteryType, SlotIndex, AwardItemID, AwardCount, bCompleted, ItemList)
        return
    end

    if self.MainUIInstance ~= nil and self.MainUIInstance.UI14Instance ~= nil and
        self.MainUIInstance.UI14Instance.OnLotteryResult ~= nil then
        self.MainUIInstance.UI14Instance:OnLotteryResult(LotteryType, SlotIndex, AwardItemID, AwardCount, bCompleted,
            ItemList)
    end
end

-- Title equip
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
    if (titleActor == nil or not UE.IsValid(titleActor)) and pawn.EnsurePlayerTitleActor ~= nil then
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

function UGCPlayerController:Client_BroadcastPlantMessage(UID, level)
    --[[------------------客户端收到全服通知----------------------------]] --
    -- UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.Test_01,UID,level)
end

--[[---------------------增加概率-------------------------]] --
function UGCPlayerController:Server_AddProbabilityBonus(value)
    value = tonumber(value) or 0
    if value == 0 then
        return
    end
    if self.PlayerState == nil or self.PlayerState.AddProbability_Bonus == nil then
        return
    end
    self.PlayerState:AddProbability_Bonus(value)

    local str = "增加" .. tostring(value) .. "%概率，是" .. tostring(self.PlayerState.Probability_Bonus) .. "%"
    UnrealNetwork.CallUnrealRPC(self, self, "Client_ProbabilityBonusChanged", str)
end

function UGCPlayerController:Client_ProbabilityBonusChanged(str)
    if self.MainUIInstance ~= nil and self.MainUIInstance.OnhandleTest ~= nil then
        self.MainUIInstance:OnhandleTest(str)
    end
end

function UGCPlayerController:Client_RefreshProperty(baseAttack, baseMaxHp, hp, maxHp, bFillHealth)
    if self.MainUIInstance ~= nil and self.MainUIInstance.OnRefreshProperty ~= nil then
        self.MainUIInstance:OnRefreshProperty(baseAttack, baseMaxHp, hp, maxHp, bFillHealth)
        return
    end

    UGCGenericMessageSystem.BroadcastUserDefinedGlobalMessage(L_Enum_Event.Enum.ReFreshProperty, baseAttack, baseMaxHp,
        hp, maxHp, bFillHealth)
end

function UGCPlayerController:Client_YXWDInvincibleBuffChanged(bEnabled, DurationSeconds)
    if self.MainUIInstance ~= nil and self.MainUIInstance.OnYXWDInvincibleBuffChanged ~= nil then
        self.MainUIInstance:OnYXWDInvincibleBuffChanged(bEnabled, DurationSeconds)
    end
end

--[[------------------------自动拾取----------------------]] --
function UGCPlayerController:Server_SetYXWDInvincibleBuffActive(bEnabled)
    local PlayerState = self.PlayerState
    if PlayerState == nil then
        return
    end

    local bHasBuff = false
    if PlayerState.GetYXWD_InvincibleBuff ~= nil then
        bHasBuff = PlayerState:GetYXWD_InvincibleBuff() == true
    else
        bHasBuff = tonumber(PlayerState.YXWD_InvincibleBuff) == 1
    end

    if not bHasBuff then
        UnrealNetwork.CallUnrealRPC(self, self, "Client_YXWDInvincibleActiveChanged", 0)
        return
    end

    local bActive = bEnabled == true or tonumber(bEnabled) == 1
    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
        PlayerState:SetYXWD_InvincibleBuffActive(bActive)
    else
        PlayerState.YXWD_InvincibleBuffActive = bActive
    end

    UnrealNetwork.CallUnrealRPC(self, self, "Client_YXWDInvincibleActiveChanged", bActive and 1 or 0)
end

function UGCPlayerController:Client_YXWDInvincibleActiveChanged(bActive)
    if self.MainUIInstance ~= nil and self.MainUIInstance.OnYXWDInvincibleActiveChanged ~= nil then
        self.MainUIInstance:OnYXWDInvincibleActiveChanged(bActive)
    end
end

function UGCPlayerController:Server_SetFinalMaxHp(finalMaxHp, bFillHealth)
    local pawn = self.Pawn
    if pawn == nil then
        return
    end
    finalMaxHp = tonumber(finalMaxHp) or 100
    local oldMaxHp = UGCPawnAttrSystem.GetHealthMax(pawn) or finalMaxHp
    local oldHp = UGCPawnAttrSystem.GetHealth(pawn) or oldMaxHp
    UGCPawnAttrSystem.SetHealthMax(pawn, finalMaxHp)

    if bFillHealth then
        oldHp = finalMaxHp
    else
        local addHp = finalMaxHp - oldMaxHp
        if addHp > 0 then
            oldHp = oldHp + addHp
        end
    end
    UGCPawnAttrSystem.SetHealth(pawn, math.min(oldHp, finalMaxHp))
end

function UGCPlayerController:Server_SetFinalAttack(finalAttack)
    local pawn = self.Pawn
    if pawn == nil then
        return
    end
    finalAttack = tonumber(finalAttack) or 40
    UGCAttributeSystem.SetGameAttributeValue(pawn, "AttackPower", finalAttack)
end

local AUTO_PICK_RANGE = 600
local AUTO_PICK_INTERVAL = 0.5
function UGCPlayerController:Server_SetAutoPickEnabled(bEnabled)
    self.bAutoPickEnabled = bEnabled
    local TimerName = "AutoPick_" .. tostring(self.PlayerKey)
    UGCTimerUtility.RemoveLuaTimerByName(TimerName)
    if not bEnabled then
        return
    end

    UGCTimerUtility.CreateLuaTimer(AUTO_PICK_INTERVAL, function()
        local Location = self.Pawn:K2_GetActorLocation()
        local Wrappers = UGCItemSystemV2.FindPickupWrapperActorByRange(Location, AUTO_PICK_RANGE)

        for _, Wrappers in pairs(Wrappers) do
            UGCItemSystemV2.TryPickupWrapperItem(self.Pawn, Wrappers, nil, Wrappers:GetItemCount(), true)
        end
    end, true, TimerName)

    --[[--------------------这边测试加战力--------------------------]] --
    -- local pawn = self.Pawn or self:K2_GetPawn()
    -- L_Com.UseHunHuan(pawn, 8310055, 100)
end

--[[----------------------自动攻击------------------------]] --
function UGCPlayerController:StopAutoMeleeAttack()
    UGCTimerUtility.RemoveLuaTimerByName("AutoMeleeAttack")
end

local Auto_Melee_Attack = 0.45
local function TriggerMeleeWeaponAttack(Weapon)
    local PressEvent = EWeaponTriggerEvent.EWeaponTriggerEvent_PressFuncBtn
    local ReleaseEvent = EWeaponTriggerEvent.EWeaponTriggerEvent_ReleaseFuncBtn
    Weapon:TriggerWeaponEvent(PressEvent, "")
    Weapon:TriggerWeaponEvent(ReleaseEvent, "")
end

function UGCPlayerController:StartAutoMeleeAttack()
    UGCTimerUtility.RemoveLuaTimerByName("AutoMeleeAttack")
    UGCTimerUtility.CreateLuaTimer(Auto_Melee_Attack, function()
        self:TryAutoMeleeAttack()
    end, true, "AutoMeleeAttack")
end

function UGCPlayerController:TryAutoMeleeAttack()
    local Pawn = self.Pawn
    local MeleeSlot = ESurviveWeaponPropSlot.SWPS_MeleeWeapon
    if tonumber(UGCWeaponManagerSystem.GetCurrentWeaponSlot(Pawn)) == tonumber(MeleeSlot) then
        TriggerMeleeWeaponAttack(UGCWeaponManagerSystem.GetCurrentWeapon(Pawn))
    end
end

--[[----------------------补偿系统----------------------]] --
-- 注册补偿系统委托
-- 服务器注册全部3个委托，客户端只注册单笔补偿委托
function UGCPlayerController:RegisterCompensationDelegates()
    if UGCCommoditySystem == nil then
        return
    end

    -- 单笔补偿（服务器&客户端都会收到）
    if UGCCommoditySystem.CompensateUGCCommodityDelegate ~= nil then
        UGCCommoditySystem.CompensateUGCCommodityDelegate:Add(self.OnCompensateUGCCommodity, self)
    end

    -- 以下两个委托仅服务器
    if self:HasAuthority() then
        if UGCCommoditySystem.CompensateUGCCommodityBatchDelegate ~= nil then
            UGCCommoditySystem.CompensateUGCCommodityBatchDelegate:Add(self.OnCompensateUGCCommodityBatch, self)
        end
        if UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate ~= nil then
            UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate:Add(
                self.OnBuyUGCCommodityResultBetweenGames, self)
        end
    end

    print("[Compensation] RegisterCompensationDelegates: isServer=" .. tostring(self:HasAuthority()))
end

-- 注销补偿系统委托
function UGCPlayerController:UnregisterCompensationDelegates()
    if UGCCommoditySystem == nil then
        return
    end

    if UGCCommoditySystem.CompensateUGCCommodityDelegate ~= nil then
        UGCCommoditySystem.CompensateUGCCommodityDelegate:Remove(self.OnCompensateUGCCommodity, self)
    end

    if self:HasAuthority() then
        if UGCCommoditySystem.CompensateUGCCommodityBatchDelegate ~= nil then
            UGCCommoditySystem.CompensateUGCCommodityBatchDelegate:Remove(self.OnCompensateUGCCommodityBatch, self)
        end
        if UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate ~= nil then
            UGCCommoditySystem.BuyUGCCommodityResultBetweenGamesDelegate:Remove(
                self.OnBuyUGCCommodityResultBetweenGames, self)
        end
    end
end

function UGCPlayerController:ReceiveEndPlay()
    self:UnregisterCompensationDelegates()
end

--- 单笔补偿回调（服务器&客户端都会收到）
---@param PlayerKey number
---@param UID number
---@param CommodityID number 物品ID（对应UGCObject表）
---@param Count number 补偿数量
---@param ProductID number 商品ID（对应UGCShop表）
function UGCPlayerController:OnCompensateUGCCommodity(PlayerKey, UID, CommodityID, Count, ProductID)
    print(string.format("[Compensation] OnCompensateUGCCommodity: PlayerKey=%s UID=%s CommodityID=%s Count=%s ProductID=%s",
        tostring(PlayerKey), tostring(UID), tostring(CommodityID), tostring(Count), tostring(ProductID)))

    -- 服务器收到后转发给对应客户端
    if self:HasAuthority() then
        local TargetPC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
        if TargetPC ~= nil then
            UnrealNetwork.CallUnrealRPC(self, TargetPC, "Client_CompensationReceived", CommodityID, Count, ProductID)
        end
    end
end

--- 批量补偿回调（仅服务器）
---@param PlayerKey number
---@param UID number
---@param CommodityList table 补偿商品列表
function UGCPlayerController:OnCompensateUGCCommodityBatch(PlayerKey, UID, CommodityList)
    print(string.format("[Compensation] OnCompensateUGCCommodityBatch: PlayerKey=%s UID=%s count=%d",
        tostring(PlayerKey), tostring(UID), #CommodityList))

    local TargetPC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
    if TargetPC == nil then
        return
    end

    -- 逐个转发给客户端
    for _, item in ipairs(CommodityList) do
        UnrealNetwork.CallUnrealRPC(self, TargetPC, "Client_CompensationReceived",
            item.CommodityID, item.Count, item.ProductID or 0)
    end
end

--- 跨局商品变化回调（仅服务器）
---@param PlayerKey number
---@param UID number
---@param CommodityID number 物品ID
---@param Count number 新增的差异数量
function UGCPlayerController:OnBuyUGCCommodityResultBetweenGames(PlayerKey, UID, CommodityID, Count)
    print(string.format("[Compensation] OnBuyUGCCommodityResultBetweenGames: PlayerKey=%s UID=%s CommodityID=%s Count=%s",
        tostring(PlayerKey), tostring(UID), tostring(CommodityID), tostring(Count)))

    local TargetPC = UGCGameSystem.GetPlayerControllerByPlayerKey(PlayerKey)
    if TargetPC == nil then
        return
    end

    -- 转发给客户端弹窗（ProductID传0表示跨局变化，非补偿购买）
    UnrealNetwork.CallUnrealRPC(self, TargetPC, "Client_CompensationReceived", CommodityID, Count, 0)
end

--- 客户端收到补偿通知后弹窗
---@param CommodityID number 物品ID
---@param Count number 数量
---@param ProductID number 商品ID（0表示跨局变化）
function UGCPlayerController:Client_CompensationReceived(CommodityID, Count, ProductID)
    print(string.format("[Compensation] Client_CompensationReceived: CommodityID=%s Count=%s ProductID=%s",
        tostring(CommodityID), tostring(Count), tostring(ProductID)))

    -- 复用 ShopV2Manager 的弹窗
    if ShopV2Manager ~= nil and ShopV2Manager.ShowItemGetPopup ~= nil then
        ShopV2Manager:ShowItemGetPopup(CommodityID, Count)
    else
        print("[Compensation] ShopV2Manager not available, popup skipped")
    end
end

--- GM测试补偿系统（客户端调用，服务器执行模拟补偿）
---@param TestType number 1=单笔 2=批量 3=跨局
---@param CommodityID number 物品ID（默认1001）
---@param Count number 数量（默认5）
function UGCPlayerController:Server_TestCompensation(TestType, CommodityID, Count)
    if not self:HasAuthority() then
        return
    end
    TestType = tonumber(TestType) or 1
    CommodityID = tonumber(CommodityID) or 1001
    Count = tonumber(Count) or 5

    print(string.format("[Compensation][GM] Server_TestCompensation: type=%d item=%d count=%d",
        TestType, CommodityID, Count))

    if TestType == 1 then
        -- 模拟单笔补偿
        self:OnCompensateUGCCommodity(self.PlayerKey, 0, CommodityID, Count, 9000001)
    elseif TestType == 2 then
        -- 模拟批量补偿
        local list = {
            {CommodityID = CommodityID, Count = Count, ProductID = 9000001},
            {CommodityID = CommodityID + 1, Count = Count + 2, ProductID = 9000002}
        }
        self:OnCompensateUGCCommodityBatch(self.PlayerKey, 0, list)
    elseif TestType == 3 then
        -- 模拟跨局商品变化
        self:OnBuyUGCCommodityResultBetweenGames(self.PlayerKey, 0, CommodityID, Count)
    end
end

return UGCPlayerController
