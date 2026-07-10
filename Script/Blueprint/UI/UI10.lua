---@class UI10_C:UUserWidget
---@field Button_125 UButton
---@field button_dz UButton
---@field Image_66 UImage
---@field Image_112 UImage
---@field Image_180 UImage
---@field Image_181 UImage
---@field Image_297 UImage
---@field Image_299 UImage
---@field Image_814 UImage
---@field Image_982 UImage
---@field Image_985 UImage
---@field Image_986 UImage
---@field left_cl UImage
---@field NewUGCWidgetBlueprint NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_0 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_1 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_2 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_3 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_4 NewUGCWidgetBlueprint_C
---@field right_cl UImage
---@field text_bb UTextBlock
---@field text_cg UTextBlock
---@field text_hgrj UTextBlock
---@field text_jj UTextBlock
---@field text_name_1 UTextBlock
---@field text_qnhh UTextBlock
---@field TextBlock_297 UTextBlock
--Edit Below--
-- 武器锻造 UI：负责读取背包武器、显示材料消耗，并向服务器发起锻造请求。
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local UI10 = { bInitDoOnce = false }

-- 锻造材料道具 ID。
local MaterialItemIDs = {
    HGRJ = 8310035,
    QNHH = 8310036,
}

-- UI 固定文案，使用 char 避免部分编辑器保存中文时乱码。
local TextLabels = {
    Success = string.char(230, 136, 144, 229, 138, 159, 239, 188, 154),
    Keep = string.char(228, 191, 157, 230, 140, 129, 228, 184, 141, 229, 143, 152, 239, 188, 154),
    Down = string.char(233, 153, 141, 231, 186, 167, 239, 188, 154),
    AttackBonus = string.char(230, 148, 187, 229, 135, 187, 229, 138, 160, 230, 136, 144),
    OpenParen = string.char(239, 188, 136),
    CloseParen = string.char(239, 188, 137),
}

-- 武器品质显示名称。
local LevelLabels = {
    [1] = string.char(230, 153, 174, 233, 128, 154),
    [2] = string.char(228, 188, 152, 231, 167, 128),
    [3] = string.char(231, 178, 190, 232, 137, 175),
    [4] = string.char(229, 143, 178, 232, 175, 151),
    [5] = string.char(228, 188, 160, 232, 175, 180),
}

-- 武器系列显示名称。
local WeaponNameLabels = {
    XJWQ = "血狱裁魂刃",
    HWSCJ = "沧澜裂海戟",
    HTC = "星陨昊锤",
    LCSL = "影罗夺命镰",
    TSSJ = "璀羽圣金剑",
}

-- 武器系列对应的展示图标。
local WeaponUIConfig = {
    XJWQ = {
        DefaultName = "XJWQ",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/XJWQ/XSWQ_B.XSWQ_B",
    },
    HWSCJ = {
        DefaultName = "HWSCJ",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/HWSCJ_B.HWSCJ_B",
    },
    HTC = {
        DefaultName = "HTC",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/HTC/HTC_T1.HTC_T1",
    },
    LCSL = {
        DefaultName = "LCSL",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/LCSL/LCSL_T.LCSL_T",
    },
    TSSJ = {
        DefaultName = "TSSJ",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/TSSJ/TSSJ_B.TSSJ_B",
    },
}

function UI10:Construct()
    self:LuaInit()
end

-- 只初始化一次按钮事件和默认武器显示。
function UI10:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    if self.Button_125 ~= nil then
        self.Button_125.OnClicked:Add(self.Button_125_OnClicked, self)
        UIEffectUtil.BindPressScale(self, self.Button_125, self.Button_125, 1.06, 1.0)
    end
    if self.button_dz ~= nil then
        self.button_dz.OnClicked:Add(self.Button_dz_OnClicked, self)
        UIEffectUtil.BindPressScale(self, self.button_dz, self.button_dz, 1.06, 1.0)
    end

    self:InitWeaponWidgets()
end

-- 关闭界面时只隐藏实例，方便下次打开复用。
function UI10:Button_125_OnClicked()
    self:SetVisibility(ESlateVisibility.Collapsed)
end

-- 从背包刷新底部武器格子，并默认选中第一把可锻造武器。
function UI10:InitWeaponWidgets()
    local Widgets = self:GetWeaponWidgets()
    local WeaponList = self:GetBackpackWeaponList()
    for Index, Widget in ipairs(Widgets) do
        local WeaponInfo = WeaponList[Index]
        if Widget ~= nil then
            if WeaponInfo ~= nil and Widget.SetWeaponData ~= nil then
                Widget:SetWeaponData(WeaponInfo.Name, WeaponInfo.IconPath, self, WeaponInfo.ItemID)
            elseif Widget.ClearWeaponData ~= nil then
                Widget:ClearWeaponData()
            else
                Widget:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end

    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].ItemID)
    else
        self:SelectWeapon(nil, nil, nil)
    end
end

-- UI10 蓝图中预摆放的 5 个武器格子。
function UI10:GetWeaponWidgets()
    return {
        self.NewUGCWidgetBlueprint_C_0,
        self.NewUGCWidgetBlueprint_C_1,
        self.NewUGCWidgetBlueprint_C_2,
        self.NewUGCWidgetBlueprint_C_3,
        self.NewUGCWidgetBlueprint_C_4,
    }
end

-- 读取本地背包武器；同系列有多把时只展示最高等级。
function UI10:GetBackpackWeaponList()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        return {}
    end
    local BestWeaponBySeries = {}
    for SeriesKey, SeriesData in pairs(WeaponLevelConfig.Series) do
        for Level, ItemID in ipairs(SeriesData.ItemIDs) do
            if self:GetBackpackItemCount(PlayerPawn, ItemID) > 0 then
                local CurrentWeapon = BestWeaponBySeries[SeriesKey]
                if CurrentWeapon == nil or Level > CurrentWeapon.Level then
                    BestWeaponBySeries[SeriesKey] = {
                        ItemID = ItemID,
                        Level = Level,
                        SeriesKey = SeriesKey,
                    }
                end
            end
        end
    end
    local Result = {}
    local SeriesOrder = { "XJWQ", "HWSCJ", "HTC", "LCSL", "TSSJ" }
    for _, SeriesKey in ipairs(SeriesOrder) do
        local BackpackWeapon = BestWeaponBySeries[SeriesKey]
        local UIConfig = WeaponUIConfig[SeriesKey]
        if BackpackWeapon ~= nil and UIConfig ~= nil then
            table.insert(Result, {
                Name = self:GetWeaponDisplayName(BackpackWeapon.SeriesKey, BackpackWeapon.Level),
                IconPath = UIConfig.IconPath,
                ItemID = BackpackWeapon.ItemID,
            })
        end
    end
    return Result
end

-- 武器名由系列名和品质名拼成，例如“星陨昊锤（史诗）”。
function UI10:GetWeaponDisplayName(SeriesKey, Level)
    local WeaponName = WeaponNameLabels[SeriesKey] or tostring(SeriesKey)
    local LevelName = LevelLabels[tonumber(Level)] or tostring(Level)
    return WeaponName .. TextLabels.OpenParen .. LevelName .. TextLabels.CloseParen
end

-- 优先从背包数据或道具配置取名字，取不到才使用默认名。
function UI10:GetBackpackItemName(ItemData, ItemID, DefaultName)
    local Name = self:GetNameFromItemData(ItemData)
    if Name == nil then
        Name = self:GetNameFromItemConfig(ItemID)
    end
    if Name == nil or tostring(Name) == "" then
        return DefaultName
    end
    return tostring(Name)
end

-- 兼容不同数据表里的道具名称字段。
function UI10:GetNameFromItemData(ItemData)
    if ItemData == nil then
        return nil
    end

    local Name =
        ItemData.ItemName
        or ItemData.Name
        or ItemData.DisplayName
        or ItemData.ItemDisplayName
        or ItemData.ItemNameText

    if Name ~= nil then
        return Name
    end

    local NestedData =
        ItemData.ItemData
        or ItemData.ItemConfig
        or ItemData.Config
        or ItemData.ItemDefine
        or ItemData.ItemTableData

    if NestedData == nil then
        return nil
    end

    return NestedData.ItemName
        or NestedData.Name
        or NestedData.DisplayName
        or NestedData.ItemDisplayName
        or NestedData.ItemNameText
end

-- 通过 ItemID 尝试读取道具配置名称。
function UI10:GetNameFromItemConfig(ItemID)
    if ItemID == nil then
        return nil
    end

    local ConfigData = self:TryGetBackpackItemConfig(ItemID)
    local Name = self:GetNameFromItemData(ConfigData)
    if Name ~= nil then
        return Name
    end

    ConfigData = self:TryGetVirtualItemConfig(ItemID)
    return self:GetNameFromItemData(ConfigData)
end

-- 不同编辑器或运行时版本可能暴露不同的背包配置接口。
function UI10:TryGetBackpackItemConfig(ItemID)
    local FunctionNames = {
        "GetItemData",
        "GetItemConfigData",
        "GetItemDataByItemID",
        "GetItemDefine",
    }

    for _, FunctionName in ipairs(FunctionNames) do
        local Func = UGCBackPackSystem[FunctionName]
        if Func ~= nil then
            local Success, Result = pcall(Func, ItemID)
            if Success and Result ~= nil then
                return Result
            end
        end
    end

    return nil
end

-- 官方虚拟道具配置兜底读取。
function UI10:TryGetVirtualItemConfig(ItemID)
    local VirtualItemManager = self:GetVirtualItemManager()
    if VirtualItemManager == nil or VirtualItemManager.GetItemData == nil then
        return nil
    end

    local Success, Result = pcall(VirtualItemManager.GetItemData, VirtualItemManager, ItemID)
    if Success then
        return Result
    end

    return nil
end

-- 获取全局虚拟道具管理器。
function UI10:GetVirtualItemManager()
    if UGCBlueprintFunctionLibrary == nil or UGCGameSystem.GameState == nil then
        return nil
    end

    return UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager")
end

-- 更新顶部选中武器的名字、图标，并刷新锻造信息。
function UI10:SelectWeapon(WeaponName, IconPath, ItemID)
    self.SelectedWeaponName = WeaponName
    self.SelectedWeaponIconPath = IconPath
    self.SelectedWeaponItemID = ItemID

    if self.text_name_1 ~= nil then
        self.text_name_1:SetText(WeaponName or "")
    end

    self:RefreshForgeInfo()

    if self.Image_299 == nil or IconPath == nil then
        return
    end

    local IconTexture = UE.LoadObject(IconPath)
    if IconTexture == nil then
        return
    end

    self.Image_299:SetBrushFromTexture(IconTexture)
end

-- 刷新材料数量、成功率和当前武器属性加成。
function UI10:RefreshForgeInfo()
    local Cost = WeaponLevelConfig.GetForgeCost(self.SelectedWeaponItemID) or { HGRJ = 0, QNHH = 0 }
    local Rate = WeaponLevelConfig.GetForgeRate(self.SelectedWeaponItemID) or { Success = 0, Keep = 0, Down = 0 }
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local HGRJCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.HGRJ)
    local QNHHCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.QNHH)

    if self.text_hgrj ~= nil then
        self.text_hgrj:SetText(tostring(HGRJCount) .. "/" .. tostring(Cost.HGRJ or 0))
    end
    if self.text_qnhh ~= nil then
        self.text_qnhh:SetText(tostring(QNHHCount) .. "/" .. tostring(Cost.QNHH or 0))
    end
    if self.text_cg ~= nil then
        self.text_cg:SetText(TextLabels.Success .. tostring(Rate.Success or 0) .. "%")
    end
    if self.text_bb ~= nil then
        self.text_bb:SetText(TextLabels.Keep .. tostring(Rate.Keep or 0) .. "%")
    end
    if self.text_jj ~= nil then
        self.text_jj:SetText(TextLabels.Down .. tostring(Rate.Down or 0) .. "%")
    end
    if self.TextBlock_297 ~= nil then
        local Attribute = WeaponLevelConfig.GetTotalAttribute(self.SelectedWeaponItemID) or { AttackPercent = 0 }
        self.TextBlock_297:SetText(TextLabels.AttackBonus .. tostring(Attribute.AttackPercent or 0) .. "%")
    end
end

-- 服务端锻造结果回调后，刷新背包列表并尽量保持当前系列选中。
function UI10:OnForgeWeaponResult(ResultType, OldItemID, ResultItemID)
    OldItemID = tonumber(OldItemID)
    ResultItemID = tonumber(ResultItemID) or OldItemID

    local ResultInfo = WeaponLevelConfig.GetWeaponInfo(ResultItemID)
    local SeriesKey = nil
    if ResultInfo ~= nil then
        SeriesKey = ResultInfo.SeriesKey
    end

    local IconPath = self:GetWeaponIconPathByItemID(ResultItemID) or self.SelectedWeaponIconPath
    self:ShowForgeResultPopup(ResultType, IconPath)

    UGCTimerUtility.CreateLuaTimer(0.2, function()
        if self ~= nil then
            self:InitWeaponWidgets()
            if SeriesKey ~= nil then
                self:SelectWeaponBySeriesKey(SeriesKey)
            elseif ResultItemID ~= nil then
                self:SelectWeaponByItemID(ResultItemID)
            end
        end
    end, false)
end

-- 显示锻造结果弹窗；旧组件没有接口时至少保证弹窗可见。
function UI10:ShowForgeResultPopup(ResultType, IconPath)
    if self.NewUGCWidgetBlueprint == nil then
        return
    end

    if self.NewUGCWidgetBlueprint.ShowForgeResult ~= nil then
        self.NewUGCWidgetBlueprint:ShowForgeResult(ResultType, IconPath)
        return
    end

    self.NewUGCWidgetBlueprint:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

-- 根据武器 ItemID 找到对应系列图标。
function UI10:GetWeaponIconPathByItemID(ItemID)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if WeaponInfo == nil then
        return nil
    end

    local UIConfig = WeaponUIConfig[WeaponInfo.SeriesKey]
    if UIConfig == nil then
        return nil
    end

    return UIConfig.IconPath
end

-- 点击锻造：先做本地材料和武器检查，再请求服务器执行锻造。
function UI10:Button_dz_OnClicked()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local ItemID = tonumber(self.SelectedWeaponItemID)
    if PlayerPawn == nil or ItemID == nil then
        return
    end

    local Cost = WeaponLevelConfig.GetForgeCost(ItemID)
    if Cost == nil then
        return
    end

    local HGRJCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.HGRJ)
    local QNHHCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.QNHH)
    if HGRJCount < (Cost.HGRJ or 0) or QNHHCount < (Cost.QNHH or 0) then
        self:RefreshForgeInfo()
        return
    end

    if self:GetBackpackItemCount(PlayerPawn, ItemID) <= 0 then
        self:InitWeaponWidgets()
        return
    end

    local PlayerController = self:GetLocalPlayerController()
    if PlayerController == nil then
        return
    end

    local SelectedWeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    local SelectedSeriesKey = nil
    if SelectedWeaponInfo ~= nil then
        SelectedSeriesKey = SelectedWeaponInfo.SeriesKey
    end

    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_ForgeWeapon", ItemID)
    UGCTimerUtility.CreateLuaTimer(0.5, function()
        if self ~= nil then
            self:InitWeaponWidgets()
            if SelectedSeriesKey ~= nil then
                self:SelectWeaponBySeriesKey(SelectedSeriesKey)
            end
        end
    end, false)
end

-- 本地消耗锻造材料和替换武器的兜底逻辑。
function UI10:ConsumeForgeItems(PlayerPawn, OldItemID, NewItemID, Cost)
    if not self:TryRemoveBackpackItem(PlayerPawn, MaterialItemIDs.HGRJ, Cost.HGRJ or 0) then
        return false
    end
    if not self:TryRemoveBackpackItem(PlayerPawn, MaterialItemIDs.QNHH, Cost.QNHH or 0) then
        UGCBackpackSystemV2.AddItemV2(PlayerPawn, MaterialItemIDs.HGRJ, Cost.HGRJ or 0)
        return false
    end
    if NewItemID ~= OldItemID then
        if not self:TryRemoveBackpackItem(PlayerPawn, OldItemID, 1) then
            UGCBackpackSystemV2.AddItemV2(PlayerPawn, MaterialItemIDs.HGRJ, Cost.HGRJ or 0)
            UGCBackpackSystemV2.AddItemV2(PlayerPawn, MaterialItemIDs.QNHH, Cost.QNHH or 0)
            return false
        end
        UGCBackpackSystemV2.AddItemV2(PlayerPawn, NewItemID, 1)
    end

    return true
end

-- 兼容背包系统和虚拟道具系统的移除接口。
function UI10:TryRemoveBackpackItem(PlayerPawn, ItemID, Count)
    Count = tonumber(Count) or 0
    if Count <= 0 then
        return true
    end

    if PlayerPawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.RemoveItemV2 ~= nil then
        local Success, Result = pcall(UGCBackpackSystemV2.RemoveItemV2, PlayerPawn, ItemID, Count)
        if Success and Result ~= false and Result ~= 0 then
            return true
        end
    end

    local VirtualItemManager = self:GetVirtualItemManager()
    if VirtualItemManager ~= nil and VirtualItemManager.RemoveItem ~= nil then
        local Success, Result = pcall(VirtualItemManager.RemoveItem, VirtualItemManager, PlayerPawn, ItemID, Count)
        if Success and Result ~= false then
            return true
        end
        local PlayerController = self:GetLocalPlayerController()
        if PlayerController ~= nil then
            Success, Result = pcall(VirtualItemManager.RemoveItem, VirtualItemManager, PlayerController, ItemID, Count)
            if Success and Result ~= false then
                return true
            end
        end
    end

    return false
end

-- 获取本地 PlayerController，兼容 UGCGameSystem 和 Pawn 两种路径。
function UI10:GetLocalPlayerController()
    if UGCGameSystem.GetLocalPlayerController ~= nil then
        local Success, Result = pcall(UGCGameSystem.GetLocalPlayerController)
        if Success then
            return Result
        end
    end

    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil then
        return PlayerPawn.Controller or PlayerPawn.PlayerController
    end

    return nil
end

-- 同时读取背包数量和虚拟道具数量，取较大的值用于显示。
function UI10:GetBackpackItemCount(PlayerPawn, ItemID)
    if ItemID == nil then
        return 0
    end

    local BackpackCount = 0
    if PlayerPawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        BackpackCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerPawn, ItemID)) or 0
    end

    local VirtualCount = 0
    local VirtualItemManager = self:GetVirtualItemManager()
    local PlayerController = self:GetLocalPlayerController()
    if VirtualItemManager ~= nil and VirtualItemManager.GetItemNum ~= nil and PlayerController ~= nil then
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

-- 根据 ItemID 重新选中武器；找不到时回退到第一把。
function UI10:SelectWeaponByItemID(ItemID)
    local WeaponList = self:GetBackpackWeaponList()
    for _, WeaponInfo in ipairs(WeaponList) do
        if WeaponInfo.ItemID == ItemID then
            self:SelectWeapon(WeaponInfo.Name, WeaponInfo.IconPath, WeaponInfo.ItemID)
            return
        end
    end

    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].ItemID)
    else
        self:SelectWeapon(nil, nil, nil)
    end
end

-- 根据武器系列重新选中武器；锻造升降级后用它保持选中系列不跳走。
function UI10:SelectWeaponBySeriesKey(SeriesKey)
    local WeaponList = self:GetBackpackWeaponList()
    for _, WeaponInfo in ipairs(WeaponList) do
        local Info = WeaponLevelConfig.GetWeaponInfo(WeaponInfo.ItemID)
        if Info ~= nil and Info.SeriesKey == SeriesKey then
            self:SelectWeapon(WeaponInfo.Name, WeaponInfo.IconPath, WeaponInfo.ItemID)
            return
        end
    end

    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].ItemID)
    else
        self:SelectWeapon(nil, nil, nil)
    end
end

-- function UI10:Tick(MyGeometry, InDeltaTime)
-- end

-- function UI10:Destruct()
-- end

return UI10
