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

local function AddItemIfMissing(PlayerPawn, ItemID, Count)
    local CurrentCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0
    if CurrentCount <= 0 then
        UGCBackpackSystemV2.AddItemV2(PlayerPawn, ItemID, Count)
    end
end

--- 发放与 UGCGameMode 登录流程一致的基础武器和初始物资。
---@param PlayerPawn userdata
---@param ExtraBaseItemID number|nil
function PlayerInitialData.Grant(PlayerPawn, ExtraBaseItemID)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil then
        return false
    end

    for _, ItemID in ipairs(WeaponLevelConfig.GetAllBaseItemIDs()) do
        AddItemIfMissing(PlayerPawn, ItemID, 1)
    end
    if ExtraBaseItemID ~= nil then
        AddItemIfMissing(PlayerPawn, ExtraBaseItemID, 1)
    end

    for _, Item in ipairs(INITIAL_STACK_ITEMS) do
        UGCBackpackSystemV2.AddItemV2(PlayerPawn, Item.ItemID, Item.Count)
    end
    return true
end

--- 清空当前 Pawn 的 V2 背包。仅操作背包，不触碰虚拟物品或官方扩展系统数据。
---@param PlayerPawn userdata
---@return boolean, number
function PlayerInitialData.ClearBackpack(PlayerPawn)
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or
        UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil then
        return false, 0
    end

    local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
    if AllItemData == nil then
        return true, 0
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
    local RemainingCount = 0
    for _ in pairs(Remaining or {}) do
        RemainingCount = RemainingCount + 1
    end
    return RemainingCount == 0, RemovedInstanceCount
end

return PlayerInitialData
