local DamageOnlyCollision = {}

local function CallIfExists(Object, FunctionName, ...)
    if Object ~= nil and Object[FunctionName] ~= nil then
        pcall(Object[FunctionName], Object, ...)
    end
end

local function SetNoCollision(Component)
    if Component == nil then
        return
    end

    CallIfExists(Component, "SetCollisionProfileName", "NoCollision")
    if ECollisionEnabled ~= nil and ECollisionEnabled.NoCollision ~= nil then
        CallIfExists(Component, "SetCollisionEnabled", ECollisionEnabled.NoCollision)
    end
    CallIfExists(Component, "SetGenerateOverlapEvents", false)
end

local function SetOverlapOnly(Component)
    if Component == nil then
        return
    end

    CallIfExists(Component, "SetCollisionProfileName", "OverlapAll")
    if ECollisionEnabled ~= nil and ECollisionEnabled.QueryOnly ~= nil then
        CallIfExists(Component, "SetCollisionEnabled", ECollisionEnabled.QueryOnly)
    end
    if ECollisionResponse ~= nil and ECollisionResponse.ECR_Overlap ~= nil then
        CallIfExists(Component, "SetCollisionResponseToAllChannels", ECollisionResponse.ECR_Overlap)
    end
    CallIfExists(Component, "SetGenerateOverlapEvents", true)
end

local function ForEachChildComponent(RootComponent, Callback)
    if RootComponent == nil then
        return
    end

    Callback(RootComponent)

    local Children = {}
    local Success, Result = pcall(
        RootComponent.GetChildrenComponents,
        RootComponent,
        true,
        Children
    )
    if Success and type(Result) == "table" then
        Children = Result
    end

    for _, ChildComponent in ipairs(Children) do
        Callback(ChildComponent)
    end
end

function DamageOnlyCollision.Apply(Actor, MeshNames, BoxNames, GetComponentByName)
    if Actor == nil or GetComponentByName == nil then
        return
    end

    -- Keep actor collision enabled so query-only Box overlap events can still fire.
    if Actor.SetActorEnableCollision ~= nil then
        pcall(Actor.SetActorEnableCollision, Actor, true)
    end

    for _, MeshName in ipairs(MeshNames or {}) do
        local MeshRoot = GetComponentByName(Actor, MeshName)
        ForEachChildComponent(MeshRoot, SetNoCollision)
    end

    for _, BoxName in ipairs(BoxNames or {}) do
        SetOverlapOnly(GetComponentByName(Actor, BoxName))
    end
end

return DamageOnlyCollision
