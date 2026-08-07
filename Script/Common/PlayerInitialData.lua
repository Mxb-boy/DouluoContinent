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
---@param VerifyOnly boolean|nil
---@return boolean, number, number, string
function PlayerInitialData.ClearBackpack(PlayerPawn, VerifyOnly)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or
        UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil or
        UGCBackpackSystemV2.RemoveItemByDefineIDV2 == nil then
        return false, 0, -1, "backpack_api_unavailable"
    end

    local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
    if AllItemData == nil then
        return false, 0, -1, "item_array_nil"
    end

    -- Never range-iterate the engine TArray and mutate the backpack in the same
    -- call stack. UnLua keeps the ranged-for iterator alive until the function
    -- returns, which triggers UE's "Array has changed" ensure on PC.
    local ItemInstanceCount = tonumber(#AllItemData) or 0
    if ItemInstanceCount <= 0 then
        return true, 0, 0, "empty"
    end
    if VerifyOnly == true then
        return false, 0, ItemInstanceCount, "final_verify_not_empty"
    end

    local ReadSucceeded, ItemDefineID = pcall(function()
        return AllItemData[1]
    end)
    if not ReadSucceeded or ItemDefineID == nil then
        return false, 0, ItemInstanceCount, "first_item_unavailable"
    end

    local ItemIDReadSucceeded, ItemID = pcall(function()
        return tonumber(ItemDefineID.TypeSpecificID)
    end)
    if not ItemIDReadSucceeded or ItemID == nil then
        return false, 0, ItemInstanceCount, "item_id_unavailable"
    end

    local ItemCount = 0
    if UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        local CountSucceeded, CountValue = pcall(UGCBackpackSystemV2.GetItemCountV2,
            PlayerPawn, ItemID)
        if CountSucceeded then
            ItemCount = math.max(0, tonumber(CountValue) or 0)
        end
    end

    ugcprint("[GMReset][BackpackRemoveBegin] itemID=" .. tostring(ItemID) ..
                 " itemCount=" .. tostring(ItemCount) .. " instancesBefore=" ..
                 tostring(ItemInstanceCount))

    -- Drop the TArray wrapper before any call that mutates the backpack.
    AllItemData = nil
    local RemoveSucceeded, RemoveResult, RemoveMode
    if ItemCount > 0 and UGCBackpackSystemV2.RemoveItemV2 ~= nil then
        RemoveSucceeded, RemoveResult = pcall(UGCBackpackSystemV2.RemoveItemV2,
            PlayerPawn, ItemID, ItemCount)
        RemoveMode = "item_id"
    else
        RemoveSucceeded, RemoveResult = pcall(UGCBackpackSystemV2.RemoveItemByDefineIDV2,
            PlayerPawn, ItemDefineID)
        RemoveMode = "define_id"
    end
    ugcprint("[GMReset][BackpackRemoveEnd] itemID=" .. tostring(ItemID) ..
                 " mode=" .. tostring(RemoveMode) .. " callSucceeded=" ..
                 tostring(RemoveSucceeded) .. " result=" .. tostring(RemoveResult))
    local Requested = RemoveSucceeded and RemoveResult ~= false and RemoveResult ~= 0
    local Detail = "itemID=" .. tostring(ItemID) .. " itemCount=" .. tostring(ItemCount) ..
                       " mode=" .. tostring(RemoveMode) .. " callSucceeded=" ..
                       tostring(RemoveSucceeded) .. " result=" .. tostring(RemoveResult)
    return false, Requested and 1 or 0, ItemInstanceCount, Detail
end

return PlayerInitialData
