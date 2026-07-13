---@class BP_PlayerTitleActor_C:AActor
---@field Widget UWidgetComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local BP_PlayerTitleActor = {}
local TITLE_CHECK_INTERVAL = 2
 
function BP_PlayerTitleActor:ReceiveBeginPlay()
    BP_PlayerTitleActor.SuperClass.ReceiveBeginPlay(self)
    self.CurrentTitleID = self.CurrentTitleID or 0
    self.TitleCheckElapsed = TITLE_CHECK_INTERVAL
    local ownerPawn = UGCActorComponentUtility.GetOwner(self)
    self.OwnerPawn = ownerPawn
    if ownerPawn and ownerPawn:IsLocallyControlled() then
        self.IsLocalTitle = true
    else
        self.IsLocalTitle = false
    end

    self.ShouldShowTitle = (not self.IsLocalTitle) and self.CurrentTitleID > 0
    if self.Widget then
        self.Widget:SetVisibility(self.ShouldShowTitle)
    end
end

function BP_PlayerTitleActor:GetTitleWidget()
    if self.TitleWidget and UE.IsValid(self.TitleWidget) then
        return self.TitleWidget
    end

    if self.Widget == nil then
        return nil
    end

    self.TitleWidget = self.Widget:GetUserWidgetObject()
    return self.TitleWidget
end

function BP_PlayerTitleActor:ApplyTitleToWidget(titleID)
    local titleWidget = self:GetTitleWidget()
    if titleWidget == nil or titleWidget.SetTitle == nil then
        return false
    end

    titleWidget:SetTitle(titleID)
    if self.Widget and self.Widget.RequestRedraw then
        self.Widget:RequestRedraw()
    end
    return true
end

function BP_PlayerTitleActor:SetTitle(titleID)
    self.CurrentTitleID = tonumber(titleID) or 0
    if self:ApplyTitleToWidget(self.CurrentTitleID) then
        self.LastAppliedTitleID = self.CurrentTitleID
    else
        self.LastAppliedTitleID = nil
    end
end

function BP_PlayerTitleActor:ReceiveTick(DeltaTime)
    BP_PlayerTitleActor.SuperClass.ReceiveTick(self, DeltaTime)

    local safeDeltaTime = tonumber(DeltaTime) or 0.016
    self.TitleCheckElapsed = (self.TitleCheckElapsed or TITLE_CHECK_INTERVAL) + safeDeltaTime

    if self.TitleCheckElapsed >= TITLE_CHECK_INTERVAL then
        self.TitleCheckElapsed = 0

        local ownerPawn = self.OwnerPawn or UGCActorComponentUtility.GetOwner(self)
        self.OwnerPawn = ownerPawn
        self.IsLocalTitle = ownerPawn and ownerPawn:IsLocallyControlled() or false

        local titleID = self.CurrentTitleID or 0
        if titleID == 0 then
            titleID = ownerPawn and ownerPawn.EquippedTitleID or 0
        end

        local shouldShow = (not self.IsLocalTitle) and titleID > 0
        self.ShouldShowTitle = shouldShow
        if self.Widget then
            self.Widget:SetVisibility(shouldShow)
        end

        if shouldShow and titleID ~= self.LastAppliedTitleID then
            if self:ApplyTitleToWidget(titleID) then
                self.LastAppliedTitleID = titleID
            end
        end
    end

    -- 自己看不到自己的称号；没装备称号时也不显示整个Widget。
    if not self.ShouldShowTitle then
        return
    end

    if not self.Widget then
        return
    end

    local ownerPawn = self.OwnerPawn
    if ownerPawn then
        local pawnLocation = ownerPawn:K2_GetActorLocation()
        local titleLocation = {
            X = pawnLocation.X,
            Y = pawnLocation.Y,
            Z = pawnLocation.Z + 40
        }
        self:K2_SetActorLocation(titleLocation, false, nil, false)
    end

    local playerController = GameplayStatics.GetPlayerController(self, 0)
    local cameraManager = playerController and playerController.PlayerCameraManager
    if not cameraManager then
        return
    end

    local titleLocation = self:K2_GetActorLocation()
    local cameraLocation = cameraManager:GetCameraLocation()
    local lookRotation = KismetMathLibrary.FindLookAtRotation(
        titleLocation,
        cameraLocation
    )

    -- Only rotate horizontally so the title faces the local camera.
    self.Widget:K2_SetWorldRotation(
        {Pitch = 0, Yaw = lookRotation.Yaw, Roll = 0},
        false,
        nil,
        false
    )
end

--[[
function BP_PlayerTitleActor:ReceiveEndPlay()
    BP_PlayerTitleActor.SuperClass.ReceiveEndPlay(self) 
end
--]]

function BP_PlayerTitleActor:GetReplicatedProperties()
    return {"CurrentTitleID"}
end

--[[
function BP_PlayerTitleActor:GetAvailableServerRPCs()
    return
end
--]]

return BP_PlayerTitleActor
