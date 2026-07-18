---@class TeamPanel_C:UUserWidget
---@field ActionInput UEditableTextBox
---@field CloseBtn UButton
---@field DisbandBtn UButton
---@field InviteBtn UButton
---@field KickBtn UButton
---@field LeaveBtn UButton
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
---@field TeamEntryBtn UButton
--Edit Below--
---@class TeamPanel_C:UUserWidget
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")

local TeamPanel = {}
local Visible = 0
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
        "ActionInput", "InviteBtn", "InviteBtnText", "KickBtn", "KickBtnText", "DisbandBtn", "DisbandBtnText",
        "LeaveBtn", "LeaveBtnText", "RefreshBtn", "RefreshBtnText", "CloseBtn", "CloseBtnText"
    }
    for _, Name in ipairs(WidgetNames) do
        self:GetWidget(Name)
    end

    for Index = 1, MAX_ROWS do
        local RowIndex = Index
        local ButtonName = "PlayerRow" .. tostring(RowIndex)
        self:GetWidget(ButtonName)
        self:GetWidget("PlayerRowText" .. tostring(RowIndex))
        self:BindButton(ButtonName, function()
            self:OnPlayerRowClicked(RowIndex)
        end)
    end

    self:BindButton("TeamEntryBtn", self.OnEntryClicked)
    self:BindButton("InviteBtn", self.OnInviteClicked)
    self:BindButton("KickBtn", self.OnKickClicked)
    self:BindButton("DisbandBtn", self.OnDisbandClicked)
    self:BindButton("LeaveBtn", self.OnLeaveClicked)
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
    local PanelWidgets = {"PlayerListText", "PlayerScroll", "PlayerRows", "SelectedText", "InviteBtn", "KickBtn",
                          "DisbandBtn", "LeaveBtn", "RefreshBtn", "CloseBtn"}
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
    for Index = 1, MAX_ROWS do
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
        elseif Button ~= nil then
            Button:SetVisibility(Hidden)
        end
    end
end

function TeamPanel:RefreshActions()
    local LocalInfo = self:GetLocalInfo()
    local SelectedInfo = self:FindRosterInfo(self.SelectedPlayerKey)
    local bGrouped = LocalInfo ~= nil and LocalInfo.IsGrouped == true
    local bLeader = LocalInfo ~= nil and LocalInfo.IsLeader == true
    local bCanInvite = (not bGrouped or bLeader) and SelectedInfo ~= nil and
                           not IsSamePlayerKey(SelectedInfo.PlayerKey, self.LocalPlayerKey) and
                           SelectedInfo.IsGrouped ~= true
    local bCanKick = bLeader and SelectedInfo ~= nil and
                         tonumber(SelectedInfo.SquadID) == tonumber(LocalInfo.SquadID) and
                         not IsSamePlayerKey(SelectedInfo.PlayerKey, self.LocalPlayerKey)

    self:SetWidgetVisibility("InviteBtn", bCanInvite and Visible or Hidden)
    self:SetWidgetVisibility("KickBtn", bCanKick and Visible or Hidden)
    self:SetWidgetVisibility("DisbandBtn", bLeader and Visible or Hidden)
    self:SetWidgetVisibility("LeaveBtn", bGrouped and not bLeader and Visible or Hidden)
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
