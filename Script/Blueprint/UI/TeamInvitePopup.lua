---@class TeamInvitePopup_C:UUserWidget
local TeamInvitePopup = {}

function TeamInvitePopup:GetLocalController()
    return UGCGameSystem.GetLocalPlayerController()
end

function TeamInvitePopup:Construct()
    self.InviteText = self:GetWidgetFromName("InviteText")
    self.AcceptBtn = self:GetWidgetFromName("AcceptBtn")
    self.RejectBtn = self:GetWidgetFromName("RejectBtn")
    self.InviterKey = nil
    self.bResponded = false
    self.bClosing = false

    if self.AcceptBtn ~= nil then
        self.AcceptBtn.OnClicked:Add(self.OnAcceptClicked, self)
    end
    if self.RejectBtn ~= nil then
        self.RejectBtn.OnClicked:Add(self.OnRejectClicked, self)
    end
end

function TeamInvitePopup:ShowInvite(InviterKey, InviterName)
    self.InviterKey = InviterKey
    self.bResponded = false
    self.bClosing = false
    if self.InviteText ~= nil then
        self.InviteText:SetText(tostring(InviterName or InviterKey) .. " 邀请你加入队伍")
    end
    self:SetVisibility(0)
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
    if TeamPanel ~= nil and TeamPanel.MarkInviteResponded ~= nil then
        TeamPanel:MarkInviteResponded(self.InviterKey, bAccepted)
    end
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "ServerRespondInvite", self.InviterKey, bAccepted)
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
