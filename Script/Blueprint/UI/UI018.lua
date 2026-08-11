---@class UI018_C:UUserWidget
---@field Btn_Close UButton
---@field Button_0 UButton
---@field Button_1 UButton
---@field Button_2 UButton
---@field Button_81 UButton
---@field Button_83 UButton
---@field Button_84 UButton
---@field Button_85 UButton
---@field Button_86 UButton
---@field Button_87 UButton
---@field Button_88 UButton
---@field Button_89 UButton
---@field Button_90 UButton
---@field Button_91 UButton
---@field Button_92 UButton
---@field Button_93 UButton
---@field Button_94 UButton
---@field Button_95 UButton
---@field Button_96 UButton
---@field Button_97 UButton
---@field Button_219 UButton
---@field Button_342 UButton
---@field Button_428 UButton
---@field CheckBox_0 UCheckBox
---@field CheckBox_1 UCheckBox
---@field CheckBox_2 UCheckBox
---@field CheckBox_3 UCheckBox
---@field Image_0 UImage
---@field Image_19 UImage
---@field Image_22 UImage
---@field Image_23 UImage
---@field Image_26 UImage
---@field Image_55 UImage
---@field Image_56 UImage
---@field Image_57 UImage
---@field Image_58 UImage
---@field Image_59 UImage
---@field Image_60 UImage
---@field Image_61 UImage
---@field Image_62 UImage
---@field Image_63 UImage
---@field Image_64 UImage
---@field Image_65 UImage
---@field Image_66 UImage
---@field Image_67 UImage
---@field Image_68 UImage
---@field Image_69 UImage
---@field Image_70 UImage
---@field Image_71 UImage
---@field Image_72 UImage
---@field Image_73 UImage
---@field Image_74 UImage
---@field Image_75 UImage
---@field Image_76 UImage
---@field Image_77 UImage
---@field Image_78 UImage
---@field Image_79 UImage
---@field Image_80 UImage
---@field Image_81 UImage
---@field Image_82 UImage
---@field Image_83 UImage
---@field Image_84 UImage
---@field Image_85 UImage
---@field Image_86 UImage
---@field Image_87 UImage
---@field Image_88 UImage
---@field Image_89 UImage
---@field Image_90 UImage
---@field Image_91 UImage
---@field Image_92 UImage
---@field Image_93 UImage
---@field Image_94 UImage
---@field Image_95 UImage
---@field Image_96 UImage
---@field Image_97 UImage
---@field Image_98 UImage
---@field Image_99 UImage
---@field Image_100 UImage
---@field Image_101 UImage
---@field Image_102 UImage
---@field Image_103 UImage
---@field Image_104 UImage
---@field Image_105 UImage
---@field Image_106 UImage
---@field Image_107 UImage
---@field Image_108 UImage
---@field Image_109 UImage
---@field Image_110 UImage
---@field Image_192 UImage
---@field Image_358 UImage
---@field Image_375 UImage
--Edit Below--
---@class UI15_C:UUserWidget
---@field Btn_Close UButton
---@field WrapBox_0 UWrapBox

local UI018 = { bInitDoOnce = false }

local SOUL_RING_ITEM_IDS = {
    8310048, 8310049, 8310051, 8310053, 8310054, 8310055, 8310056, 8310057, 8310052, 8310050,
    8310122, 8310123, 8310124, 8310125, 8310126, 8310127, 8310128, 8310129, 8310130, 8310131
}

local SOUL_RING_ITEM_ID_SET = {}
for _, ItemID in ipairs(SOUL_RING_ITEM_IDS) do
    SOUL_RING_ITEM_ID_SET[ItemID] = true
end

local PROJECT_ROOT_PATH = UGCMapInfoLib.GetRootLongPackagePath()

local function SafeGetField(Data, FieldName)
    if Data == nil then
        return nil
    end
    local Success, Value = pcall(function()
        return Data[FieldName]
    end)
    if Success then
        return Value
    end
    return nil
end

function UI018:GetWidget(Name)
    local Widget = self[Name]
    if Widget == nil and self.GetWidgetFromName ~= nil then
        Widget = self:GetWidgetFromName(Name)
    end
    return Widget
end

function UI018:Construct()
    self:LuaInit()
end

function UI018:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    local CloseButton = self:GetWidget("Btn_Close")
    if CloseButton ~= nil then
        CloseButton.OnClicked:Add(self.Btn_Close_OnClicked, self)
    end
end

function UI018:Open()
    self:SetVisibility(ESlateVisibility.Visible)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestSoulRingInventory")
    end
end

function UI018:Btn_Close_OnClicked()
    self:Close()
end

function UI018:Close()
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI018:GetSoulRingGrid()
    return self:GetWidget("WrapBox_0")
end

function UI018:GetSoulRingTableRows()
    if self.SoulRingTableRows ~= nil then
        return self.SoulRingTableRows
    end

    self.SoulRingTableRows = {}
    local Success, ObjectTable = pcall(UGCGameSystem.GetTableData, "Data/Table/UGCObject")
    if Success and ObjectTable ~= nil then
        for _, Row in pairs(ObjectTable) do
            local ItemID = tonumber(SafeGetField(Row, "ItemID"))
            if ItemID ~= nil and SOUL_RING_ITEM_ID_SET[ItemID] then
                self.SoulRingTableRows[ItemID] = Row
            end
        end
    end
    return self.SoulRingTableRows
end

function UI018:GetSoulRingName(ItemID, Row)
    if UGCItemSystemV2 ~= nil and UGCItemSystemV2.GetItemNameV2 ~= nil then
        local Success, ItemName = pcall(UGCItemSystemV2.GetItemNameV2, ItemID)
        if Success and ItemName ~= nil and tostring(ItemName) ~= "" then
            return tostring(ItemName)
        end
    end

    local Name = SafeGetField(Row, "ItemName")
    if Name ~= nil and tostring(Name) ~= "" then
        return tostring(Name)
    end
    return "Soul Ring " .. tostring(ItemID)
end

function UI018:GetItemIDFromDefineID(ItemDefineID)
    if ItemDefineID == nil then
        return nil
    end
    if type(ItemDefineID) == "number" or type(ItemDefineID) == "string" then
        return tonumber(ItemDefineID)
    end

    for _, FieldName in ipairs({"TypeSpecificID", "ItemID", "ID"}) do
        local ItemID = tonumber(SafeGetField(ItemDefineID, FieldName))
        if ItemID ~= nil then
            return ItemID
        end
    end
    return nil
end

function UI018:GetSoulRingsFromBackpackV2(PlayerPawn)
    local Result = {}
    if PlayerPawn == nil or UGCBackpackSystemV2 == nil or UGCBackpackSystemV2.GetAllItemDefineIDsV2 == nil then
        return Result
    end

    local Success, AllDefineIDs = pcall(UGCBackpackSystemV2.GetAllItemDefineIDsV2, PlayerPawn)
    if not Success or AllDefineIDs == nil then
        return Result
    end

    for _, ItemDefineID in pairs(AllDefineIDs) do
        local ItemID = self:GetItemIDFromDefineID(ItemDefineID)
        if ItemID ~= nil and SOUL_RING_ITEM_ID_SET[ItemID] then
            local Count = 1
            if UGCBackpackSystemV2.GetItemCountByDefineIDV2 ~= nil then
                local CountSuccess, CountValue, CountValue2 = pcall(
                    UGCBackpackSystemV2.GetItemCountByDefineIDV2, PlayerPawn, ItemDefineID)
                if CountSuccess then
                    Count = tonumber(CountValue2) or tonumber(CountValue) or 1
                end
            end
            if Count > 0 then
                Result[ItemID] = Result[ItemID] or { Count = 0 }
                Result[ItemID].Count = Result[ItemID].Count + Count
            end
        end
    end
    return Result
end

function UI018:GetSoulRingsFromLegacyBackpack(PlayerPawn)
    local Result = {}
    if PlayerPawn == nil or UGCBackPackSystem == nil or UGCBackPackSystem.GetAllItemData == nil then
        return Result
    end

    local Success, AllItemData = pcall(UGCBackPackSystem.GetAllItemData, PlayerPawn)
    if not Success or AllItemData == nil then
        return Result
    end

    for _, ItemData in pairs(AllItemData) do
        local ItemID = tonumber(SafeGetField(ItemData, "ItemID"))
        local Count = tonumber(SafeGetField(ItemData, "Count")) or 0
        if ItemID ~= nil and Count > 0 and SOUL_RING_ITEM_ID_SET[ItemID] then
            Result[ItemID] = { Count = Count }
        end
    end
    return Result
end

function UI018:GetSoulRingsInBackpack(PlayerPawn)
    local Result = self:GetSoulRingsFromBackpackV2(PlayerPawn)
    if next(Result) ~= nil then
        return Result
    end
    return self:GetSoulRingsFromLegacyBackpack(PlayerPawn)
end

function UI018:ParseSoulRingInventorySnapshot(Snapshot)
    local Result = {}
    for Entry in string.gmatch(tostring(Snapshot or ""), "[^,]+") do
        local ItemIDText, CountText = string.match(Entry, "^(%d+):(%d+)$")
        local ItemID = tonumber(ItemIDText)
        local Count = tonumber(CountText) or 0
        if ItemID ~= nil and Count > 0 and SOUL_RING_ITEM_ID_SET[ItemID] then
            Result[ItemID] = { Count = Count }
        end
    end
    return Result
end

function UI018:ApplySoulRingInventorySnapshot(Snapshot)
    self:RefreshSoulRingList(self:ParseSoulRingInventorySnapshot(Snapshot))
end

function UI018:GetSoulRingIconPath(ItemID, Row)
    local IconReference = nil
    if UGCItemSystemV2 ~= nil and UGCItemSystemV2.GetItemIconTextureV2 ~= nil then
        local Success, ItemIcon = pcall(UGCItemSystemV2.GetItemIconTextureV2, ItemID)
        if Success then
            IconReference = ItemIcon
        end
    end
    if IconReference == nil then
        IconReference = SafeGetField(Row, "ItemSmallIcon")
    end

    if IconReference ~= nil and KismetSystemLibrary ~= nil then
        local Path = KismetSystemLibrary.BreakSoftObjectPath(IconReference)
        if Path ~= nil and tostring(Path) ~= "" then
            Path = tostring(Path)
            if string.find(Path, "Asset/") == 1 then
                return PROJECT_ROOT_PATH .. Path
            end
            return Path
        end
    end
    return ""
end

function UI018:RefreshSoulRingList(SoulRingSnapshot)
    local Grid = self:GetSoulRingGrid()
    if Grid == nil then
        ugcprint("[UI018:RefreshSoulRingList] WrapBox_0 is nil")
        return
    end

    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        ugcprint("[UI018:RefreshSoulRingList] local player pawn is nil")
        return
    end

    local CellPath = PROJECT_ROOT_PATH .. "Asset/Blueprint/UI/wq1.wq1_C"
    local CellClass = UE.LoadClass(CellPath)
    if CellClass == nil then
        ugcprint("[UI018:RefreshSoulRingList] wq1 class load failed: " .. CellPath)
        return
    end

    local PlayerController = UGCGameSystem.GetLocalPlayerController()
        or GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    local BackpackSoulRings = SoulRingSnapshot or self:GetSoulRingsInBackpack(PlayerPawn)
    local TableRows = self:GetSoulRingTableRows()

    Grid:ClearChildren()
    self.SoulRingCells = {}
    self.SelectedSoulRingCell = nil
    local CreatedCount = 0

    for _, ItemID in ipairs(SOUL_RING_ITEM_IDS) do
        local BackpackData = BackpackSoulRings[ItemID]
        if BackpackData ~= nil then
            local Row = TableRows[ItemID]
            local Cell = UserWidget.NewWidgetObjectBP(PlayerController, CellClass)
            if Cell ~= nil then
                local Slot = Grid:AddChild(Cell)
                if Slot ~= nil and Slot.SetPadding ~= nil then
                    Slot:SetPadding({ Left = 15.0, Top = 0.0, Right = 15.0, Bottom = 10.0 })
                end
                Cell:SetVisibility(ESlateVisibility.Visible)
                Cell:SetSoulRingData({
                    ItemID = ItemID,
                    Count = BackpackData.Count,
                    Name = self:GetSoulRingName(ItemID, Row),
                    IconPath = self:GetSoulRingIconPath(ItemID, Row)
                }, self)
                table.insert(self.SoulRingCells, Cell)
                CreatedCount = CreatedCount + 1
                local bAdded = Grid.HasChild ~= nil and Grid:HasChild(Cell) or false
                ugcprint("[UI018:RefreshSoulRingList] cell item=" .. tostring(ItemID) ..
                    " slot=" .. tostring(Slot ~= nil) .. " added=" .. tostring(bAdded))
            end
        end
    end
    Grid:SetVisibility(ESlateVisibility.Visible)
    if self.ScrollBox_254 ~= nil then
        self.ScrollBox_254:SetVisibility(ESlateVisibility.Visible)
    end
    if self.ForceLayoutPrepass ~= nil then
        self:ForceLayoutPrepass()
    end
    local ChildCount = Grid.GetChildrenCount ~= nil and Grid:GetChildrenCount() or -1
    ugcprint("[UI018:RefreshSoulRingList] created=" .. tostring(CreatedCount) ..
        " children=" .. tostring(ChildCount))
end

function UI018:SelectSoulRing(SelectedCell)
    for _, Cell in ipairs(self.SoulRingCells or {}) do
        Cell:SetSelected(Cell == SelectedCell)
    end
    self.SelectedSoulRingCell = SelectedCell
end

return UI018