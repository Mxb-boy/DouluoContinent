---@class TeamPanel_C:UUserWidget
---@field ActionInput UEditableTextBox
---@field CloseBtn UButton
---@field PlayerRow1 UButton
---@field PlayerRow10 UButton
---@field PlayerRow11 UButton
---@field PlayerRow12 UButton
---@field PlayerRow2 UButton
---@field PlayerRow3 UButton
---@field PlayerRow4 UButton
---@field PlayerRow5 UButton
---@field PlayerRow6 UButton
---@field PlayerRow7 UButton
---@field PlayerRow8 UButton
---@field PlayerRow9 UButton
---@field RefreshBtn UButton
---@field RowDisbandBtn1 UButton
---@field RowDisbandBtn10 UButton
---@field RowDisbandBtn11 UButton
---@field RowDisbandBtn12 UButton
---@field RowDisbandBtn2 UButton
---@field RowDisbandBtn3 UButton
---@field RowDisbandBtn4 UButton
---@field RowDisbandBtn5 UButton
---@field RowDisbandBtn6 UButton
---@field RowDisbandBtn7 UButton
---@field RowDisbandBtn8 UButton
---@field RowDisbandBtn9 UButton
---@field RowInviteBtn1 UButton
---@field RowInviteBtn10 UButton
---@field RowInviteBtn11 UButton
---@field RowInviteBtn12 UButton
---@field RowInviteBtn2 UButton
---@field RowInviteBtn3 UButton
---@field RowInviteBtn4 UButton
---@field RowInviteBtn5 UButton
---@field RowInviteBtn6 UButton
---@field RowInviteBtn7 UButton
---@field RowInviteBtn8 UButton
---@field RowInviteBtn9 UButton
---@field RowKickBtn1 UButton
---@field RowKickBtn10 UButton
---@field RowKickBtn11 UButton
---@field RowKickBtn12 UButton
---@field RowKickBtn2 UButton
---@field RowKickBtn3 UButton
---@field RowKickBtn4 UButton
---@field RowKickBtn5 UButton
---@field RowKickBtn6 UButton
---@field RowKickBtn7 UButton
---@field RowKickBtn8 UButton
---@field RowKickBtn9 UButton
---@field RowLeaveBtn1 UButton
---@field RowLeaveBtn10 UButton
---@field RowLeaveBtn11 UButton
---@field RowLeaveBtn12 UButton
---@field RowLeaveBtn2 UButton
---@field RowLeaveBtn3 UButton
---@field RowLeaveBtn4 UButton
---@field RowLeaveBtn5 UButton
---@field RowLeaveBtn6 UButton
---@field RowLeaveBtn7 UButton
---@field RowLeaveBtn8 UButton
---@field RowLeaveBtn9 UButton
---@field TeamEntryBtn UButton
--Edit Below--
---@class TeamPanel_C:UUserWidget
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")

local TeamPanel = {}
local Visible = 0
local Collapsed = 1
local Hidden = 2
local MAX_ROWS = TeamConfig.MAX_SERVER_PLAYERS

local function IsSamePlayerKey(KeyA, KeyB)
    return KeyA ~= nil and KeyB ~= nil and tostring(KeyA) == tostring(KeyB)
end

function TeamPanel:GetLocalController()
    return UGCGameSystem.GetLocalPlayerController()
end

function TeamPanel:GetWidget(Name)
    if self.WidgetRefs[Name] == nil then
        self.WidgetRefs[Name] = self:GetWidgetFromName(Name)
    end
    return self.WidgetRefs[Name]
end

function TeamPanel:BindButton(Name, Handler)
    local Button = self:GetWidget(Name)
    if Button ~= nil then
        Button.OnClicked:Add(Handler, self)
    end
end

function TeamPanel:SetWidgetVisibility(Name, Value)
    local Widget = self:GetWidget(Name)
    if Widget ~= nil then
        Widget:SetVisibility(Value)
    end
end

function TeamPanel:GetRoster()
    local GameState = UGCGameSystem.GetGameState()
    return GameState and GameState.TeamRoster or {}
end

function TeamPanel:FindRosterInfo(PlayerKey)
    for _, Info in ipairs(self:GetRoster()) do
        if IsSamePlayerKey(Info.PlayerKey, PlayerKey) then
            return Info
        end
    end
    return nil
end

function TeamPanel:GetLocalInfo()
    return self:FindRosterInfo(self.LocalPlayerKey)
end

function TeamPanel:GetPendingInvite()
    local GameState = UGCGameSystem.GetGameState()
    local Notifications = GameState and GameState.PendingNotifications or {}
    local ActiveInviteKeys = {}
    self.RespondedInviteKeys = self.RespondedInviteKeys or {}

    for _, Notification in ipairs(Notifications) do
        if IsSamePlayerKey(Notification.TargetKey, self.LocalPlayerKey) then
            ActiveInviteKeys[tostring(Notification.FromKey)] = true
        end
    end
    for InviterKey, _ in pairs(self.RespondedInviteKeys) do
        if ActiveInviteKeys[InviterKey] ~= true then
            self.RespondedInviteKeys[InviterKey] = nil
        end
    end
    for _, Notification in ipairs(Notifications) do
        if IsSamePlayerKey(Notification.TargetKey, self.LocalPlayerKey) and
            self.RespondedInviteKeys[tostring(Notification.FromKey)] ~= true then
            return Notification
        end
    end
    return nil
end

function TeamPanel:MarkInviteResponded(InviterKey, bAccepted)
    self.RespondedInviteKeys = self.RespondedInviteKeys or {}
    if bAccepted then
        local GameState = UGCGameSystem.GetGameState()
        local Notifications = GameState and GameState.PendingNotifications or {}
        for _, Notification in ipairs(Notifications) do
            if IsSamePlayerKey(Notification.TargetKey, self.LocalPlayerKey) then
                self.RespondedInviteKeys[tostring(Notification.FromKey)] = true
            end
        end
    elseif InviterKey ~= nil then
        self.RespondedInviteKeys[tostring(InviterKey)] = true
    end
    self:RefreshEntry()
end

function TeamPanel:CallServerRPC(RPCName, ...)
    local PlayerController = self:GetLocalController()
    if PlayerController == nil then
        ugcprint("[Team] Client RPC rejected: PlayerController is nil, rpc=" .. tostring(RPCName))
        return false
    end
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, RPCName, ...)
    return true
end

function TeamPanel:Construct()
    self.WidgetRefs = {}
    self.RowPlayerKeys = {}
    self.SelectedPlayerKey = nil
    self.bOpen = false
    self.BlinkPhase = false
    self.LastRosterCount = -1
    self.LastPendingFrom = nil
    self.bLoggedRosterOverflow = false
    self.RespondedInviteKeys = {}

    local PlayerController = self:GetLocalController()
    self.LocalPlayerKey = PlayerController and PlayerController.PlayerKey or nil

    local WidgetNames = {
        "TeamEntryBtn", "TeamEntryBtnText", "PlayerListText", "PlayerScroll", "PlayerRows", "SelectedText",
        "ActionInput", "RefreshBtn", "RefreshBtnText", "CloseBtn", "CloseBtnText"
    }
    for _, Name in ipairs(WidgetNames) do
        self:GetWidget(Name)
    end

    for Index = 1, MAX_ROWS do
        local RowIndex = Index
        local ButtonName = "PlayerRow" .. tostring(RowIndex)
        self:GetWidget("PlayerRowContainer" .. tostring(RowIndex))
        self:GetWidget(ButtonName)
        self:GetWidget("PlayerRowText" .. tostring(RowIndex))
        for _, Action in ipairs({"Invite", "Kick", "Disband", "Leave"}) do
            self:GetWidget("Row" .. Action .. "Btn" .. tostring(RowIndex))
            self:GetWidget("Row" .. Action .. "Btn" .. tostring(RowIndex) .. "Text")
        end
        self:BindButton(ButtonName, function()
            self:OnPlayerRowClicked(RowIndex)
        end)
        self:BindButton("RowInviteBtn" .. tostring(RowIndex), function()
            self:OnRowActionClicked(RowIndex, "Invite")
        end)
        self:BindButton("RowKickBtn" .. tostring(RowIndex), function()
            self:OnRowActionClicked(RowIndex, "Kick")
        end)
        self:BindButton("RowDisbandBtn" .. tostring(RowIndex), function()
            self:OnRowActionClicked(RowIndex, "Disband")
        end)
        self:BindButton("RowLeaveBtn" .. tostring(RowIndex), function()
            self:OnRowActionClicked(RowIndex, "Leave")
        end)
    end
    self:BindButton("TeamEntryBtn", self.OnEntryClicked)
    self:BindButton("RefreshBtn", self.OnRefreshClicked)
    self:BindButton("CloseBtn", self.OnCloseClicked)

    self:SetPanelOpen(false)
    self:RefreshUI()
    self.RefreshTimer = UGCTimerUtility.CreateLuaTimer(0.8, function()
        self.BlinkPhase = not self.BlinkPhase
        self:RefreshUI()
    end, true)
    ugcprint("[Team] TeamPanel Construct local=" .. tostring(self.LocalPlayerKey))
end

function TeamPanel:SetPanelOpen(bOpen)
    self.bOpen = bOpen == true
    self:SetWidgetVisibility("TeamEntryBtn", self.bOpen and Hidden or Visible)
    local PanelWidgets = {"PlayerListText", "PlayerScroll", "PlayerRows", "SelectedText", "RefreshBtn", "CloseBtn"}
    for _, Name in ipairs(PanelWidgets) do
        self:SetWidgetVisibility(Name, self.bOpen and Visible or Hidden)
    end
    self:SetWidgetVisibility("ActionInput", Hidden)
end

function TeamPanel:RefreshEntry()
    local EntryButton = self:GetWidget("TeamEntryBtn")
    local EntryText = self:GetWidget("TeamEntryBtnText")
    local Pending = self:GetPendingInvite()
    local PendingFrom = Pending and Pending.FromKey or nil
    if tostring(self.LastPendingFrom) ~= tostring(PendingFrom) then
        self.LastPendingFrom = PendingFrom
        ugcprint("[Team] Client pending invite from=" .. tostring(PendingFrom))
    end
    if EntryText ~= nil then
        EntryText:SetText(Pending and (self.BlinkPhase and "队伍 ●" or "队伍") or "队伍")
    end
    if EntryButton ~= nil and not self.bOpen then
        EntryButton:SetVisibility(Visible)
    end
    local PlayerController = self:GetLocalController()
    local Popup = PlayerController and PlayerController.TeamInvitePopupInstance or nil
    if Pending == nil and Popup ~= nil and Popup.ClosePopup ~= nil then
        Popup:ClosePopup()
    end
end
function TeamPanel:GetTeamSize(Info)
    if Info == nil or Info.IsGrouped ~= true then
        return 0
    end
    local Count = 0
    for _, RosterInfo in ipairs(self:GetRoster()) do
        if RosterInfo.IsGrouped == true and tonumber(RosterInfo.SquadID) == tonumber(Info.SquadID) then
            Count = Count + 1
        end
    end
    return Count
end
function TeamPanel:RefreshRowActions(Index, Info, LocalInfo, LocalTeamSize)
    local Prefixes = {"Invite", "Kick", "Disband", "Leave"}
    for _, Prefix in ipairs(Prefixes) do
        self:SetWidgetVisibility("Row" .. Prefix .. "Btn" .. tostring(Index), Collapsed)
    end
    if Info == nil or LocalInfo == nil then
        return
    end
    local bSelf = IsSamePlayerKey(Info.PlayerKey, self.LocalPlayerKey)
    local bLocalGrouped = LocalInfo.IsGrouped == true
    local bLeader = LocalInfo.IsLeader == true
    if bSelf then
        if bLeader then
            self:SetWidgetVisibility("RowDisbandBtn" .. tostring(Index), Visible)
        elseif bLocalGrouped then
            self:SetWidgetVisibility("RowLeaveBtn" .. tostring(Index), Visible)
        end
        return
    end
    if bLeader and Info.IsGrouped == true and tonumber(Info.SquadID) == tonumber(LocalInfo.SquadID) then
        self:SetWidgetVisibility("RowKickBtn" .. tostring(Index), Visible)
    elseif Info.IsGrouped ~= true and (not bLocalGrouped or bLeader) and
        (not bLeader or LocalTeamSize < TeamConfig.MAX_PLAYERS_PER_TEAM) then
        self:SetWidgetVisibility("RowInviteBtn" .. tostring(Index), Visible)
    end
end
function TeamPanel:RefreshRows()
    local ViewRoster = {}
    for _, Info in ipairs(self:GetRoster()) do
        table.insert(ViewRoster, Info)
    end
    if self.LastRosterCount ~= #ViewRoster then
        self.LastRosterCount = #ViewRoster
        ugcprint("[Team] Client roster count=" .. tostring(self.LastRosterCount))
    end
    if #ViewRoster > MAX_ROWS and not self.bLoggedRosterOverflow then
        self.bLoggedRosterOverflow = true
        ugcprint("[Team] Client roster overflow count=" .. tostring(#ViewRoster) .. " max=" .. tostring(MAX_ROWS))
    end
    table.sort(ViewRoster, function(A, B)
        if A.IsGrouped ~= B.IsGrouped then
            return A.IsGrouped == true
        end
        if tonumber(A.SquadID) ~= tonumber(B.SquadID) then
            return (tonumber(A.SquadID) or 0) < (tonumber(B.SquadID) or 0)
        end
        return tostring(A.PlayerName) < tostring(B.PlayerName)
    end)
    self.RowPlayerKeys = {}
    local LocalInfo = self:GetLocalInfo()
    local LocalTeamSize = self:GetTeamSize(LocalInfo)
    for Index = 1, MAX_ROWS do
        local Container = self:GetWidget("PlayerRowContainer" .. tostring(Index))
        local Button = self:GetWidget("PlayerRow" .. tostring(Index))
        local Text = self:GetWidget("PlayerRowText" .. tostring(Index))
        local Info = ViewRoster[Index]
        if Info ~= nil then
            self.RowPlayerKeys[Index] = Info.PlayerKey
            local Status = Info.IsLeader and "队长" or (Info.IsGrouped and "队员" or "未组队")
            local Selected = IsSamePlayerKey(self.SelectedPlayerKey, Info.PlayerKey) and "  <" or ""
            if Text ~= nil then
                Text:SetText(string.format("%s  [%s]%s", tostring(Info.PlayerName), Status, Selected))
            end
            if Button ~= nil then
                Button:SetVisibility(Visible)
            end
            if Container ~= nil then
                Container:SetVisibility(Visible)
            end
        else
            if Container ~= nil then
                Container:SetVisibility(Collapsed)
            elseif Button ~= nil then
                Button:SetVisibility(Collapsed)
            end
        end
        self:RefreshRowActions(Index, Info, LocalInfo, LocalTeamSize)
    end
end
function TeamPanel:RefreshActions()
    local SelectedInfo = self:FindRosterInfo(self.SelectedPlayerKey)
    self:SetWidgetVisibility("RefreshBtn", Visible)
    self:SetWidgetVisibility("CloseBtn", Visible)
    local SelectedText = self:GetWidget("SelectedText")
    if SelectedText ~= nil then
        SelectedText:SetText(SelectedInfo and ("已选择：" .. tostring(SelectedInfo.PlayerName)) or
                                 "点击玩家选择操作目标")
    end
end

function TeamPanel:RefreshUI()
    if self.LocalPlayerKey == nil then
        local PlayerController = self:GetLocalController()
        self.LocalPlayerKey = PlayerController and PlayerController.PlayerKey or nil
    end
    self:RefreshEntry()
    if not self.bOpen then
        return
    end
    self:RefreshRows()
    self:RefreshActions()
end

function TeamPanel:OpenInvitePopup(Pending)
    local PlayerController = self:GetLocalController()
    if PlayerController == nil or Pending == nil then
        return
    end

    local Popup = PlayerController.TeamInvitePopupInstance
    if Popup == nil then
        local PopupPath = UGCMapInfoLib.GetRootLongPackagePath() ..
                              "Asset/Blueprint/UI/TeamInvitePopup.TeamInvitePopup_C"
        local PopupClass = UE.LoadClass(PopupPath)
        if PopupClass == nil then
            ugcprint("[Team] Client TeamInvitePopup class load failed: " .. PopupPath)
            return
        end
        Popup = UserWidget.NewWidgetObjectBP(PlayerController, PopupClass)
        if Popup == nil then
            ugcprint("[Team] Client TeamInvitePopup create failed")
            return
        end
        PlayerController.TeamInvitePopupInstance = Popup
        Popup:AddToViewport(16000)
    end

    local InviterInfo = self:FindRosterInfo(Pending.FromKey)
    local InviterName = InviterInfo and tostring(InviterInfo.PlayerName) or tostring(Pending.FromKey)
    if Popup.ShowInvite ~= nil then
        Popup:ShowInvite(Pending.FromKey, InviterName)
    end
end

function TeamPanel:OnEntryClicked()
    local Pending = self:GetPendingInvite()
    if Pending ~= nil then
        self:OpenInvitePopup(Pending)
        return
    end
    self:SetPanelOpen(true)
    self:RefreshUI()
end

function TeamPanel:OnPlayerRowClicked(Index)
    self.SelectedPlayerKey = self.RowPlayerKeys[Index]
    self:RefreshUI()
end
function TeamPanel:OnRowActionClicked(Index, Action)
    self.SelectedPlayerKey = self.RowPlayerKeys[Index]
    if self.SelectedPlayerKey == nil then
        return
    end
    self:RefreshRows()
    self:RefreshActions()
    if Action == "Invite" then
        self:OnInviteClicked()
    elseif Action == "Kick" then
        self:OnKickClicked()
    elseif Action == "Disband" then
        self:OnDisbandClicked()
    elseif Action == "Leave" then
        self:OnLeaveClicked()
    end
end

function TeamPanel:OnInviteClicked()
    if self.SelectedPlayerKey ~= nil then
        self:CallServerRPC("ServerRequestInvitePlayer", self.SelectedPlayerKey)
    end
end

function TeamPanel:OnKickClicked()
    if self.SelectedPlayerKey ~= nil then
        self:CallServerRPC("ServerRequestKickPlayer", self.SelectedPlayerKey)
    end
end

function TeamPanel:OnDisbandClicked()
    self:CallServerRPC("ServerRequestDisbandTeam")
end

function TeamPanel:OnLeaveClicked()
    self:CallServerRPC("ServerRequestLeaveTeam")
end

function TeamPanel:OnRefreshClicked()
    self:RefreshUI()
end

function TeamPanel:OnCloseClicked()
    self:SetPanelOpen(false)
    self:RefreshUI()
end

function TeamPanel:Destruct()
    if self.RefreshTimer ~= nil then
        UGCTimerUtility.StopLuaTimer(self.RefreshTimer)
        self.RefreshTimer = nil
    end
    local PlayerController = self:GetLocalController()
    if PlayerController ~= nil and PlayerController.TeamInvitePopupInstance ~= nil and
        PlayerController.TeamInvitePopupInstance.ClosePopup ~= nil then
        PlayerController.TeamInvitePopupInstance:ClosePopup()
    end
    if PlayerController ~= nil and PlayerController.TeamPanelInstance == self then
        PlayerController.TeamPanelInstance = nil
    end
end

return TeamPanel