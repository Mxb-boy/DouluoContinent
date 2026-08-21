local DamageOnlyCollision = {}
local OrbitWeaponFollower = UGCGameSystem.UGCRequire(
    "Script.Common.OrbitWeaponFollower")

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

-- 显式处理根组件及其全部后代，避免粒子、附属网格等子组件继续显示。
function DamageOnlyCollision.SetComponentTreeActive(RootComponent, bActive)
    ForEachChildComponent(RootComponent, function(Component)
        if Component == nil then
            return
        end
        if Component.SetVisibility ~= nil then
            pcall(Component.SetVisibility, Component, bActive, true)
        end
        if Component.SetActive ~= nil then
            pcall(Component.SetActive, Component, bActive, true)
        end
    end)
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

    -- Replicated movement only provides discrete network snapshots. On remote
    -- clients, follow the replicated owner every local tick for smooth visuals.
    OrbitWeaponFollower.Start(Actor)
end

-- 武器显示切换时同步开关一一对应的伤害盒，防止隐藏武器的碰撞仍留在场景中。
function DamageOnlyCollision.RefreshActiveBoxes(Actor, ActiveGuns, BoxNames, GetComponentByName)
    if Actor == nil or GetComponentByName == nil then
        return
    end

    for Index, BoxName in ipairs(BoxNames or {}) do
        local BoxComponent = GetComponentByName(Actor, BoxName)
        local bActive = ActiveGuns ~= nil and ActiveGuns[Index] == true
        if bActive then
            SetOverlapOnly(BoxComponent)
        else
            SetNoCollision(BoxComponent)
        end
        CallIfExists(BoxComponent, "SetActive", bActive, true)
    end
end

-- 根据发生重叠的碰撞盒找到 num，并返回该把旋转武器自己的攻击百分比。
function DamageOnlyCollision.GetDamagePercentForBox(Actor, DamageBox, ActiveGuns,
    BoxNames, GetComponentByName, DefaultPercent)
    if Actor == nil or DamageBox == nil or GetComponentByName == nil then
        return DefaultPercent
    end
    for WeaponIndex, BoxName in ipairs(BoxNames or {}) do
        if (ActiveGuns == nil or ActiveGuns[WeaponIndex] == true) and
            DamageBox == GetComponentByName(Actor, BoxName) then
            local Percent = Actor.DamagePercentByGun ~= nil and
                tonumber(Actor.DamagePercentByGun[WeaponIndex] or
                    Actor.DamagePercentByGun[tostring(WeaponIndex)]) or nil
            Percent = Percent or tonumber(DefaultPercent)
            if Percent ~= nil and Percent > 0 then
                -- 全局伤害计算也读取这个字段，必须与本次碰撞盒的百分比保持一致。
                Actor.UseAttackPercentDamage = true
                Actor.AttackDamagePercent = Percent
                return Percent
            end
            return DefaultPercent
        end
    end
    return DefaultPercent
end

return DamageOnlyCollision
