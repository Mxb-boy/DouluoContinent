local OrbitWeaponFollower = {}

local DEFAULT_ROTATION_SPEED = 32
local HEIGHT_OFFSET = 0
local MAX_DELTA_TIME = 0.1

local function IsValid(Object)
    return Object ~= nil and (UE == nil or UE.IsValid == nil or UE.IsValid(Object))
end

local function IsAuthority(Actor)
    if Actor ~= nil and Actor.HasAuthority ~= nil then
        local Success, Result = pcall(Actor.HasAuthority, Actor)
        if Success then
            return Result == true
        end
    end
    if UGCActorComponentUtility ~= nil and
        UGCActorComponentUtility.HasAuthority ~= nil then
        local Success, Result = pcall(UGCActorComponentUtility.HasAuthority, Actor)
        if Success then
            return Result == true
        end
    end
    -- If authority cannot be determined, do not overwrite an authoritative Actor.
    return true
end

local function GetOwner(Actor)
    if UGCActorComponentUtility == nil or
        UGCActorComponentUtility.GetOwner == nil then
        return nil
    end
    local Success, Owner = pcall(UGCActorComponentUtility.GetOwner, Actor)
    if Success and IsValid(Owner) then
        return Owner
    end
    return nil
end

local function GetGameTimeSeconds(WorldContext)
    if UGCGameSystem == nil or UGCGameSystem.GetTimeSeconds == nil then
        return nil
    end
    local Success, TimeSeconds = pcall(
        UGCGameSystem.GetTimeSeconds, WorldContext)
    if Success then
        return tonumber(TimeSeconds)
    end
    return nil
end

local function GetActorLocation(Actor)
    if not IsValid(Actor) or Actor.K2_GetActorLocation == nil then
        return nil
    end
    local Success, Location = pcall(Actor.K2_GetActorLocation, Actor)
    if Success then
        return Location
    end
    return nil
end

local function GetActorYaw(Actor)
    if not IsValid(Actor) or Actor.K2_GetActorRotation == nil then
        return nil
    end
    local Success, Rotation = pcall(Actor.K2_GetActorRotation, Actor)
    if Success and Rotation ~= nil then
        return tonumber(Rotation.Yaw)
    end
    return nil
end

local function GetOwnerMesh(Owner)
    if not IsValid(Owner) then
        return nil
    end
    local Success, Mesh = pcall(function()
        return Owner.Mesh
    end)
    if Success and IsValid(Mesh) then
        return Mesh
    end
    return nil
end

local function GetComponentLocation(Component)
    if not IsValid(Component) or Component.K2_GetComponentLocation == nil then
        return nil
    end
    local Success, Location = pcall(
        Component.K2_GetComponentLocation, Component)
    if Success then
        return Location
    end
    return nil
end

local function GetComponentYaw(Component)
    if not IsValid(Component) or Component.K2_GetComponentRotation == nil then
        return nil
    end
    local Success, Rotation = pcall(
        Component.K2_GetComponentRotation, Component)
    if Success and Rotation ~= nil then
        return tonumber(Rotation.Yaw)
    end
    return nil
end

local function AttachToSmoothedMesh(Actor, Mesh)
    if not IsValid(Actor) or not IsValid(Mesh) or
        Actor.K2_AttachToComponent == nil or EAttachmentRule == nil or
        EAttachmentRule.KeepWorld == nil then
        return false
    end
    local Success, Result = pcall(
        Actor.K2_AttachToComponent,
        Actor,
        Mesh,
        "NAME_None",
        EAttachmentRule.KeepWorld,
        EAttachmentRule.KeepWorld,
        EAttachmentRule.KeepWorld,
        false
    )
    return Success and Result ~= false
end

-- Simulated Pawns receive stepped capsule transforms, while CharacterMovement
-- smooths their visible Mesh between network updates. Preserve the initial
-- capsule-to-mesh offset and then follow the smoothed Mesh world transform.
local function GetSmoothedOwnerTransform(Owner, State)
    local ActorLocation = GetActorLocation(Owner)
    local ActorYaw = GetActorYaw(Owner)
    if ActorLocation == nil or ActorYaw == nil then
        return nil, nil
    end

    local Mesh = GetOwnerMesh(Owner)
    local MeshLocation = GetComponentLocation(Mesh)
    local MeshYaw = GetComponentYaw(Mesh)
    if MeshLocation == nil or MeshYaw == nil then
        return ActorLocation, ActorYaw
    end

    if State.MeshOffset == nil then
        State.MeshOffset = Vector.New(
            ActorLocation.X - MeshLocation.X,
            ActorLocation.Y - MeshLocation.Y,
            ActorLocation.Z - MeshLocation.Z
        )
        State.MeshYawOffset = ActorYaw - MeshYaw
    end

    local SmoothedLocation = Vector.New(
        MeshLocation.X + State.MeshOffset.X,
        MeshLocation.Y + State.MeshOffset.Y,
        MeshLocation.Z + State.MeshOffset.Z
    )
    return SmoothedLocation, MeshYaw + (State.MeshYawOffset or 0)
end

local function RemoveTimer(TimerName)
    if UGCTimerUtility ~= nil and
        UGCTimerUtility.RemoveLuaTimerByName ~= nil then
        pcall(UGCTimerUtility.RemoveLuaTimerByName, TimerName)
    end
end

-- The server owns the only gameplay Actor and still performs all collision/damage
-- updates. Remote clients only overwrite its visual transform every rendered tick,
-- avoiding the stepping caused by replicated-movement snapshots.
function OrbitWeaponFollower.Start(Actor)
    if not IsValid(Actor) or IsAuthority(Actor) then
        return false
    end
    if UGCTimerUtility == nil or UGCTimerUtility.CreateLuaTimer == nil then
        return false
    end

    local TimerName = "OrbitWeaponFollower_" .. tostring(Actor)
    RemoveTimer(TimerName)

    local State = {
        Angle = nil,
        LastTime = nil,
        MeshOffset = nil,
        MeshYawOffset = nil,
        AttachedMesh = nil,
    }

    UGCTimerUtility.CreateLuaTimer(0, function()
        if not IsValid(Actor) then
            RemoveTimer(TimerName)
            return
        end

        local Owner = GetOwner(Actor)
        local OwnerLocation, OwnerYaw = GetSmoothedOwnerTransform(Owner, State)
        if OwnerLocation == nil or OwnerYaw == nil then
            return
        end

        local CurrentTime = GetGameTimeSeconds(Actor)
        if State.Angle == nil then
            local ActorYaw = GetActorYaw(Actor) or OwnerYaw
            State.Angle = (ActorYaw - OwnerYaw) % 360
            State.LastTime = CurrentTime
        elseif CurrentTime ~= nil and State.LastTime ~= nil then
            local DeltaTime = math.max(0,
                math.min(MAX_DELTA_TIME, CurrentTime - State.LastTime))
            local RotationSpeed = math.max(0,
                tonumber(Actor.OrbitRotationSpeed) or DEFAULT_ROTATION_SPEED)
            State.Angle = (State.Angle - RotationSpeed * DeltaTime) % 360
            State.LastTime = CurrentTime
        elseif CurrentTime ~= nil then
            State.LastTime = CurrentTime
        end

        local NewLocation = Vector.New(
            OwnerLocation.X,
            OwnerLocation.Y,
            OwnerLocation.Z + HEIGHT_OFFSET
        )

        local OwnerMesh = GetOwnerMesh(Owner)
        if State.AttachedMesh ~= OwnerMesh then
            -- Align once in world space, then make the weapon a child of the
            -- already-smoothed character Mesh. This removes the extra follower
            -- tick which otherwise looks like the weapon is chasing the player.
            if Actor.K2_SetActorLocation ~= nil then
                pcall(Actor.K2_SetActorLocation,
                    Actor, NewLocation, false, nil, true)
            end
            if AttachToSmoothedMesh(Actor, OwnerMesh) then
                State.AttachedMesh = OwnerMesh
            end
        elseif State.AttachedMesh == nil and Actor.K2_SetActorLocation ~= nil then
            pcall(Actor.K2_SetActorLocation, Actor, NewLocation, false, nil, true)
        end

        if State.AttachedMesh ~= nil and
            Actor.K2_SetActorRelativeRotation ~= nil then
            -- Parent Mesh supplies the smoothed player rotation in the same
            -- component update; Lua only advances the orbit's relative angle.
            local NewRelativeRotation = Rotator.New(
                0, (State.MeshYawOffset or 0) + State.Angle, 0)
            pcall(Actor.K2_SetActorRelativeRotation,
                Actor, NewRelativeRotation, false, nil, true)
        elseif Actor.K2_SetActorRotation ~= nil then
            local NewRotation = Rotator.New(0, OwnerYaw + State.Angle, 0)
            pcall(Actor.K2_SetActorRotation, Actor, NewRotation, false)
        end
    end, true, TimerName)
    return true
end

return OrbitWeaponFollower
