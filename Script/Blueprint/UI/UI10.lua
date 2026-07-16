---@class UI10_C:UUserWidget
---@field Button_24 UButton
---@field Button_125 UButton
---@field button_dz UButton
---@field GDK UScrollBox
---@field Image_35 UImage
---@field Image_66 UImage
---@field Image_72 UImage
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
---@field NewUGCWidgetBlueprint_C_6 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_7 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_8 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_9 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_10 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_11 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_12 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_13 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_14 NewUGCWidgetBlueprint_C
---@field NewUGCWidgetBlueprint_C_15 NewUGCWidgetBlueprint_C
---@field right_cl UImage
---@field text_bb UTextBlock
---@field text_cg UTextBlock
---@field text_hgrj UTextBlock
---@field text_jj UTextBlock
---@field text_name_1 UTextBlock
---@field text_qnhh UTextBlock
---@field TextBlock_1 UTextBlock
---@field TextBlock_2 UTextBlock
---@field TextBlock_297 UTextBlock
--Edit Below--
-- 武器锻造 UI：负责读取背包武器、显示材料消耗，并向服务器发起锻造请求。
local WeaponLevelConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponLevelConfig")
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")
local UI10 = { bInitDoOnce = false }
local WeaponItemWidgetPath = "Asset/NewUGCWidgetBlueprint.NewUGCWidgetBlueprint_C"
local ForgeResultWidgetPath = "Asset/Blueprint/UI/NewUGCWidgetBlueprint.NewUGCWidgetBlueprint_C"

-- 锻造材料道具 ID。
local MaterialItemIDs = {
    HGRJ = 8310035,
    QNHH = 8310036,
    Protect = 8310121,
}

-- UI 固定文案，使用 char 避免部分编辑器保存中文时乱码。
local TextLabels = {
    Success = string.char(230, 136, 144, 229, 138, 159, 239, 188, 154),
    Keep = string.char(228, 191, 157, 230, 140, 129, 228, 184, 141, 229, 143, 152, 239, 188, 154),
    Down = string.char(233, 153, 141, 231, 186, 167, 239, 188, 154),
    Destroy = string.char(230, 175, 129, 229, 157, 143, 239, 188, 154),
    AttackBonus = string.char(230, 148, 187, 229, 135, 187, 229, 138, 160, 230, 136, 144),
    OpenParen = string.char(239, 188, 136),
    CloseParen = string.char(239, 188, 137),
    MaterialNotEnough = string.char(230, 157, 144, 230, 150, 153, 228, 184, 141, 232, 182, 179),
    ProtectLevelLimit = string.char(230, 173, 166, 229, 153, 168, 49, 48, 45, 49, 52, 231, 186, 167, 229, 143, 175, 228, 189, 191, 231, 148, 168, 228, 191, 157, 230, 138, 164, 229, 141, 183),
    ProtectNotEnough = string.char(230, 178, 161, 230, 156, 137, 229, 188, 186, 229, 140, 150, 228, 191, 157, 230, 138, 164, 229, 141, 183),
}

-- 武器品质显示名称。
-- 武器系列显示名称。
--[[
local WeaponNameLabels = {
    XJWQ = "血狱裁魂刃",
    HWSCJ = "沧澜裂海戟",
    HTC = "星陨昊锤",
    LCSL = "影罗夺命镰",
    TSSJ = "璀羽圣金剑",
}

-- 武器系列对应的展示图标。
]]
local WeaponNameLabels = {
    XJWQ = "XJWQ",
    HWSCJ = "HWSCJ",
    HTC = "HTC",
    LCSL = "LCSL",
    TSSJ = "TSSJ",
}
local WeaponUIConfig = {
    XJWQ = {
        DefaultName = "XJWQ",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/XJWQ/XSWQ_B.XSWQ_B",
    },
    HWSCJ = {
        DefaultName = "HWSCJ",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/image/HWSCJ_T3.HWSCJ_T3",
    },
    HTC = {
        DefaultName = "HTC",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/image/HTC_T3.HTC_T3",
    },
    LCSL = {
        DefaultName = "LCSL",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/LCSL/LCSL_T.LCSL_T",
    },
    TSSJ = {
        DefaultName = "TSSJ",
        IconPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/cs/image/TSSJ_T3.TSSJ_T3",
    },
}

local WeaponIconKeyByWPID = {
    [8310000] = "HWSCJ",
    [8310003] = "TSSJ",
    [8310002] = "HTC",
    [8310004] = "LCSL",
    [8310006] = "XJWQ",
}

local function SortAndIndexWeaponList(WeaponList)
    table.sort(WeaponList, function(Left, Right)
        local LeftSeries = tonumber(Left.SeriesKey) or 0
        local RightSeries = tonumber(Right.SeriesKey) or 0
        if LeftSeries ~= RightSeries then
            return LeftSeries < RightSeries
        end
        local LeftLevel = tonumber(Left.Level) or 1
        local RightLevel = tonumber(Right.Level) or 1
        if LeftLevel ~= RightLevel then
            return LeftLevel < RightLevel
        end
        local LeftItemID = tonumber(Left.ItemID) or 0
        local RightItemID = tonumber(Right.ItemID) or 0
        if LeftItemID ~= RightItemID then
            return LeftItemID < RightItemID
        end
        return tostring(Left.ItemDefineID or "") < tostring(Right.ItemDefineID or "")
    end)
    for Index, WeaponInfo in ipairs(WeaponList) do
        WeaponInfo.SelectKey = Index
    end
    return WeaponList
end

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
    local BoundCount = 0
    if self:BindForgeButton(self.button_dz, "button_dz") then
        BoundCount = BoundCount + 1
    end
    if self:BindForgeButton(self.Button_78, "Button_78") then
        BoundCount = BoundCount + 1
    end
    if self.Button_24 ~= nil and self.Button_24.OnClicked ~= nil then
        self.Button_24.OnClicked:Add(self.Button_24_OnClicked, self)
        UIEffectUtil.BindPressScale(self, self.Button_24, self.Button_24, 1.06, 1.0)
    end
    if BoundCount <= 0 then
        ugcprint("[UI10:LuaInit] Forge button is nil")
    else
        ugcprint("[UI10:LuaInit] Forge button bind count=" .. tostring(BoundCount))
    end

    self:SetForgeProtectSelected(false)
    self:InitWeaponWidgets()
end

function UI10:Open()
    self:LuaInit()
    self.bForgeBackpackSyncPending = false
    self:SetForgeProtectSelected(false)
    self:SetVisibility(ESlateVisibility.Visible)
    self:InitWeaponWidgets()

    local function RefreshAfterOpen(RetriesRemaining)
        if self == nil then
            return
        end

        local PreviousItemID = self:GetItemIDFromDefineID(self.SelectedWeaponDefineID) or tonumber(self.SelectedWeaponItemID)
        local PreviousInfo = WeaponLevelConfig.GetWeaponInfo(PreviousItemID)
        self:InitWeaponWidgets()
        if PreviousInfo ~= nil then
            self:SelectWeaponBySeriesKey(PreviousInfo.SeriesKey)
        end

        if RetriesRemaining > 0 then
            UGCTimerUtility.CreateLuaTimer(0.3, function()
                RefreshAfterOpen(RetriesRemaining - 1)
            end, false)
        end
    end

    UGCTimerUtility.CreateLuaTimer(0.3, function()
        RefreshAfterOpen(3)
    end, false)
end

function UI10:GetForgeButton()
    return self.button_dz or self.Button_78
end

function UI10:BindForgeButton(Button, ButtonName)
    if Button == nil or Button.OnClicked == nil then
        return false
    end
    self.BoundForgeButtons = self.BoundForgeButtons or {}
    if self.BoundForgeButtons[Button] == true then
        return false
    end
    self.BoundForgeButtons[Button] = true
    Button.OnClicked:Add(self.Button_dz_OnClicked, self)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
    ugcprint("[UI10:BindForgeButton] bind " .. tostring(ButtonName))
    return true
end

-- 关闭界面时只隐藏实例，方便下次打开复用。
function UI10:Button_125_OnClicked()
    ugcprint("[UI10:Button_125_OnClicked] Close UI10")
    self:SetForgeProtectSelected(false)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI10:SetForgeProtectSelected(bSelected)
    self.bUseForgeProtect = bSelected == true
    if self.Image_35 ~= nil then
        self.Image_35:SetVisibility(self.bUseForgeProtect and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end
end

function UI10:GetSelectedWeaponLevel()
    local ItemID = self:GetItemIDFromDefineID(self.SelectedWeaponDefineID) or tonumber(self.SelectedWeaponItemID)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    return tonumber(self.SelectedWeaponLevel) or
               self:GetWeaponLevelByDefineID(self.SelectedWeaponDefineID, WeaponInfo, self.SelectedWeaponStackIndex) or 1
end

function UI10:ShowToast(Text)
    if L_Com ~= nil and L_Com.ShowToast ~= nil then
        L_Com.ShowToast(Text)
    end
end

function UI10:Button_24_OnClicked()
    if self.bUseForgeProtect == true then
        self:SetForgeProtectSelected(false)
        return
    end

    local SelectedLevel = self:GetSelectedWeaponLevel()
    if SelectedLevel < 10 or SelectedLevel > 14 then
        self:ShowToast(TextLabels.ProtectLevelLimit)
        self:SetForgeProtectSelected(false)
        return
    end

    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.Protect) <= 0 then
        self:ShowToast(TextLabels.ProtectNotEnough)
        self:SetForgeProtectSelected(false)
        return
    end

    self:SetForgeProtectSelected(true)
end

-- 从背包刷新底部武器格子，并默认选中第一把可锻造武器。
function UI10:InitWeaponWidgets()
    local WeaponList = self:GetBackpackWeaponList()
    self.WeaponList = WeaponList

    self.DynamicWeaponWidgets = nil
    self:SetPresetWeaponWidgetsVisible(true)
    self:HideExtraPresetWeaponWidgets()
    local Widgets = self:GetWeaponWidgets()
    local DebugText = "[UI10:InitWeaponWidgets] BackpackWeaponCount=" .. tostring(#WeaponList) .. ", PresetWidgetCount=" .. tostring(#Widgets)
    ugcprint(DebugText)
    for Index = 1, #Widgets do
        local Widget = Widgets[Index]
        local WeaponInfo = WeaponList[Index]
        if Widget ~= nil then
            if WeaponInfo ~= nil then
                self:ApplyWeaponWidgetData(Widget, WeaponInfo, Index)
            elseif Widget.ClearWeaponData ~= nil then
                Widget:ClearWeaponData()
            else
                Widget:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end

    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].SelectKey or 1, WeaponList[1])
    else
        self:SelectWeapon(nil, nil, nil)
    end
end

-- UI10 蓝图中预摆放的 5 个武器格子。
function UI10:ApplyWeaponWidgetData(Widget, WeaponInfo, Index)
    if Widget == nil or WeaponInfo == nil then
        return
    end

    if Widget.SetWeaponData ~= nil then
        Widget:SetWeaponData(WeaponInfo.Name, WeaponInfo.IconPath, self, WeaponInfo.ItemID, WeaponInfo)
    end

    Widget.WeaponName = WeaponInfo.Name
    Widget.IconPath = WeaponInfo.IconPath
    Widget.OwnerUI = self
    Widget.ItemID = WeaponInfo.ItemID
    Widget.WeaponInstance = WeaponInfo

    if Widget.SetVisibility ~= nil then
        Widget:SetVisibility(ESlateVisibility.Visible)
    end
    if Widget.text_name ~= nil then
        Widget.text_name:SetText(WeaponInfo.Name or "")
    end
    local IconTexture = nil
    if WeaponInfo.IconPath ~= nil then
        IconTexture = UE.LoadObject(WeaponInfo.IconPath)
    end
    if IconTexture == nil then
        ugcprint("[UI10:ApplyWeaponWidgetData] Icon load failed: " .. tostring(WeaponInfo.IconPath))
        return
    end

    if Widget.Button_97 ~= nil and Widget.SetButtonTexture ~= nil then
        Widget:SetButtonTexture(Widget.Button_97, IconTexture)
    elseif Widget.Button_97 ~= nil and Widget.Button_97.WidgetStyle ~= nil then
        self:SetWidgetBrushTexture(Widget.Button_97.WidgetStyle.Normal, IconTexture)
        self:SetWidgetBrushTexture(Widget.Button_97.WidgetStyle.Hovered, IconTexture)
        self:SetWidgetBrushTexture(Widget.Button_97.WidgetStyle.Pressed, IconTexture)
        if Widget.Button_97.SetStyle ~= nil then
            Widget.Button_97:SetStyle(Widget.Button_97.WidgetStyle)
        end
    end
end

function UI10:SetPresetWeaponWidgetsVisible(bVisible)
    local Visibility = bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed
    local Widgets = self:GetAllPresetWeaponWidgets()
    for Index = 1, #Widgets do
        local Widget = Widgets[Index]
        if Widget ~= nil and Widget.SetVisibility ~= nil then
            Widget:SetVisibility(Visibility)
        end
    end
end

function UI10:SetWidgetBrushTexture(Brush, Texture)
    if Brush == nil or Texture == nil then
        return
    end
    Brush.ResourceObject = Texture
    if Brush.TintColor ~= nil and Brush.TintColor.SpecifiedColor ~= nil then
        Brush.TintColor.SpecifiedColor.A = 1.0
    end
end

function UI10:GetWeaponItemWidgetClass()
    if self.WeaponItemWidgetClass ~= nil then
        return self.WeaponItemWidgetClass
    end

    local FullPath = nil
    if UGCMapInfoLib ~= nil and UGCMapInfoLib.GetRootLongPackagePath ~= nil then
        FullPath = UGCMapInfoLib.GetRootLongPackagePath() .. WeaponItemWidgetPath
    end

    if FullPath == nil then
        ugcprint("[UI10:GetWeaponItemWidgetClass] path is nil")
        return nil
    end

    local WidgetClass = UE.LoadClass(FullPath)
    if WidgetClass == nil then
        ugcprint("[UI10:GetWeaponItemWidgetClass] load failed: " .. tostring(FullPath))
        return nil
    end

    self.WeaponItemWidgetClass = WidgetClass
    return WidgetClass
end

function UI10:GetWeaponWidgets()
    local AllWidgets = self:GetAllPresetWeaponWidgets()
    local Widgets = {}
    for Index = 1, #AllWidgets do
        if #Widgets >= 10 then
            break
        end
        table.insert(Widgets, AllWidgets[Index])
    end

    return Widgets
end

function UI10:GetAllPresetWeaponWidgets()
    local Widgets = {}
    local function AddWidget(Widget)
        if Widget ~= nil then
            table.insert(Widgets, Widget)
        end
    end

    AddWidget(self.NewUGCWidgetBlueprint_C_0)
    AddWidget(self.NewUGCWidgetBlueprint_C_1)
    AddWidget(self.NewUGCWidgetBlueprint_C_2)
    AddWidget(self.NewUGCWidgetBlueprint_C_3)
    AddWidget(self.NewUGCWidgetBlueprint_C_4)
    AddWidget(self.NewUGCWidgetBlueprint_C_5)
    AddWidget(self.NewUGCWidgetBlueprint_C_6)
    AddWidget(self.NewUGCWidgetBlueprint_C_7)
    AddWidget(self.NewUGCWidgetBlueprint_C_8)
    AddWidget(self.NewUGCWidgetBlueprint_C_9)
    AddWidget(self.NewUGCWidgetBlueprint_C_10)
    AddWidget(self.NewUGCWidgetBlueprint_C_11)
    AddWidget(self.NewUGCWidgetBlueprint_C_12)
    AddWidget(self.NewUGCWidgetBlueprint_C_13)
    AddWidget(self.NewUGCWidgetBlueprint_C_14)
    AddWidget(self.NewUGCWidgetBlueprint_C_15)

    return Widgets
end

function UI10:HideExtraPresetWeaponWidgets()
    local Widgets = self:GetAllPresetWeaponWidgets()
    for Index = 11, #Widgets do
        local Widget = Widgets[Index]
        if Widget ~= nil and Widget.SetVisibility ~= nil then
            Widget:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

-- 读取本地背包武器；同系列有多把时只展示最高等级。
function UI10:GetBackpackWeaponList()
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn == nil then
        ugcprint("[UI10:GetBackpackWeaponList] Local player pawn is nil")
        return {}
    end
    local Result = {}
    if UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetAllItemDefineIDsV2 ~= nil then
        local AllItemData = UGCBackpackSystemV2.GetAllItemDefineIDsV2(PlayerPawn)
        if AllItemData ~= nil then
            for _, ItemDefineID in pairs(AllItemData) do
                local ItemID = self:GetItemIDFromDefineID(ItemDefineID)
                local Weapon = WeaponLevelConfig.GetWeaponInfo(ItemID)
                local DefineCount = self:GetBackpackItemCountByDefineID(PlayerPawn, ItemDefineID)
                if Weapon ~= nil and DefineCount > 0 then
                    for StackIndex = 1, DefineCount do
                        local Level = self:GetWeaponLevelByDefineID(ItemDefineID, Weapon, StackIndex)
                        local SelectKey = #Result + 1
                        table.insert(Result, {
                            Name = self:GetWeaponDisplayName(Weapon, Level),
                            IconPath = self:GetWeaponIconPathByItemID(Weapon.WPID),
                            ItemID = ItemID,
                            ItemDefineID = ItemDefineID,
                            StackIndex = StackIndex,
                            SelectKey = SelectKey,
                            Level = Level,
                            SeriesKey = Weapon.SeriesKey,
                        })
                    end
                end
            end
        end
    end
    if #Result > 0 then
        return SortAndIndexWeaponList(Result)
    end
    for _, Weapon in ipairs(WeaponLevelConfig.GetAllWeapons()) do
        local Count = self:GetBackpackItemCount(PlayerPawn, Weapon.WPID)
        for _ = 1, Count do
            local Level = self:GetWeaponLevel(Weapon)
            local SelectKey = #Result + 1
            table.insert(Result, {
                Name = self:GetWeaponDisplayName(Weapon, Level),
                IconPath = self:GetWeaponIconPathByItemID(Weapon.WPID),
                ItemID = Weapon.WPID,
                SelectKey = SelectKey,
                Level = Level,
                SeriesKey = Weapon.SeriesKey,
            })
        end
    end
    return SortAndIndexWeaponList(Result)
end

-- 武器名由系列名和品质名拼成，例如“星陨昊锤（史诗）”。
function UI10:GetWeaponDisplayName(SeriesKey, Level)
    local Weapon = nil
    if type(SeriesKey) == "table" then
        Weapon = SeriesKey
    else
        Weapon = WeaponLevelConfig.GetWeaponByID(SeriesKey)
    end

    if Weapon ~= nil then
        return WeaponLevelConfig.BuildDisplayName(Weapon, Level)
    end
    local WeaponName = WeaponNameLabels[SeriesKey] or tostring(SeriesKey)
    return WeaponName .. TextLabels.OpenParen .. "Lv" .. tostring(tonumber(Level) or 1) .. TextLabels.CloseParen
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
function UI10:SelectWeapon(WeaponName, IconPath, SelectKey, WeaponInstance)
    if WeaponInstance == nil and SelectKey ~= nil then
        local Index = tonumber(SelectKey)
        if self.WeaponList ~= nil and Index ~= nil then
            WeaponInstance = self.WeaponList[Index]
        end
        if WeaponInstance == nil then
            local WeaponList = self:GetBackpackWeaponList()
            self.WeaponList = WeaponList
            if Index ~= nil then
                WeaponInstance = WeaponList[Index]
            end
        end
    end
    if WeaponInstance == nil then
        local MaybeItemID = tonumber(SelectKey)
        if WeaponLevelConfig.GetWeaponInfo(MaybeItemID) ~= nil then
            WeaponInstance = {
                Name = WeaponName,
                IconPath = IconPath,
                ItemID = MaybeItemID,
                SelectKey = tonumber(SelectKey),
            }
        elseif self.SelectedWeaponItemID ~= nil then
            ugcprint("[UI10:SelectWeapon] ignore invalid select key: " .. tostring(SelectKey))
            return
        end
    end
    self.SelectedWeaponName = WeaponName
    self.SelectedWeaponIconPath = IconPath
    self.SelectedWeaponItemID = WeaponInstance ~= nil and WeaponInstance.ItemID or nil
    self.SelectedWeaponDefineID = WeaponInstance ~= nil and WeaponInstance.ItemDefineID or nil
    self.SelectedWeaponStackIndex = WeaponInstance ~= nil and WeaponInstance.StackIndex or nil
    self.SelectedWeaponSelectKey = WeaponInstance ~= nil and WeaponInstance.SelectKey or tonumber(SelectKey)
    self.SelectedWeaponLevel = WeaponInstance ~= nil and WeaponInstance.Level or nil
    self:SetForgeProtectSelected(false)

    if self.text_name_1 ~= nil then
        self.text_name_1:SetText(WeaponName or "")
    end

    self:RefreshForgeInfo()

    if self.Image_299 == nil or IconPath == nil then
        return
    end

    local IconTexture = UE.LoadObject(IconPath)
    if IconTexture == nil then
        ugcprint("[UI10:SelectWeapon] Icon load failed: " .. tostring(IconPath))
        return
    end

    self.Image_299:SetBrushFromTexture(IconTexture)
end

-- 刷新材料数量、成功率和当前武器属性加成。
function UI10:RefreshForgeInfo()
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(self.SelectedWeaponItemID)
    local WeaponLevel = tonumber(self.SelectedWeaponLevel) or
                            self:GetWeaponLevelByDefineID(self.SelectedWeaponDefineID, WeaponInfo,
                                self.SelectedWeaponStackIndex)
    local Cost = WeaponLevelConfig.GetForgeCost(self.SelectedWeaponItemID, WeaponLevel) or { HGRJ = 0, QNHH = 0 }
    local Rate = WeaponLevelConfig.GetForgeRate(self.SelectedWeaponItemID, WeaponLevel) or { Success = 0, Keep = 0, Down = 0, Destroy = 0 }
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local HGRJCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.HGRJ)
    local QNHHCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.QNHH)
    if (WeaponLevel < 10 or WeaponLevel > 14) and self.bUseForgeProtect == true then
        self:SetForgeProtectSelected(false)
    end

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
    if self.TextBlock_1 ~= nil then
        self.TextBlock_1:SetText(TextLabels.Destroy .. tostring(Rate.Destroy or 0) .. "%")
    end
    if self.TextBlock_297 ~= nil then
        local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(self.SelectedWeaponItemID)
        local AttackPercent = WeaponInfo ~= nil and
                                  WeaponLevelConfig.GetAttackPercentByWeaponID(WeaponInfo.ID, WeaponLevel) or 0
        self.TextBlock_297:SetText(TextLabels.AttackBonus .. tostring(AttackPercent or 0) .. "%")
    end
end

-- 服务端锻造结果回调后，刷新背包列表并尽量保持当前系列选中。
function UI10:OnForgeWeaponResult(ResultType, OldItemID, ResultItemID, ResultLevel, ItemDefineID, StackIndex)
    OldItemID = tonumber(OldItemID)
    ResultItemID = tonumber(ResultItemID)
    if ResultItemID ~= nil and ResultItemID <= 0 then
        ResultItemID = nil
    end

    local ResultInfo = ResultItemID ~= nil and WeaponLevelConfig.GetWeaponInfo(ResultItemID) or nil
    local OldInfo = WeaponLevelConfig.GetWeaponInfo(OldItemID)
    local SeriesKey = ResultInfo ~= nil and ResultInfo.SeriesKey or (OldInfo ~= nil and OldInfo.SeriesKey or nil)
    local PreviousSelectKey = self.SelectedWeaponSelectKey
    if ResultInfo ~= nil then
        local PlayerController = self:GetLocalPlayerController()
        local Level = math.max(1,
            math.min(ResultInfo.MaxLevel, tonumber(ResultLevel) or ResultInfo.Level or 1))
        self.SelectedWeaponItemID = ResultItemID
        self.SelectedWeaponDefineID = nil
        self.SelectedWeaponStackIndex = nil
        self.SelectedWeaponLevel = Level
        self.SelectedWeaponName = self:GetWeaponDisplayName(ResultInfo, Level)
        self.SelectedWeaponIconPath = self:GetWeaponIconPathByItemID(ResultItemID) or self.SelectedWeaponIconPath
        self.bForgeBackpackSyncPending = true
        if self.text_name_1 ~= nil then
            self.text_name_1:SetText(self.SelectedWeaponName or "")
        end
        self:RefreshForgeInfo()
        if PlayerController ~= nil then
            PlayerController.WeaponLevelByID = PlayerController.WeaponLevelByID or {}
            PlayerController.WeaponLevelByID[ResultInfo.ID] = Level
        end

        local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
        if PlayerPawn ~= nil then
            PlayerPawn.WeaponLevelByID = PlayerPawn.WeaponLevelByID or {}
            PlayerPawn.WeaponLevelByID[ResultInfo.ID] = Level

            local CurrentWeapon = UGCWeaponManagerSystem ~= nil and
                                      UGCWeaponManagerSystem.GetCurrentWeapon ~= nil and
                                      UGCWeaponManagerSystem.GetCurrentWeapon(PlayerPawn) or nil
            local CurrentWeaponID = CurrentWeapon ~= nil and
                                        tonumber(CurrentWeapon.WeaponConfigID or CurrentWeapon.WuQiID or
                                            CurrentWeapon.WeaponTypeID) or nil
            local CurrentItemID = CurrentWeapon ~= nil and
                                      tonumber(CurrentWeapon.ItemID or CurrentWeapon.ItemId or CurrentWeapon.WPID or
                                          CurrentWeapon.ItemDefineID or CurrentWeapon.DefineID) or nil
            local CurrentInfo = WeaponLevelConfig.GetWeaponInfo(CurrentItemID)
            if (CurrentInfo ~= nil and CurrentInfo.ID == ResultInfo.ID) or CurrentWeaponID == ResultInfo.ID then
                local AttackPercent = WeaponLevelConfig.GetAttackPercentByWeaponID(ResultInfo.ID, Level)
                CurrentWeapon.WeaponLevel = Level
                CurrentWeapon.WeaponConfigID = ResultInfo.ID
                CurrentWeapon.WeaponLevel_0 = AttackPercent
                ugcprint("[UI10:ForgeAttack] weaponID=" .. tostring(ResultInfo.ID) .. ", level=" .. tostring(Level) ..
                    ", attack=" .. tostring(AttackPercent))
                if PlayerPawn.ApplyWeaponAttackBonusLocalDisplay ~= nil then
                    PlayerPawn:ApplyWeaponAttackBonusLocalDisplay(ResultItemID, ResultInfo.SeriesKey, ResultInfo.Name,
                        Level, true)
                end
            end
        end
    end

    local IconPath = self:GetWeaponIconPathByItemID(ResultItemID or OldItemID) or self.SelectedWeaponIconPath
    self:ShowForgeResultPopup(ResultType, IconPath)

    local function RefreshAndReselect(RetriesRemaining)
        if self == nil then
            return
        end
        self:InitWeaponWidgets()
        if ResultItemID ~= nil then
            if self:SelectWeaponByItemID(ResultItemID, false) == true then
                self.bForgeBackpackSyncPending = false
            else
                self.SelectedWeaponItemID = ResultItemID
                self.SelectedWeaponDefineID = nil
                self.SelectedWeaponStackIndex = nil
                if ResultInfo ~= nil then
                    self.SelectedWeaponLevel = math.max(1,
                        math.min(ResultInfo.MaxLevel, tonumber(ResultLevel) or ResultInfo.Level or 1))
                    self.SelectedWeaponName = self:GetWeaponDisplayName(ResultInfo, self.SelectedWeaponLevel)
                    self.SelectedWeaponIconPath = self:GetWeaponIconPathByItemID(ResultItemID) or self.SelectedWeaponIconPath
                    if self.text_name_1 ~= nil then
                        self.text_name_1:SetText(self.SelectedWeaponName or "")
                    end
                    self:RefreshForgeInfo()
                end
                if RetriesRemaining > 0 then
                    UGCTimerUtility.CreateLuaTimer(0.2, function()
                        RefreshAndReselect(RetriesRemaining - 1)
                    end, false)
                end
            end
        elseif SeriesKey ~= nil then
            self:SelectWeaponBySeriesKey(SeriesKey)
        elseif PreviousSelectKey ~= nil then
            self:SelectWeaponByIndex(PreviousSelectKey)
        end
    end
    UGCTimerUtility.CreateLuaTimer(0.3, function()
        RefreshAndReselect(5)
    end, false)
end

function UI10:GetForgeResultWidget()
    if self.ForgeResultWidget ~= nil then
        return self.ForgeResultWidget
    end

    local PlayerController = self:GetLocalPlayerController()
    if PlayerController == nil then
        ugcprint("[UI10:GetForgeResultWidget] PlayerController is nil")
        return nil
    end

    local FullPath = nil
    if UGCGameSystem.GetUGCResourcesFullPath ~= nil then
        local Success, Result = pcall(UGCGameSystem.GetUGCResourcesFullPath, ForgeResultWidgetPath)
        if Success then
            FullPath = Result
        end
    end
    if FullPath == nil and UGCMapInfoLib ~= nil and UGCMapInfoLib.GetRootLongPackagePath ~= nil then
        FullPath = UGCMapInfoLib.GetRootLongPackagePath() .. ForgeResultWidgetPath
    end

    local WidgetClass = FullPath ~= nil and UE.LoadClass(FullPath) or nil
    if WidgetClass == nil then
        ugcprint("[UI10:GetForgeResultWidget] Class load failed: " .. tostring(FullPath))
        return nil
    end

    local Widget = UserWidget.NewWidgetObjectBP(PlayerController, WidgetClass)
    if Widget == nil then
        ugcprint("[UI10:GetForgeResultWidget] Widget create failed")
        return nil
    end
    Widget:AddToViewport(12000)
    self.ForgeResultWidget = Widget
    return Widget
end

-- 使用独立的全屏控件显示每一次锻造结果。
function UI10:ShowForgeResultPopup(ResultType, IconPath)
    local Widget = self:GetForgeResultWidget()
    if Widget == nil then
        return
    end
    if Widget.ShowForgeResult ~= nil then
        Widget:ShowForgeResult(ResultType, IconPath)
    else
        Widget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

-- 根据武器 ItemID 找到对应系列图标。
function UI10:GetWeaponIconPathByItemID(ItemID)
    local WeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    if WeaponInfo == nil then
        return nil
    end

    local UIConfig = WeaponUIConfig[WeaponIconKeyByWPID[tonumber(ItemID)] or WeaponInfo.SeriesKey]
    if UIConfig == nil then
        return nil
    end

    return UIConfig.IconPath
end

function UI10:RefreshSelectedWeaponFromBackpack()
    if self.bForgeBackpackSyncPending == true then
        return
    end

    local CurrentItemID = self:GetItemIDFromDefineID(self.SelectedWeaponDefineID) or tonumber(self.SelectedWeaponItemID)
    local CurrentInfo = WeaponLevelConfig.GetWeaponInfo(CurrentItemID)
    if CurrentInfo == nil then
        self:SelectFirstBackpackWeapon()
        return
    end

    local WeaponList = self:GetBackpackWeaponList()
    self.WeaponList = WeaponList
    local BestWeapon = nil
    for _, WeaponInfo in ipairs(WeaponList) do
        if WeaponInfo.SeriesKey == CurrentInfo.SeriesKey and
            (BestWeapon == nil or (tonumber(WeaponInfo.Level) or 1) > (tonumber(BestWeapon.Level) or 1)) then
            BestWeapon = WeaponInfo
        end
    end

    if BestWeapon ~= nil then
        self:SelectWeapon(BestWeapon.Name, BestWeapon.IconPath, BestWeapon.SelectKey, BestWeapon)
    end
end

function UI10:SelectFirstBackpackWeapon()
    local WeaponList = self:GetBackpackWeaponList()
    self.WeaponList = WeaponList
    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].SelectKey or 1, WeaponList[1])
        return true
    end
    return false
end

-- 点击锻造：先做本地材料和武器检查，再请求服务器执行锻造。
function UI10:Button_dz_OnClicked()
    ugcprint("[UI10:Button_dz_OnClicked] clicked")
    local NowTime = os.time()
    if self.LastForgeClickTime ~= nil and NowTime - self.LastForgeClickTime < 2 then
        return
    end
    self.LastForgeClickTime = NowTime

    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local bProtectSelectedBeforeRefresh = self.bUseForgeProtect == true
    self:RefreshSelectedWeaponFromBackpack()
    local ItemID = self:GetItemIDFromDefineID(self.SelectedWeaponDefineID) or tonumber(self.SelectedWeaponItemID)
    if WeaponLevelConfig.GetWeaponInfo(ItemID) == nil and self:SelectFirstBackpackWeapon() == true then
        ItemID = self:GetItemIDFromDefineID(self.SelectedWeaponDefineID) or tonumber(self.SelectedWeaponItemID)
    end
    if PlayerPawn == nil or ItemID == nil then
        ugcprint("[UI10:Button_dz_OnClicked] PlayerPawn or selected weapon is nil")
        self:ShowForgeResultPopup("Error", self.SelectedWeaponIconPath)
        return
    end

    local SelectedWeaponInfo = WeaponLevelConfig.GetWeaponInfo(ItemID)
    local SelectedLevel = tonumber(self.SelectedWeaponLevel) or
                              self:GetWeaponLevelByDefineID(self.SelectedWeaponDefineID, SelectedWeaponInfo,
                                  self.SelectedWeaponStackIndex)
    local Cost = WeaponLevelConfig.GetForgeCost(ItemID, SelectedLevel)
    if Cost == nil then
        ugcprint("[UI10:Button_dz_OnClicked] Selected weapon cannot forge: " .. tostring(ItemID))
        self:ShowForgeResultPopup("Error", self.SelectedWeaponIconPath)
        return
    end

    local HGRJCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.HGRJ)
    local QNHHCount = self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.QNHH)
    if HGRJCount < (Cost.HGRJ or 0) or QNHHCount < (Cost.QNHH or 0) then
        ugcprint("[UI10:Button_dz_OnClicked] Material not enough")
        self:RefreshForgeInfo()
        if L_Com ~= nil and L_Com.ShowToast ~= nil then
            L_Com.ShowToast(TextLabels.MaterialNotEnough)
        end
        return
    end

    if self.SelectedWeaponDefineID == nil and self:GetBackpackItemCount(PlayerPawn, ItemID) <= 0 then
        if self.bForgeBackpackSyncPending ~= true then
            ugcprint("[UI10:Button_dz_OnClicked] Selected weapon is not in backpack: " .. tostring(ItemID))
            self:InitWeaponWidgets()
            self:ShowForgeResultPopup("Error", self.SelectedWeaponIconPath)
            return
        end
        ugcprint("[UI10:Button_dz_OnClicked] Backpack sync pending, send selected result item: " .. tostring(ItemID))
    end

    local PlayerController = self:GetLocalPlayerController()
    if PlayerController == nil then
        ugcprint("[UI10:Button_dz_OnClicked] PlayerController is nil")
        self:ShowForgeResultPopup("Error", self.SelectedWeaponIconPath)
        return
    end

    local UseProtect = bProtectSelectedBeforeRefresh and SelectedLevel >= 10 and SelectedLevel <= 14 and
                           self:GetBackpackItemCount(PlayerPawn, MaterialItemIDs.Protect) > 0 and 1 or 0
    ugcprint("[UI10:Button_dz_OnClicked] Call Server_ForgeWeapon item=" .. tostring(ItemID) ..
        ", define=" .. tostring(self.SelectedWeaponDefineID) .. ", stack=" .. tostring(self.SelectedWeaponStackIndex or 1) ..
        ", protect=" .. tostring(UseProtect))
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_ForgeWeapon", ItemID, UseProtect)
    self:SetForgeProtectSelected(false)
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
function UI10:GetWeaponLevel(WeaponInfo)
    if WeaponInfo == nil then
        return 1
    end
    local PlayerController = self:GetLocalPlayerController()
    if PlayerController ~= nil and PlayerController.WeaponLevelByID ~= nil then
        local CachedLevel = tonumber(PlayerController.WeaponLevelByID[WeaponInfo.ID])
        if CachedLevel ~= nil then
            return math.max(1, math.min(WeaponInfo.MaxLevel, CachedLevel))
        end
    end
    local PlayerState = nil
    if UGCGameSystem.GetLocalPlayerState ~= nil then
        local Success, Result = pcall(UGCGameSystem.GetLocalPlayerState)
        if Success then
            PlayerState = Result
        end
    end
    if PlayerState == nil then
        local PlayerController = self:GetLocalPlayerController()
        PlayerState = PlayerController ~= nil and PlayerController.PlayerState or nil
    end
    if PlayerState ~= nil and PlayerState.GetWeaponLevel ~= nil and
        (PlayerState.HasWeaponLevel == nil or PlayerState:HasWeaponLevel(WeaponInfo.ID)) then
        local SavedLevel = tonumber(PlayerState:GetWeaponLevel(WeaponInfo.ID))
        if SavedLevel ~= nil then
            return math.max(1, math.min(WeaponInfo.MaxLevel, SavedLevel))
        end
    end
    local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if PlayerPawn ~= nil and UGCWeaponManagerSystem ~= nil and UGCWeaponManagerSystem.GetCurrentWeapon ~= nil then
        local CurrentWeapon = UGCWeaponManagerSystem.GetCurrentWeapon(PlayerPawn)
        if CurrentWeapon ~= nil then
            local CurrentWeaponID = tonumber(CurrentWeapon.WeaponConfigID or CurrentWeapon.WuQiID or
                                                CurrentWeapon.WeaponTypeID)
            local CurrentItemID = tonumber(CurrentWeapon.ItemID or CurrentWeapon.ItemId or CurrentWeapon.WPID or
                CurrentWeapon.ItemDefineID or CurrentWeapon.DefineID)
            local CurrentLevel = tonumber(CurrentWeapon.WeaponLevel)
            local CurrentInfo = WeaponLevelConfig.GetWeaponInfo(CurrentItemID)
            if CurrentLevel ~= nil and
                (CurrentWeaponID == WeaponInfo.ID or (CurrentInfo ~= nil and CurrentInfo.ID == WeaponInfo.ID) or
                    CurrentItemID == tonumber(WeaponInfo.WPID)) then
                return math.max(1, math.min(WeaponInfo.MaxLevel, CurrentLevel))
            end
        end
    end
    return 1
end
function UI10:GetItemIDFromDefineID(ItemDefineID)
    if ItemDefineID == nil then
        return nil
    end
    local DefineIDType = type(ItemDefineID)
    if DefineIDType == "number" or DefineIDType == "string" then
        return tonumber(ItemDefineID)
    elseif DefineIDType ~= "table" and DefineIDType ~= "userdata" then
        return nil
    end
    local FieldNames = { "TypeSpecificID", "ItemID", "ItemId", "itemID", "ID", "WPID" }
    for _, FieldName in ipairs(FieldNames) do
        local Success, FieldValue = pcall(function()
            return ItemDefineID[FieldName]
        end)
        if Success then
            local ItemID = tonumber(FieldValue)
            if ItemID ~= nil then
                return ItemID
            end
        end
    end
    local FunctionNames = { "GetItemID", "GetItemId", "GetItemDefineID", "GetDefineID", "GetDefineId" }
    for _, FunctionName in ipairs(FunctionNames) do
        local SuccessGetFunc, Func = pcall(function()
            return ItemDefineID[FunctionName]
        end)
        if not SuccessGetFunc then
            Func = nil
        end
        if Func ~= nil then
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
function UI10:GetWeaponLevelByDefineID(ItemDefineID, WeaponInfo, StackIndex)
    if WeaponInfo == nil then
        return 1
    end
    StackIndex = math.max(1, tonumber(StackIndex) or 1)
    if ItemDefineID ~= nil and self.WeaponLevelByDefineID ~= nil then
        local CachedLevel = tonumber(self.WeaponLevelByDefineID[self:GetDefineIDKey(ItemDefineID, StackIndex)])
        if CachedLevel ~= nil then
            return math.max(1, math.min(WeaponInfo.MaxLevel, CachedLevel))
        end
    end
    if ItemDefineID ~= nil and UGCItemSystemV2 ~= nil and UGCItemSystemV2.LoadItemCustomData ~= nil then
        local Success, CustomData = pcall(UGCItemSystemV2.LoadItemCustomData, ItemDefineID)
        if Success and type(CustomData) == "table" then
            local Level = nil
            if type(CustomData.WeaponLevelsByStackIndex) == "table" then
                Level = tonumber(CustomData.WeaponLevelsByStackIndex[tostring(StackIndex)] or
                    CustomData.WeaponLevelsByStackIndex[StackIndex])
            end
            Level = Level or tonumber(CustomData.WeaponLevel or CustomData.StrengthenLv)
            if Level ~= nil then
                return math.max(1, math.min(WeaponInfo.MaxLevel, Level))
            end
        end
    end
    if ItemDefineID ~= nil then
        return math.max(1, math.min(WeaponInfo.MaxLevel, tonumber(WeaponInfo.Level) or 1))
    end
    return self:GetWeaponLevel(WeaponInfo)
end
function UI10:GetDefineIDKey(ItemDefineID, StackIndex)
    return tostring(ItemDefineID) .. ":" .. tostring(math.max(1, tonumber(StackIndex) or 1))
end
function UI10:GetBackpackItemCountByDefineID(PlayerPawn, ItemDefineID)
    if PlayerPawn ~= nil and ItemDefineID ~= nil and UGCBackpackSystemV2 ~= nil and
        UGCBackpackSystemV2.GetItemCountByDefineIDV2 ~= nil then
        local Success, Count, Count2 = pcall(UGCBackpackSystemV2.GetItemCountByDefineIDV2, PlayerPawn, ItemDefineID)
        if Success then
            local NumberCount = tonumber(Count2) or tonumber(Count)
            if NumberCount ~= nil then
                return NumberCount
            end
        end
    end
    return ItemDefineID ~= nil and 1 or 0
end
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

-- 根据 ItemID 重新选中武器；服务端替换后可关闭回退并等待背包复制。
function UI10:SelectWeaponByItemID(ItemID, bFallbackToFirst)
    local WeaponList = self:GetBackpackWeaponList()
    self.WeaponList = WeaponList
    for _, WeaponInfo in ipairs(WeaponList) do
        if WeaponInfo.ItemID == ItemID then
            self:SelectWeapon(WeaponInfo.Name, WeaponInfo.IconPath, WeaponInfo.SelectKey, WeaponInfo)
            return true
        end
    end

    if bFallbackToFirst == false then
        return false
    end
    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].SelectKey or 1, WeaponList[1])
    else
        self:SelectWeapon(nil, nil, nil)
    end
    return false
end

-- 根据武器系列重新选中武器；锻造升降级后用它保持选中系列不跳走。
function UI10:SelectWeaponByIndex(Index)
    Index = tonumber(Index)
    local WeaponList = self:GetBackpackWeaponList()
    self.WeaponList = WeaponList
    if Index ~= nil and WeaponList[Index] ~= nil then
        local WeaponInfo = WeaponList[Index]
        self:SelectWeapon(WeaponInfo.Name, WeaponInfo.IconPath, WeaponInfo.SelectKey or Index, WeaponInfo)
        return
    end
    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].SelectKey or 1, WeaponList[1])
    else
        self:SelectWeapon(nil, nil, nil)
    end
end
function UI10:SelectWeaponBySeriesKey(SeriesKey)
    local WeaponList = self:GetBackpackWeaponList()
    self.WeaponList = WeaponList
    for _, WeaponInfo in ipairs(WeaponList) do
        local Info = WeaponLevelConfig.GetWeaponInfo(WeaponInfo.ItemID)
        if Info ~= nil and Info.SeriesKey == SeriesKey then
            self:SelectWeapon(WeaponInfo.Name, WeaponInfo.IconPath, WeaponInfo.SelectKey, WeaponInfo)
            return
        end
    end

    if WeaponList[1] ~= nil then
        self:SelectWeapon(WeaponList[1].Name, WeaponList[1].IconPath, WeaponList[1].SelectKey or 1, WeaponList[1])
    else
        self:SelectWeapon(nil, nil, nil)
    end
end

-- function UI10:Tick(MyGeometry, InDeltaTime)
-- end

-- function UI10:Destruct()
-- end

return UI10
