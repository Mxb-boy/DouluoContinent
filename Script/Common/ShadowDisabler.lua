local ShadowDisabler = {}

local ACTOR_CLASS_PATH = "/Script/Engine.Actor"
local PRIMITIVE_COMPONENT_CLASS_PATH = "/Script/Engine.PrimitiveComponent"

local function DisableComponentShadow(Component)
    if Component == nil then
        return
    end

    if Component.SetCastShadow ~= nil then
        pcall(Component.SetCastShadow, Component, false)
    end
    if Component.SetReveiceShadow ~= nil then
        pcall(Component.SetReveiceShadow, Component, false)
    end
end

local function GetPrimitiveComponents(Actor, PrimitiveComponentClass)
    if UGCActorComponentUtility ~= nil and UGCActorComponentUtility.GetComponentsByClass ~= nil then
        local Success, Components = pcall(UGCActorComponentUtility.GetComponentsByClass, Actor, PrimitiveComponentClass)
        if Success and Components ~= nil then
            return Components
        end
    end
    if Actor.GetComponentsByClass ~= nil then
        local Success, Components = pcall(Actor.GetComponentsByClass, Actor, PrimitiveComponentClass)
        if Success and Components ~= nil then
            return Components
        end
    end
    return {}
end

function ShadowDisabler.Apply(WorldContext)
    if WorldContext == nil or UGCActorComponentUtility == nil or UGCActorComponentUtility.GetAllActorsOfClass == nil then
        return 0
    end

    local ActorClass = UE.LoadClass(ACTOR_CLASS_PATH)
    local PrimitiveComponentClass = UE.LoadClass(PRIMITIVE_COMPONENT_CLASS_PATH)
    if ActorClass == nil or PrimitiveComponentClass == nil then
        return 0
    end

    local Success, Actors = pcall(UGCActorComponentUtility.GetAllActorsOfClass, WorldContext, ActorClass)
    if not Success or Actors == nil then
        return 0
    end
    local ChangedCount = 0
    for _, Actor in ipairs(Actors) do
        local Components = GetPrimitiveComponents(Actor, PrimitiveComponentClass)
        for _, Component in ipairs(Components) do
            DisableComponentShadow(Component)
            ChangedCount = ChangedCount + 1
        end
    end
    return ChangedCount
end

function ShadowDisabler.Start(WorldContext)
    if WorldContext == nil or (WorldContext.HasAuthority ~= nil and WorldContext:HasAuthority()) then
        return
    end
    if ShadowDisabler.Started == true then
        return
    end
    ShadowDisabler.Started = true

    ShadowDisabler.Apply(WorldContext)
end

return ShadowDisabler
