---@class TeamInvitePopup_C:UUserWidget
---@field AcceptBtn UButton
---@field InviteText UTextBlock
---@field RejectBtn UButton
--Edit Below--
---@class TeamInvitePopup_C:UUserWidget
local TeamConfig = UGCGameSystem.UGCRequire("Script.Common.TeamConfig")
local TeamInvitePopup = {}

function TeamInvitePopup:GetLocalController()
    return UGCGameSystem.GetLocalPlayerController()
end

function TeamInvitePopup:Construct()
    self.InviteText = self:GetWidgetFromName("InviteText")
    self.AcceptBtn = self:GetWidgetFromName("AcceptBtn")
    self.RejectBtn = self:GetWidgetFromName("RejectBtn")
    self.InviterKey = nil
    self.NotificationType = nil
    self.NotificationTeamID = nil
    self.bResponded = false
    self.bClosing = false

    if self.AcceptBtn ~= nil then
        self.AcceptBtn.OnClicked:Add(self.OnAcceptClicked, self)
    end
    if self.RejectBtn ~= nil then
        self.RejectBtn.OnClicked:Add(self.OnRejectClicked, self)
    end
end

function TeamInvitePopup:ShowNotification(NotificationType, FromKey, FromName, TeamID)
    self.NotificationType = NotificationType or TeamConfig.INVITE_TYPE
    self.NotificationTeamID = TeamID
    self.InviterKey = FromKey
    self.bResponded = false
    self.bClosing = false
    if self.InviteText ~= nil then
        if self.NotificationType == TeamConfig.JOIN_REQUEST_TYPE then
            self.InviteText:SetText(tostring(FromName or FromKey) .. " 申请加入你的队伍")
        else
            self.InviteText:SetText(tostring(FromName or FromKey) .. " 邀请你加入队伍")
        end
    end
    self:SetVisibility(0)
end

function TeamInvitePopup:ShowInvite(InviterKey, InviterName)
    self:ShowNotification(TeamConfig.INVITE_TYPE, InviterKey, InviterName, nil)
end

function TeamInvitePopup:RespondToInvite(bAccepted)
    if self.bResponded or self.InviterKey == nil then
        return
    end

    local PlayerController = self:GetLocalController()
    if PlayerController == nil then
        ugcprint("[Team] Client invite response rejected: PlayerController is nil")
        return
    end

    self.bResponded = true
    local TeamPanel = PlayerController.TeamPanelInstance
    if TeamPanel ~= nil and TeamPanel.MarkNotificationResponded ~= nil then
        TeamPanel:MarkNotificationResponded(self.NotificationType, self.InviterKey, self.NotificationTeamID, bAccepted)
    end
    ugcprint("[Team] Client notification response click build=" .. tostring(TeamConfig.BUILD_ID) .. " type=" ..
                 tostring(self.NotificationType) .. " local=" .. tostring(PlayerController.PlayerKey) .. " from=" ..
                 tostring(self.InviterKey) .. " accept=" .. tostring(bAccepted))
    local RPCName = self.NotificationType == TeamConfig.JOIN_REQUEST_TYPE and "ServerRespondJoinRequest" or
                        "ServerRespondInvite"
    if TeamPanel ~= nil and TeamPanel.CallServerRPC ~= nil then
        TeamPanel:CallServerRPC(RPCName, self.InviterKey, bAccepted)
    else
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, RPCName, self.InviterKey, bAccepted)
    end
    self:ClosePopup()
end

function TeamInvitePopup:OnAcceptClicked()
    self:RespondToInvite(true)
end

function TeamInvitePopup:OnRejectClicked()
    self:RespondToInvite(false)
end

function TeamInvitePopup:ClosePopup()
    if self.bClosing then
        return
    end
    self.bClosing = true
    local PlayerController = self:GetLocalController()
    if PlayerController ~= nil and PlayerController.TeamInvitePopupInstance == self then
        PlayerController.TeamInvitePopupInstance = nil
    end
    self:RemoveFromParent()
end

function TeamInvitePopup:Destruct()
    local PlayerController = self:GetLocalController()
    if PlayerController ~= nil and PlayerController.TeamInvitePopupInstance == self then
        PlayerController.TeamInvitePopupInstance = nil
    end
end

return TeamInvitePopup
