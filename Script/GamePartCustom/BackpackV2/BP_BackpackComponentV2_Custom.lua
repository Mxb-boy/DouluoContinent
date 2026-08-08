---@class BP_BackpackComponentV2_Custom_C:BP_BackpackComponentV2_C
--Edit Below--
local BP_BackpackComponentV2_Custom = {} 
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")

local function GetOwnerController(self)
    local Owner = nil
    if self.GetOwner ~= nil then
        local Success, Result = pcall(self.GetOwner, self)
        if Success then
            Owner = Result
        end
    end

    if Owner == nil then
        Owner = self.Owner
    end
    if Owner == nil then
        return nil
    end
    return Owner.Controller or Owner.PlayerController or Owner
end

local function GetOwnerPawn(self)
    local Owner = nil
    if self.GetOwner ~= nil then
        local Success, Result = pcall(self.GetOwner, self)
        if Success then
            Owner = Result
        end
    end

    if Owner == nil then
        Owner = self.Owner
    end
    if Owner ~= nil and Owner.Pawn ~= nil then
        return Owner.Pawn
    end
    if Owner ~= nil and Owner.Controller ~= nil then
        return Owner
    end

    local Controller = GetOwnerController(self)
    return Controller ~= nil and Controller.Pawn or Owner
end

local function GetItemIDFromDefineID(ItemDefineID)
    if ItemDefineID == nil then
        return nil
    end

    local DefineIDType = type(ItemDefineID)
    if DefineIDType == "number" or DefineIDType == "string" then
        return tonumber(ItemDefineID)
    end

    local FieldNames = {"TypeSpecificID", "ItemID", "ItemId", "itemID", "ID"}
    for _, FieldName in ipairs(FieldNames) do
        local Success, Value = pcall(function()
            return ItemDefineID[FieldName]
        end)
        if Success and tonumber(Value) ~= nil then
            return tonumber(Value)
        end
    end

    local FunctionNames = {"GetItemID", "GetItemId", "GetItemDefineID", "GetDefineID", "GetDefineId"}
    for _, FunctionName in ipairs(FunctionNames) do
        local SuccessGetFunc, Func = pcall(function()
            return ItemDefineID[FunctionName]
        end)
        if SuccessGetFunc and Func ~= nil then
            local Success, Result = pcall(Func, ItemDefineID)
            if Success and tonumber(Result) ~= nil then
                return tonumber(Result)
            end
            Success, Result = pcall(Func)
            if Success and tonumber(Result) ~= nil then
                return tonumber(Result)
            end
        end
    end

    return nil
end

local function GetWeaponLevelFromDefineID(ItemDefineID, WeaponInfo)
    if WeaponInfo == nil then
        return nil
    end

    if ItemDefineID ~= nil and UGCItemSystemV2 ~= nil and UGCItemSystemV2.LoadItemCustomData ~= nil then
        local Success, CustomData = pcall(UGCItemSystemV2.LoadItemCustomData, ItemDefineID)
        if Success and type(CustomData) == "table" then
            local Level = tonumber(CustomData.WeaponLevel or CustomData.StrengthenLv)
            if Level ~= nil then
                return math.max(1, math.min(WeaponInfo.MaxLevel, Level))
            end
        end
    end

    return math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(WeaponInfo.Level) or 1))
end

local function SetEquippedWeaponFromDefineID(self, ItemDefineID)
    local ItemID = GetItemIDFromDefineID(ItemDefineID)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if WeaponInfo == nil then
        return
    end

    local Pawn = GetOwnerPawn(self)
    if Pawn == nil then
        return
    end

    Pawn.CurrentUsedWeaponItemID = ItemID
    Pawn.CurrentUsedWeaponLevel = GetWeaponLevelFromDefineID(ItemDefineID, WeaponInfo)
    Pawn.CurrentUsedWeaponSeriesKey = WeaponInfo.SeriesKey
    Pawn.LastWeaponAttackKey = nil
    Pawn.LastLocalWeaponAttackDisplayKey = nil

    if Pawn.RefreshWeaponAttackBonus ~= nil then
        Pawn:RefreshWeaponAttackBonus(true)
    end
end

local function ClearEquippedWeaponFromDefineID(self, ItemDefineID)
    local ItemID = GetItemIDFromDefineID(ItemDefineID)
    if WeaponLevelConfig.GetWeaponInfo(ItemID) == nil then
        return
    end

    local Pawn = GetOwnerPawn(self)
    if Pawn == nil then
        return
    end

    if tonumber(Pawn.CurrentUsedWeaponItemID) == tonumber(ItemID) then
        Pawn.CurrentUsedWeaponItemID = nil
        Pawn.CurrentUsedWeaponLevel = nil
        Pawn.CurrentUsedWeaponSeriesKey = nil
        Pawn.LastWeaponAttackKey = nil
        Pawn.LastLocalWeaponAttackDisplayKey = nil

        if Pawn.RefreshWeaponAttackBonus ~= nil then
            Pawn:RefreshWeaponAttackBonus(true)
        end
    end
end

local function SyncWeaponNamesLater(self)
    local Controller = GetOwnerController(self)
    if Controller == nil or Controller.SyncWeaponBackpackNames == nil then
        return
    end
    UGCTimerUtility.CreateLuaTimer(0.2, function()
        if Controller ~= nil and Controller.SyncWeaponBackpackNames ~= nil then
            Controller:SyncWeaponBackpackNames()
        end
    end, false)
end

---func 背包初始化函数，玩家登录后执行一次(服务端调用)
-- function BP_BackpackComponentV2_Custom:InitEventAfterPlayerEnter()
-- end

---func 能否添加物品进背包(服务端调用)
---@param ItemID number 物品ID
---@param Count number 物品数量
---@return number 允许添加物品数量
-- function BP_BackpackComponentV2_Custom:CanAddItemV2(ItemID, Count)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanAddItemV2(self, ItemID, Count);
-- end

---func 能否添加物品进背包(服务端调用)
---@param DefineID userdata 物品DefineID
---@param Count number 物品数量
---@return number 允许添加物品数量
-- function BP_BackpackComponentV2_Custom:CanAddItemByDefineIDV2(DefineID, Count)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanAddItemByDefineIDV2(self, DefineID, Count);
-- end

---func 当背包添加物品后回调(服务端调用)
---@param DefineID userdata 物品DefineID
---@param Count number 物品数量
-- function BP_BackpackComponentV2_Custom:OnAddItemV2(DefineID, Count)
--     BP_BackpackComponentV2_Custom.SuperClass.OnAddItemV2(self, DefineID, Count);
-- end
function BP_BackpackComponentV2_Custom:OnAddItemV2(DefineID, Count)
    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.OnAddItemV2 ~= nil then
        BP_BackpackComponentV2_Custom.SuperClass.OnAddItemV2(self, DefineID, Count)
    end
    SyncWeaponNamesLater(self)
end

---func 能否合并物品(新添加物品能否与已有格子物品堆叠, 格子物品即物品实例)(服务端调用)
---@param ItemDefineID userdata 格子物品DefineID
---@param CountNow number 当前格子的物品数量
---@param MergeCount number 要合并到格子的新物品数量
---@return number 能合并到该格子的物品数量
-- function BP_BackpackComponentV2_Custom:CanMergeItemV2(ItemDefineID, CountNow, MergeCount)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanMergeItemV2(self, ItemDefineID, CountNow, MergeCount);
-- end

---func 当合并物品后回调(新添加物品与已有格子物品堆叠, 格子物品即物品实例)(服务端调用)
---@param ItemDefineID userdata 格子物品DefineID
---@param OldCount number 合并前格子的物品数量
---@param MergeCount number 合并到该格子的新物品数量
-- function BP_BackpackComponentV2_Custom:OnMergeItemV2(ItemDefineID, OldCount, MergeCount)
--     BP_BackpackComponentV2_Custom.SuperClass.OnMergeItemV2(self, ItemDefineID, OldCount, MergeCount);
-- end
function BP_BackpackComponentV2_Custom:CanMergeItemV2(ItemDefineID, CountNow, MergeCount)
    local ItemID = nil
    if ItemDefineID ~= nil then
        ItemID = tonumber(ItemDefineID.TypeSpecificID or ItemDefineID.ItemID or ItemDefineID.ItemId or ItemDefineID.ID)
    end

    if ItemID ~= nil and WeaponLevelConfig.GetWeaponInfo(ItemID) ~= nil then
        return 0
    end

    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.CanMergeItemV2 ~= nil then
        return BP_BackpackComponentV2_Custom.SuperClass.CanMergeItemV2(self, ItemDefineID, CountNow, MergeCount)
    end

    return MergeCount
end

function BP_BackpackComponentV2_Custom:OnMergeItemV2(ItemDefineID, OldCount, MergeCount)
    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.OnMergeItemV2 ~= nil then
        BP_BackpackComponentV2_Custom.SuperClass.OnMergeItemV2(self, ItemDefineID, OldCount, MergeCount)
    end
    SyncWeaponNamesLater(self)
end

---func 能否移除物品(服务端调用)
---@param ItemDefineID userdata 物品DefineID
---@param Count number 需要移除的物品数量
---@return number 允许移除物品数量
-- function BP_BackpackComponentV2_Custom:CanRemoveItemV2(ItemDefineID, Count)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanRemoveItemV2(self, ItemDefineID, Count);
-- end
function BP_BackpackComponentV2_Custom:CanRemoveItemV2(ItemDefineID, Count)
    local RequestedCount = math.max(0, tonumber(Count) or 0)
    local Controller = GetOwnerController(self)
    if Controller ~= nil and Controller.bGMResetInProgress == true then
        return RequestedCount
    end

    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and
        BP_BackpackComponentV2_Custom.SuperClass.CanRemoveItemV2 ~= nil then
        return BP_BackpackComponentV2_Custom.SuperClass.CanRemoveItemV2(self, ItemDefineID, Count)
    end
    return 0
end

---func 移除物品后回调(服务端调用)
---@param ItemDefineID userdata 物品DefineID，移除后可能不存在于背包
---@param Count number 已移除的物品数量
-- function BP_BackpackComponentV2_Custom:OnRemoveItemV2(ItemDefineID, Count)
--     BP_BackpackComponentV2_Custom.SuperClass.OnRemoveItemV2(self, ItemDefineID, Count);
-- end

---func 能否丢弃物品(服务端调用)
---@param ItemDefineID userdata 物品DefineID
---@param Count number 需要丢弃的物品数量
---@return number 允许丢弃的物品数量
-- function BP_BackpackComponentV2_Custom:CanDropItemV2(ItemDefineID, Count)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanDropItemV2(self, ItemDefineID, Count);
-- end

---func 丢弃物品后回调(服务端调用)
---@param ItemDefineID userdata 物品DefineID，丢弃后物品可能不存在于背包
---@param Count number 已丢弃的物品数量
-- function BP_BackpackComponentV2_Custom:OnDropItemV2(ItemDefineID, Count)
--     BP_BackpackComponentV2_Custom.SuperClass.OnDropItemV2(self, ItemDefineID, Count);
-- end

---func 能否使用物品(服务端调用)
---@param ItemDefineID userdata 物品DefineID
---@return bool 物品能否使用
-- function BP_BackpackComponentV2_Custom:CanUseItemV2(ItemDefineID)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanUseItemV2(self, ItemDefineID);
-- end

---func 使用物品后回调(服务端调用)
---@param ItemDefineID userdata 物品DefineID
-- function BP_BackpackComponentV2_Custom:OnUseItemV2(ItemDefineID)
--     BP_BackpackComponentV2_Custom.SuperClass.OnUseItemV2(self, ItemDefineID);
-- end

---func 取消使用物品后回调(服务端调用) 装备/投掷物 取消使用/卸下。 注：药品不会触发此回调
---@param ItemDefineID userdata 物品DefineID
-- function BP_BackpackComponentV2_Custom:OnDisuseItemV2(ItemDefineID)
--     BP_BackpackComponentV2_Custom.SuperClass.OnDisuseItemV2(self, ItemDefineID);
-- end

---func 物品能否附加到此背包槽位(服务端调用)
---@param SlotName string 槽位名称Tag
---@param ItemDefineID userdata 物品DefineID
---@return bool 能否附加
-- function BP_BackpackComponentV2_Custom:CanAttachToSlot(SlotName, ItemDefineID)
--     return BP_BackpackComponentV2_Custom.SuperClass.CanAttachToSlot(self, SlotName, ItemDefineID);
-- end

---func 物品附加到背包槽位后回调(服务端调用)
---@param SlotName string 槽位名称Tag
---@param ItemDefineID userdata 物品DefineID
-- function BP_BackpackComponentV2_Custom:OnAttachToSlot(SlotName, ItemDefineID)
--     BP_BackpackComponentV2_Custom.SuperClass.OnAttachToSlot(self, SlotName, ItemDefineID);
-- end

---func 物品从背包槽位移除后回调(服务端调用)
---@param SlotName string 槽位名称Tag
---@param ItemDefineID userdata 物品DefineID
-- function BP_BackpackComponentV2_Custom:OnDetachBySlot(SlotName, ItemDefineID)
--     BP_BackpackComponentV2_Custom.SuperClass.OnDetachBySlot(self, SlotName, ItemDefineID);
-- end

---func 处理超过格子容量的物品(服务端调用) 物品在进入背包后，如果数量超过格子容量，会调用此函数处理。比如在丢弃了背包后，背包中的物品数量溢出，需要调用此函数处理
---@param ItemDefineID userdata 物品DefineID
---@param Count number 溢出物品数量
-- function BP_BackpackComponentV2_Custom:HandleExceedCellCapacity(ItemDefineID, Count)
--     BP_BackpackComponentV2_Custom.SuperClass.HandleExceedCellCapacity(self, ItemDefineID, Count);
-- end

function BP_BackpackComponentV2_Custom:OnUseItemV2(ItemDefineID)
    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.OnUseItemV2 ~= nil then
        BP_BackpackComponentV2_Custom.SuperClass.OnUseItemV2(self, ItemDefineID)
    end
    SetEquippedWeaponFromDefineID(self, ItemDefineID)
end

function BP_BackpackComponentV2_Custom:OnDisuseItemV2(ItemDefineID)
    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.OnDisuseItemV2 ~= nil then
        BP_BackpackComponentV2_Custom.SuperClass.OnDisuseItemV2(self, ItemDefineID)
    end
    ClearEquippedWeaponFromDefineID(self, ItemDefineID)
end

function BP_BackpackComponentV2_Custom:OnAttachToSlot(SlotName, ItemDefineID)
    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.OnAttachToSlot ~= nil then
        BP_BackpackComponentV2_Custom.SuperClass.OnAttachToSlot(self, SlotName, ItemDefineID)
    end
    SetEquippedWeaponFromDefineID(self, ItemDefineID)
end

function BP_BackpackComponentV2_Custom:OnDetachBySlot(SlotName, ItemDefineID)
    if BP_BackpackComponentV2_Custom.SuperClass ~= nil and BP_BackpackComponentV2_Custom.SuperClass.OnDetachBySlot ~= nil then
        BP_BackpackComponentV2_Custom.SuperClass.OnDetachBySlot(self, SlotName, ItemDefineID)
    end
    ClearEquippedWeaponFromDefineID(self, ItemDefineID)
end

return BP_BackpackComponentV2_Custom
