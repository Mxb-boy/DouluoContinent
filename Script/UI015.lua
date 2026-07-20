---@class UI015_C:UUserWidget
---@field Button_71 UButton
---@field Image_31 UImage
---@field Image_32 UImage
---@field Image_33 UImage
---@field kj05 kj05_C
---@field PlayerCellGrid UWrapBox
---@field PlayerScroll UScrollBox
--Edit Below--
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")
local Ma_NumShow = UGCGameSystem.UGCRequire("Script.Ma.Ma_NumShow")

local UI015 = {}
local Visible = 0
local Collapsed = 1
local MAX_ROWS = TeamConfig.MAX_SERVER_PLAYERS

local function IsSamePlayerKey(KeyA, KeyB)
    return KeyA ~= nil and KeyB ~= nil and tostring(KeyA) == tostring(KeyB)
end

local function RPCArgsToString(...)
    local Values = {...}
    local Parts = {}
    for Index = 1, #Values do
        Parts[Index] = tostring(Values[Index])
    end
    return table.concat(Parts, ",")
end

function UI015:GetLocalController()
    return UGCGameSystem.GetLocalPlayerController()
end

function UI015:GetWidget(Name)
    if self.WidgetRefs[Name] == nil then
        self.WidgetRefs[Name] = self:GetWidgetFromName(Name)
    end
    return self.WidgetRefs[Name]
end

function UI015:GetCellWidget(Cell, Name)
    if Cell == nil then
        return nil
    end
    local Widget = Cell[Name]
    if Widget == nil and Cell.GetWidgetFromName ~= nil then
        Widget = Cell:GetWidgetFromName(Name)
    end
    return Widget
end

function UI015:SetCellWidgetVisibility(Cell, Name, Value)
    local Widget = self:GetCellWidget(Cell, Name)
    if Widget ~= nil then
        Widget:SetVisibility(Value)
    end
end

function UI015:BindCellButton(Cell, Name, Index, Action)
    local Button = self:GetCellWidget(Cell, Name)
    if Button ~= nil then
        local RowIndex = Index
        local RowAction = Action
        Button.OnClicked:Add(function()
            self:OnRowActionClicked(RowIndex, RowAction)
        end, self)
    end
end

function UI015:GetRoster()
    local GameState = UGCGameSystem.GetGameState()
    return GameState and GameState.TeamRoster or {}
end

function UI015:FindRosterInfo(PlayerKey)
    for _, Info in ipairs(self:GetRoster()) do
        if IsSamePlayerKey(Info.PlayerKey, PlayerKey) then
            return Info
        end
    end
    return nil
end

function UI015:GetLocalInfo()
    return self:FindRosterInfo(self.LocalPlayerKey)
end

function UI015:GetPendingInvite()
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

function UI015:MarkInviteResponded(InviterKey, bAccepted)
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

function UI015:CallServerRPC(RPCName, ...)
    self:RefreshLocalPlayerKey()
    local PlayerController = self:GetLocalController()
    if PlayerController == nil then
        ugcprint("[Team] Client RPC rejected: PlayerController is nil, rpc=" .. tostring(RPCName))
        return false
    end
    ugcprint("[Team] Client RPC send build=" .. tostring(TeamConfig.BUILD_ID) .. " rpc=" .. tostring(RPCName) ..
                 " localKey=" .. tostring(self.LocalPlayerKey) .. " args=" .. RPCArgsToString(...))
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, RPCName, ...)
    return true
end

function UI015:RefreshLocalPlayerKey()
    local CurrentKey = UGCGameSystem.GetLocalPlayerKey()
    if CurrentKey == nil then
        local PlayerController = self:GetLocalController()
        CurrentKey = PlayerController and PlayerController.PlayerKey or nil
    end
    if CurrentKey ~= nil and not IsSamePlayerKey(CurrentKey, self.LocalPlayerKey) then
        ugcprint("[Team] Client local key refreshed old=" .. tostring(self.LocalPlayerKey) .. " new=" ..
                     tostring(CurrentKey) .. " newType=" .. type(CurrentKey))
        self.LocalPlayerKey = CurrentKey
    end
end

function UI015:CreatePlayerCells()
    local Grid = self:GetWidget("PlayerCellGrid")
    if Grid == nil then
        ugcprint("[Team] UI015 PlayerCellGrid is nil")
        return
    end

    Grid:ClearChildren()
    self.PlayerCells = {}
    local CellPath = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/kj05.kj05_C"
    local CellClass = UE.LoadClass(CellPath)
    if CellClass == nil then
        ugcprint("[Team] Client kj05 class load failed: " .. CellPath)
        return
    end

    local PlayerController = self:GetLocalController()
    if PlayerController == nil then
        ugcprint("[Team] Client kj05 creation rejected: PlayerController is nil")
        return
    end

    for Index = 1, MAX_ROWS do
        local Cell = UserWidget.NewWidgetObjectBP(PlayerController, CellClass)
        if Cell == nil then
            ugcprint("[Team] Client kj05 create failed index=" .. tostring(Index))
            return
        end
        Grid:AddChild(Cell)
        self.PlayerCells[Index] = Cell
        Cell:SetVisibility(Collapsed)

        for _, ButtonName in ipairs({"Button_3", "Button_0", "Button_108", "Button_2"}) do
            self:SetCellWidgetVisibility(Cell, ButtonName, Collapsed)
        end
        self:SetCellWidgetVisibility(Cell, "Button_1", Collapsed)
        self:SetCellWidgetVisibility(Cell, "TextBlock_160", Collapsed)
        self:SetCellWidgetVisibility(Cell, "Image_113", Collapsed)
        self:SetCellWidgetVisibility(Cell, "TextBlock_156", Collapsed)
        self:BindCellButton(Cell, "Button_3", Index, "Invite")
        self:BindCellButton(Cell, "Button_0", Index, "Kick")
        self:BindCellButton(Cell, "Button_108", Index, "Disband")
        self:BindCellButton(Cell, "Button_2", Index, "Leave")
    end
end

function UI015:Construct()
    self.WidgetRefs = {}
    self.PlayerCells = {}
    self.RowPlayerKeys = {}
    self.SelectedPlayerKey = nil
    self.bOpen = false
    self.BlinkPhase = false
    self.LastRosterCount = -1
    self.LastPendingFrom = nil
    self.bLoggedRosterOverflow = false
    self.RespondedInviteKeys = {}

    self.LocalPlayerKey = UGCGameSystem.GetLocalPlayerKey()
    if self.LocalPlayerKey == nil then
        local PlayerController = self:GetLocalController()
        self.LocalPlayerKey = PlayerController and PlayerController.PlayerKey or nil
    end
    self:GetWidget("PlayerScroll")
    self:GetWidget("PlayerCellGrid")
    self:GetWidget("Button_71")
    self:CreatePlayerCells()

    local CloseButton = self:GetWidget("Button_71")
    if CloseButton ~= nil then
        CloseButton.OnClicked:Add(self.OnCloseClicked, self)
    end

    self:SetPanelOpen(false)
    self:RefreshUI()
    self.RefreshTimer = UGCTimerUtility.CreateLuaTimer(0.8, function()
        self.BlinkPhase = not self.BlinkPhase
        self:RefreshUI()
    end, true)
    ugcprint("[Team] UI015 Construct build=" .. tostring(TeamConfig.BUILD_ID) .. " local=" ..
                 tostring(self.LocalPlayerKey) .. " keyType=" .. type(self.LocalPlayerKey))
end

function UI015:SetPanelOpen(bOpen)
    self.bOpen = bOpen == true
    self:SetVisibility(self.bOpen and Visible or Collapsed)
end

function UI015:GetTeamEntryButton()
    local PlayerController = self:GetLocalController()
    local MainUI = PlayerController and PlayerController.MainUIInstance or nil
    return MainUI and MainUI.Button_8 or nil
end

function UI015:RefreshEntry()
    local Pending = self:GetPendingInvite()
    local PendingFrom = Pending and Pending.FromKey or nil
    if tostring(self.LastPendingFrom) ~= tostring(PendingFrom) then
        self.LastPendingFrom = PendingFrom
        ugcprint("[Team] Client pending invite from=" .. tostring(PendingFrom))
    end

    local EntryButton = self:GetTeamEntryButton()
    if EntryButton ~= nil and EntryButton.SetRenderOpacity ~= nil then
        EntryButton:SetRenderOpacity(Pending and (self.BlinkPhase and 1.0 or 0.35) or 1.0)
    end

    local PlayerController = self:GetLocalController()
    local Popup = PlayerController and PlayerController.TeamInvitePopupInstance or nil
    if Pending == nil and Popup ~= nil and Popup.ClosePopup ~= nil then
        Popup:ClosePopup()
    end
end

function UI015:GetTeamSize(Info)
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

function UI015:RefreshCellActions(Index, Cell, Info, LocalInfo, LocalTeamSize)
    for _, ButtonName in ipairs({"Button_3", "Button_0", "Button_108", "Button_2"}) do
        self:SetCellWidgetVisibility(Cell, ButtonName, Collapsed)
    end

    local bCellLeader = Info ~= nil and Info.IsLeader == true
    self:SetCellWidgetVisibility(Cell, "Image_113", bCellLeader and Visible or Collapsed)
    self:SetCellWidgetVisibility(Cell, "TextBlock_156", bCellLeader and Visible or Collapsed)
    if Info == nil or LocalInfo == nil then
        return
    end

    local bSelf = IsSamePlayerKey(Info.PlayerKey, self.LocalPlayerKey)
    local bLocalGrouped = LocalInfo.IsGrouped == true
    local bLeader = LocalInfo.IsLeader == true
    if bSelf then
        if bLeader then
            self:SetCellWidgetVisibility(Cell, "Button_108", Visible)
        elseif bLocalGrouped then
            self:SetCellWidgetVisibility(Cell, "Button_2", Visible)
        end
        return
    end

    if bLeader and Info.IsGrouped == true and tonumber(Info.SquadID) == tonumber(LocalInfo.SquadID) then
        self:SetCellWidgetVisibility(Cell, "Button_0", Visible)
    elseif Info.IsGrouped ~= true and (not bLocalGrouped or bLeader) and
        (not bLeader or LocalTeamSize < TeamConfig.MAX_PLAYERS_PER_TEAM) then
        self:SetCellWidgetVisibility(Cell, "Button_3", Visible)
    end
end

function UI015:RefreshRows()
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
        local Cell = self.PlayerCells[Index]
        local Info = ViewRoster[Index]
        if Cell ~= nil and Info ~= nil then
            self.RowPlayerKeys[Index] = Info.PlayerKey
            local NameText = self:GetCellWidget(Cell, "TextBlock_75")
            if NameText ~= nil then
                NameText:SetText(tostring(Info.PlayerName))
            end
            local CombatPowerText = self:GetCellWidget(Cell, "TextBlock_76")
            if CombatPowerText ~= nil then
                CombatPowerText:SetText("战力：" .. Ma_NumShow.Format(tonumber(Info.CombatPower) or 0))
                CombatPowerText:SetVisibility(Visible)
            end
            Cell:SetVisibility(Visible)
        elseif Cell ~= nil then
            Cell:SetVisibility(Collapsed)
        end
        self:RefreshCellActions(Index, Cell, Info, LocalInfo, LocalTeamSize)
    end
end

function UI015:RefreshUI()
    self:RefreshLocalPlayerKey()
    self:RefreshEntry()
    if not self.bOpen then
        return
    end
    self:RefreshRows()
end

function UI015:OpenInvitePopup(Pending)
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
        Popup:AddToViewport(TeamConfig.UI_Z_ORDER + 6000)
    end

    local InviterInfo = self:FindRosterInfo(Pending.FromKey)
    local InviterName = InviterInfo and tostring(InviterInfo.PlayerName) or tostring(Pending.FromKey)
    if Popup.ShowInvite ~= nil then
        Popup:ShowInvite(Pending.FromKey, InviterName)
    end
end

function UI015:OnEntryClicked()
    ugcprint("[Team] Client entry click build=" .. tostring(TeamConfig.BUILD_ID) .. " local=" ..
                 tostring(self.LocalPlayerKey))
    local Pending = self:GetPendingInvite()
    if Pending ~= nil then
        self:OpenInvitePopup(Pending)
        return
    end
    self:SetPanelOpen(true)
    self:RefreshUI()
end

function UI015:OnRowActionClicked(Index, Action)
    self.SelectedPlayerKey = self.RowPlayerKeys[Index]
    if self.SelectedPlayerKey == nil then
        return
    end
    ugcprint("[Team] Client row action click build=" .. tostring(TeamConfig.BUILD_ID) .. " action=" ..
                 tostring(Action) .. " local=" .. tostring(self.LocalPlayerKey) .. " target=" ..
                 tostring(self.SelectedPlayerKey))
    if Action == "Invite" then
        self:CallServerRPC("ServerRequestInvitePlayer", self.SelectedPlayerKey)
    elseif Action == "Kick" then
        self:CallServerRPC("ServerRequestKickPlayer", self.SelectedPlayerKey)
    elseif Action == "Disband" then
        self:CallServerRPC("ServerRequestDisbandTeam")
    elseif Action == "Leave" then
        self:CallServerRPC("ServerRequestLeaveTeam")
    end
end

function UI015:OnCloseClicked()
    ugcprint("[Team] Client close click build=" .. tostring(TeamConfig.BUILD_ID) .. " local=" ..
                 tostring(self.LocalPlayerKey))
    self:SetPanelOpen(false)
    self:RefreshUI()
end

function UI015:Destruct()
    if self.RefreshTimer ~= nil then
        UGCTimerUtility.StopLuaTimer(self.RefreshTimer)
        self.RefreshTimer = nil
    end
    local EntryButton = self:GetTeamEntryButton()
    if EntryButton ~= nil and EntryButton.SetRenderOpacity ~= nil then
        EntryButton:SetRenderOpacity(1.0)
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

return UI015
