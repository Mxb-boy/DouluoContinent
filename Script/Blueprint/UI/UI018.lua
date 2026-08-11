---@class UI018_C:UUserWidget
---@field Btn_AddPoint UButton
---@field Btn_Close UButton
---@field Btn_Detail UButton
---@field Btn_lock_1 UButton
---@field Btn_lock_2 UButton
---@field Btn_lock_3 UButton
---@field Btn_lock_4 UButton
---@field Btn_Talent_10 UButton
---@field Btn_Talent_11 UButton
---@field Btn_Talent_12 UButton
---@field Btn_Talent_13 UButton
---@field Btn_Talent_14 UButton
---@field Btn_Talent_15 UButton
---@field Btn_Talent_01 UButton
---@field Btn_Talent_02 UButton
---@field Btn_Talent_03 UButton
---@field Btn_Talent_04 UButton
---@field Btn_Talent_05 UButton
---@field Btn_Talent_06 UButton
---@field Btn_Talent_07 UButton
---@field Btn_Talent_08 UButton
---@field Btn_Talent_09 UButton
---@field BtnIn_Quit UButton
---@field CheckBox_1 UCheckBox
---@field CheckBox_2 UCheckBox
---@field CheckBox_3 UCheckBox
---@field CheckBox_4 UCheckBox
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
---@field Panel_Detail UCanvasPanel
---@field Txt_TalentPoints UTextBlock
--Edit Below--
local TalentMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentMgr")

local UI018 = { bInitDoOnce = false }

local ULTIMATE_WIDGETS = {
    [16] = { LockButton = "Btn_lock_1", CheckBox = "CheckBox_1" },
    [17] = { LockButton = "Btn_lock_2", CheckBox = "CheckBox_2" },
    [18] = { LockButton = "Btn_lock_3", CheckBox = "CheckBox_3" },
    [19] = { LockButton = "Btn_lock_4", CheckBox = "CheckBox_4" }
}

local function GetLocalPlayerController(Widget)
    return UGCGameSystem.GetLocalPlayerController() or GameplayStatics.GetPlayerController(Widget, 0)
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

    self:BindButton("Btn_Close", function()
        self:Close()
    end)
    self:BindButton("Btn_Detail", function()
        self:SetDetailVisible(true)
    end)
    self:BindButton("BtnIn_Quit", function()
        self:SetDetailVisible(false)
    end)
    self:BindButton("Btn_AddPoint", function()
        ugcprint("[TalentUI] Talent point source is not configured")
    end)

    for NodeID = 1, 15 do
        local CurrentNodeID = NodeID
        self:BindButton(string.format("Btn_Talent_%02d", CurrentNodeID), function()
            self:RequestLearnTalent(CurrentNodeID)
        end)
    end

    for NodeID = 16, 19 do
        local CurrentNodeID = NodeID
        local WidgetNames = ULTIMATE_WIDGETS[CurrentNodeID]
        self:BindButton(WidgetNames.LockButton, function()
            self:RequestLearnTalent(CurrentNodeID)
        end)
        self:BindCheckBox(WidgetNames.CheckBox, function(bIsChecked)
            self:OnUltimateCheckStateChanged(CurrentNodeID, bIsChecked)
        end)
    end

    local PlayerController = GetLocalPlayerController(self)
    if PlayerController ~= nil then
        PlayerController.TalentUIInstance = self
    end
end

function UI018:BindButton(WidgetName, Callback)
    local Button = self:GetWidget(WidgetName)
    if Button ~= nil and Button.OnClicked ~= nil then
        Button.OnClicked:Add(Callback)
    end
end

function UI018:BindCheckBox(WidgetName, Callback)
    local CheckBox = self:GetWidget(WidgetName)
    if CheckBox ~= nil and CheckBox.OnCheckStateChanged ~= nil then
        CheckBox.OnCheckStateChanged:Add(Callback)
    end
end

function UI018:GetPlayerState()
    local PlayerController = GetLocalPlayerController(self)
    return PlayerController ~= nil and PlayerController.PlayerState or nil
end

function UI018:SetDetailVisible(bVisible)
    local DetailPanel = self:GetWidget("Panel_Detail")
    if DetailPanel ~= nil then
        DetailPanel:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    end
end

function UI018:Open()
    self:SetVisibility(ESlateVisibility.Visible)
    self:SetDetailVisible(false)
    self:RefreshTalentState()

    local PlayerController = GetLocalPlayerController(self)
    if PlayerController ~= nil then
        PlayerController.TalentUIInstance = self
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestTalentState")
    end
end

function UI018:Close()
    self:SetDetailVisible(false)
    self:SetVisibility(ESlateVisibility.Collapsed)
end

function UI018:RequestLearnTalent(NodeID)
    local PlayerController = GetLocalPlayerController(self)
    if PlayerController == nil then
        return
    end
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_LearnTalent", NodeID)
end

function UI018:OnUltimateCheckStateChanged(NodeID, bIsChecked)
    if self.bRefreshingUltimateCheckBoxes then
        return
    end
    local PlayerState = self:GetPlayerState()
    if not TalentMgr:HasLearnedTalent(PlayerState, NodeID) then
        self:RefreshTalentState()
        return
    end

    local PlayerController = GetLocalPlayerController(self)
    if PlayerController == nil then
        return
    end

    local EquippedID = PlayerState ~= nil and
                           (PlayerState.GetEquippedUltimateID ~= nil and PlayerState:GetEquippedUltimateID() or
                               math.max(0, math.floor(tonumber(PlayerState.EquippedUltimateID) or 0))) or 0
    local RequestedID = bIsChecked and NodeID or (EquippedID == NodeID and 0 or EquippedID)
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_EquipTalentUltimate", RequestedID)
end

function UI018:RefreshTalentState()
    local PlayerState = self:GetPlayerState()
    if PlayerState == nil then
        return
    end

    local TalentPoints = PlayerState.GetTalentPoints ~= nil and PlayerState:GetTalentPoints() or
                             math.max(0, math.floor(tonumber(PlayerState.TalentPoints) or 0))
    local PointsText = self:GetWidget("Txt_TalentPoints")
    if PointsText ~= nil then
        PointsText:SetText(tostring(TalentPoints))
    end

    for NodeID = 1, 15 do
        local Button = self:GetWidget(string.format("Btn_Talent_%02d", NodeID))
        if Button ~= nil then
            local bLearned = TalentMgr:HasLearnedTalent(PlayerState, NodeID)
            local bCanLearn = TalentMgr:CanLearnTalent(PlayerState, NodeID)
            Button:SetVisibility(bLearned and ESlateVisibility.HitTestInvisible or ESlateVisibility.Visible)
            Button:SetIsEnabled(bLearned or bCanLearn)
            if Button.SetRenderOpacity ~= nil then
                Button:SetRenderOpacity(bLearned and 1.0 or 0.55)
            end
        end
    end

    local EquippedID = PlayerState.GetEquippedUltimateID ~= nil and PlayerState:GetEquippedUltimateID() or
                           math.max(0, math.floor(tonumber(PlayerState.EquippedUltimateID) or 0))
    self.bRefreshingUltimateCheckBoxes = true
    for NodeID = 16, 19 do
        local WidgetNames = ULTIMATE_WIDGETS[NodeID]
        local LockButton = self:GetWidget(WidgetNames.LockButton)
        local CheckBox = self:GetWidget(WidgetNames.CheckBox)
        local bLearned = TalentMgr:HasLearnedTalent(PlayerState, NodeID)

        if LockButton ~= nil then
            LockButton:SetVisibility(bLearned and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
            LockButton:SetIsEnabled(not bLearned and TalentMgr:CanLearnTalent(PlayerState, NodeID))
        end
        if CheckBox ~= nil then
            CheckBox:SetVisibility(bLearned and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
            CheckBox:SetIsEnabled(bLearned)
            CheckBox:SetIsChecked(bLearned and EquippedID == NodeID)
        end
    end
    self.bRefreshingUltimateCheckBoxes = false
end

return UI018
