local PlayerInitialData = {}
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")

local INITIAL_STACK_ITEMS = {
    {ItemID = 8310064, Count = 10},
    {ItemID = 8310047, Count = 1},
    {ItemID = 8310035, Count = 80000},
    {ItemID = 8310036, Count = 1000},
    {ItemID = 8310037, Count = 10},
    {ItemID = 8310038, Count = 10},
    {ItemID = 8310039, Count = 10},
    {ItemID = 8310008, Count = 1000},
    {ItemID = 8310007, Count = 1},
    {ItemID = 8310009, Count = 1}
}

local DISUSE_FUNCTION_NAMES = {"DisuseItemV2", "UnUseItemV2", "CancelUseItemV2", "StopUseItemV2"}

local function TryDisuseItem(PlayerPawn, ItemDefineID)
    if PlayerPawn == nil or ItemDefineID == nil or UGCBackpackSystemV2 == nil then
        return false
    end

    for _, FunctionName in ipairs(DISUSE_FUNCTION_NAMES) do
        local Func = UGCBackpackSystemV2[FunctionName]
        if Func ~= nil then
            local Success, Result = pcall(Func, PlayerPawn, ItemDefineID)
            if Success and Result ~= false then
                return true
            end
        end
    end
    return false
end

local function BuildTargetItemCounts(ExtraBaseItemID)
    local Targets = {}
    for _, ItemID in ipairs(WeaponLevelConfig.GetAllBaseItemIDs()) do
        ItemID = tonumber(ItemID)
        if ItemID ~= nil then
            Targets[ItemID] = math.max(Targets[ItemID] or 0, 1)
        end
    end
    ExtraBaseItemID = tonumber(ExtraBaseItemID) or WeaponLevelConfig.GetItemID("HTC", 2) or 8310015
    Targets[ExtraBaseItemID] = math.max(Targets[ExtraBaseItemID] or 0, 1)
    for _, Item in ipairs(INITIAL_STACK_ITEMS) do
        local ItemID = tonumber(Item.ItemID)
        local Count = math.max(0, tonumber(Item.Count) or 0)
        if ItemID ~= nil then
            Targets[ItemID] = math.max(Targets[ItemID] or 0, Count)
        end
    end
    return Targets
end

local function AddMissingItemCount(PlayerPawn, ItemID, TargetCount)
    local CurrentCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0
    local MissingCount = math.max(0, TargetCount - CurrentCount)
    if MissingCount == 0 then
        return true
    end

    local AddedCount = UGCBackpackSystemV2.AddItemV2(PlayerPawn, ItemID, MissingCount)
    AddedCount = tonumber(AddedCount)
    return AddedCount ~= nil and AddedCount >= MissingCount
end

--- 发放与 UGCGameMode 登录流程一致的基础武器和初始物资。
---@param PlayerPawn userdata
---@param ExtraBaseItemID number|nil
function PlayerInitialData.Grant(PlayerPawn, ExtraBaseItemID)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil then
        return false
    end

    local AllRequestsSucceeded = true
    for ItemID, TargetCount in pairs(BuildTargetItemCounts(ExtraBaseItemID)) do
        if not AddMissingItemCount(PlayerPawn, ItemID, TargetCount) then
            AllRequestsSucceeded = false
            ugcprint("[PlayerInitialData] grant request incomplete itemID=" .. tostring(ItemID) ..
                         " target=" .. tostring(TargetCount))
        end
    end
    return AllRequestsSucceeded
end

---@param PlayerPawn userdata
---@param ExtraBaseItemID number|nil
---@return boolean, table|nil
function PlayerInitialData.VerifyGrant(PlayerPawn, ExtraBaseItemID)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil then
        return false, nil
    end

    local Mismatches = {}
    for ItemID, TargetCount in pairs(BuildTargetItemCounts(ExtraBaseItemID)) do
        local ActualCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0
        if ActualCount ~= TargetCount then
            table.insert(Mismatches, {
                ItemID = ItemID,
                Expected = TargetCount,
                Actual = ActualCount
            })
        end
    end
    return #Mismatches == 0, Mismatches
end

--- 清空当前 Pawn 的 V2 背包。仅操作背包，不触碰虚拟物品或官方扩展系统数据。
---@param PlayerPawn userdata
---@return boolean, number, table
function PlayerInitialData.ClearBackpack(PlayerPawn)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or
        UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil then
        return false, 0, {}
    end

    local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
    if AllItemData == nil then
        return false, 0, {}
    end

    -- 先复制实例 ID，避免删除物品时修改引擎返回的容器导致漏删。
    local ItemDefineIDs = {}
    for _, ItemDefineID in pairs(AllItemData) do
        table.insert(ItemDefineIDs, ItemDefineID)
    end

    local RemovedInstanceCount = 0
    for _, ItemDefineID in ipairs(ItemDefineIDs) do
        TryDisuseItem(PlayerPawn, ItemDefineID)

        local Removed = false
        if UGCBackpackSystemV2.RemoveItemByDefineIDV2 ~= nil then
            local Success, Result = pcall(UGCBackpackSystemV2.RemoveItemByDefineIDV2, PlayerPawn, ItemDefineID)
            Removed = Success and Result ~= false and Result ~= 0
        end

        if not Removed and UGCBackpackSystemV2.RemoveItemV2 ~= nil then
            local ItemID = tonumber(ItemDefineID.TypeSpecificID)
            local Count = UGCBackpackSystemV2.GetItemCountByDefineIDV2 ~= nil and
                              tonumber(UGCBackpackSystemV2.GetItemCountByDefineIDV2(PlayerPawn, ItemDefineID)) or 0
            if ItemID ~= nil and Count > 0 then
                local Success, Result = pcall(UGCBackpackSystemV2.RemoveItemV2, PlayerPawn, ItemID, Count)
                Removed = Success and Result ~= false and Result ~= 0
            end
        end

        if Removed then
            RemovedInstanceCount = RemovedInstanceCount + 1
        end
    end

    local Remaining = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
    if Remaining == nil then
        return false, RemovedInstanceCount, {}
    end
    local RemainingCount = 0
    local RemainingDefineIDs = {}
    for _, ItemDefineID in pairs(Remaining or {}) do
        RemainingCount = RemainingCount + 1
        table.insert(RemainingDefineIDs, ItemDefineID)
    end
    return RemainingCount == 0, RemovedInstanceCount, RemainingDefineIDs
end

return PlayerInitialData
