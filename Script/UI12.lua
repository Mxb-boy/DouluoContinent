---@class UI12_C:UUserWidget
---@field Button_151 UButton
---@field CanvasPanel_0 UCanvasPanel
---@field Image_0 UImage
---@field Image_45 UImage
---@field Image_46 UImage
---@field Image_47 UImage
---@field NewUGCWidgetBlueprint2 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_0 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_1 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_2 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_3 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_4 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_5 NewUGCWidgetBlueprint2_C
---@field NewUGCWidgetBlueprint2_C_6 NewUGCWidgetBlueprint2_C
---@field ScrollBox_82 UScrollBox
---@field TextBlock_75 UTextBlock
-- Edit Below--
local UI12 = {}

local TeleportConfig = UGCGameSystem.UGCRequire("Script.TeleportConfig")
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")

-- 显式加载子控件模块，确保 UnLua 绑定生效
UGCGameSystem.UGCRequire("Script.NewUGCWidgetBlueprint2")

--- 计算战力显示文本: "(1234550战力限制)"
local function FormatPowerText(power)
    if power <= 0 then
        return "(无限制)"
    end
    return "(" .. tostring(power) .. "战力限制)"
end

--- 判断战力是否满足要求
local function CanEnter(currentPower, powerReq)
    if powerReq <= 0 then
        return true
    end
    return currentPower >= powerReq
end

--- 执行传送
local function DoTeleport(pointIndex, worldContext)
    local loc = TeleportConfig.GetLocation(pointIndex)
    if loc == nil then
        return
    end

    local pc = GameplayStatics.GetPlayerController(worldContext, 0)
    if pc == nil then
        return
    end

    UnrealNetwork.CallUnrealRPC(pc, pc, "Server_TeleportToLocation", loc.x, loc.y, loc.z + 100)
end

function UI12:Construct()
    -- 关闭按钮
    if self.Button_151 then
        UIEffectUtil.SetButtonStateBrushSameAsNormal(self.Button_151)
        UIEffectUtil.BindPressScale(self, self.Button_151, self.Button_151, 1.06, 1.0)
        self.Button_151.OnClicked:Add(self.OnCloseClicked, self)
    end
    self:RefreshList()
end

function UI12:OnCloseClicked()
    -- 隐藏而非移除，配合 UI02 的实例复用逻辑（再次打开时 SetVisibility Visible）
    self:SetVisibility(ESlateVisibility.Collapsed)
end

--- 刷新传送点列表（每次打开都会重新评估战力门槛）
function UI12:RefreshList()
    -- 获取当前战力
    local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
    local currentPower = 0
    if playerPawn then
        local attack = UGCAttributeSystem.GetGameAttributeValue(playerPawn, "AttackPower") or 0
        local maxHp = UGCPawnAttrSystem.GetHealthMax(playerPawn) or 0
        currentPower = attack + maxHp
    end

    -- 清空 ScrollBox
    if self.ScrollBox_82 then
        self.ScrollBox_82:ClearChildren()
    end

    -- 加载 NewUGCWidgetBlueprint2 类
    local itemPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/NewUGCWidgetBlueprint2.NewUGCWidgetBlueprint2_C"
    local itemClass = UE.LoadClass(itemPath)
    if itemClass == nil then
        return
    end

    local pc = GameplayStatics.GetPlayerController(self, 0)

    -- 为每个传送点创建子控件
    local count = TeleportConfig.GetCount()
    for i = 1, count do
        local point = TeleportConfig.GetPoint(i)
        local widget = UserWidget.NewWidgetObjectBP(pc, itemClass)
        if widget == nil then
        else
            local powerText = FormatPowerText(point.power)
            local canEnter = CanEnter(currentPower, point.power)
            -- 先 AddChild 让 widget 进入控件树、触发 Construct，
            -- 之后再调 Setup 才能保证子控件 (TextBlock/Button) 已初始化
            self.ScrollBox_82:AddChild(widget)
            local ok, err = pcall(function()
                widget:Setup(i, point.name, powerText, canEnter, function(idx)
                    DoTeleport(idx, self)
                end)
            end)
            if not ok then
            else
            end
        end
    end
end

return UI12
