local BackpackCapacityUtil = {}

local function SafeNumberCall(Func, Player)
    if Func == nil then
        return nil
    end
    local Success, Value = pcall(Func, Player)
    if not Success then
        return nil
    end
    return tonumber(Value)
end

function BackpackCapacityUtil.GetEquippedItemCount(Player)
    if Player == nil or UGCBackpackSystemV2 == nil or
        UGCBackpackSystemV2.GetEquipSlots == nil or
        UGCBackpackSystemV2.GetEquippedItemBySlotName == nil then
        return 0
    end

    local Success, Slots = pcall(UGCBackpackSystemV2.GetEquipSlots, Player)
    if not Success or Slots == nil then
        return 0
    end

    local EquippedCount = 0
    local SlotCount = tonumber(#Slots) or 0
    for Index = 1, SlotCount do
        local SlotName = Slots[Index]
        if SlotName ~= nil then
            local ReadSucceeded, ItemDefineID = pcall(
                UGCBackpackSystemV2.GetEquippedItemBySlotName, Player, SlotName)
            -- 空装备槽在部分运行环境返回 0 而不是 nil，不能把它计入已占用空间。
            local NumericItemDefineID = ReadSucceeded and tonumber(ItemDefineID) or nil
            if NumericItemDefineID ~= nil and NumericItemDefineID > 0 then
                EquippedCount = EquippedCount + 1
            end
        end
    end
    return EquippedCount
end

--- 背包容量判断包含穿戴在所有装备槽中的物品。
function BackpackCapacityUtil.IsFullIncludingEquipped(Player)
    if Player == nil or UGCBackpackSystemV2 == nil then
        return false
    end

    local CellCapacity = SafeNumberCall(UGCBackpackSystemV2.GetCellCapacity, Player)
    local CellItemCount = SafeNumberCall(UGCBackpackSystemV2.GetCellItemCount, Player)
    if CellCapacity ~= nil and CellCapacity > 0 and CellItemCount ~= nil then
        return CellItemCount + BackpackCapacityUtil.GetEquippedItemCount(Player) >= CellCapacity
    end

    if UGCBackpackSystemV2.IsCellCapacityFull ~= nil then
        local Success, bFull = pcall(UGCBackpackSystemV2.IsCellCapacityFull, Player)
        return Success and bFull == true
    end
    return false
end

return BackpackCapacityUtil
