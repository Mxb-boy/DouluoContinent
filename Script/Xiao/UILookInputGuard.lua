local UILookInputGuard = {
    ActiveOwners = {},
    bLookInputLocked = false,
    LockedPlayerController = nil,
}

local function GetLocalPlayerController(WorldContext)
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if PlayerController == nil and WorldContext ~= nil then
        PlayerController = GameplayStatics.GetPlayerController(WorldContext, 0)
    end
    return PlayerController
end

local function HasActiveOwner()
    return next(UILookInputGuard.ActiveOwners) ~= nil
end

local function UpdateLookInputLock(WorldContext)
    local bShouldLock = HasActiveOwner()
    if bShouldLock == UILookInputGuard.bLookInputLocked then
        return
    end

    local PlayerController = GetLocalPlayerController(WorldContext)
    if PlayerController == nil then
        ugcprint("[UILookInputGuard] local PlayerController is nil")
        return
    end

    PlayerController:SetIgnoreLookInput(bShouldLock)
    UILookInputGuard.bLookInputLocked = bShouldLock
    UILookInputGuard.LockedPlayerController = bShouldLock and PlayerController or nil
    ugcprint("[UILookInputGuard] look input locked=" .. tostring(bShouldLock))
end

function UILookInputGuard.Enter(Owner, WorldContext)
    if Owner == nil then
        return
    end

    UILookInputGuard.ActiveOwners[Owner] = true
    UpdateLookInputLock(WorldContext or Owner)
end

function UILookInputGuard.Leave(Owner, WorldContext)
    if Owner == nil or UILookInputGuard.ActiveOwners[Owner] == nil then
        return
    end

    UILookInputGuard.ActiveOwners[Owner] = nil
    UpdateLookInputLock(
        WorldContext or UILookInputGuard.LockedPlayerController or Owner
    )
end

return UILookInputGuard
