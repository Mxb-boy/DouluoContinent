---@class WQ_C:AActor
---@field Box7 UBoxComponent
---@field Box6 UBoxComponent
---@field Box5 UBoxComponent
---@field Box4 UBoxComponent
---@field Box3 UBoxComponent
---@field Box2 UBoxComponent
---@field Box1 UBoxComponent
---@field ParticleSystem7 UParticleSystemComponent
---@field Box UBoxComponent
---@field ParticleSystem6 UParticleSystemComponent
---@field ParticleSystem5 UParticleSystemComponent
---@field ParticleSystem3 UParticleSystemComponent
---@field ParticleSystem1 UParticleSystemComponent
---@field ParticleSystem4 UParticleSystemComponent
---@field ParticleSystem2 UParticleSystemComponent
---@field ParticleSystem UParticleSystemComponent
---@field StaticMesh15 UStaticMeshComponent
---@field StaticMesh_8 UStaticMeshComponent
---@field StaticMesh13 UStaticMeshComponent
---@field StaticMesh_7 UStaticMeshComponent
---@field StaticMesh11 UStaticMeshComponent
---@field StaticMesh_6 UStaticMeshComponent
---@field StaticMesh9 UStaticMeshComponent
---@field StaticMesh_5 UStaticMeshComponent
---@field StaticMesh7 UStaticMeshComponent
---@field StaticMesh_4 UStaticMeshComponent
---@field StaticMesh5 UStaticMeshComponent
---@field StaticMesh_3 UStaticMeshComponent
---@field StaticMesh3 UStaticMeshComponent
---@field StaticMesh_2 UStaticMeshComponent
---@field StaticMesh1 UStaticMeshComponent
---@field StaticMesh_1 UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local WQ = {}
local DamageSync = UGCGameSystem.UGCRequire('Script.Common.DamageSync')
local DAMAGE_BOX_NAMES = { "Box", "Box1", "Box2", "Box3", "Box4", "Box5", "Box6", "Box7" }

local function GetComponentByName(self, componentName)
    local success, component = pcall(function()
        return self[componentName]
    end)
    if success then
        return component
    end
    return nil
end

function WQ:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    if self.DamageBoxesBound then
        return
    end

    self.DamageBoxesBound = true
    for _, boxName in ipairs(DAMAGE_BOX_NAMES) do
        local box = GetComponentByName(self, boxName)
        if box ~= nil and box.OnComponentBeginOverlap ~= nil then
            box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self)
        end
    end
end

-- Public API: 50 and 0.5 both mean 50% of AttackPower.
function WQ:SetDamagePercent(percent)
    self.DamagePercent = DamageSync.SetAttackPercentDamageSource(self, percent)
    return self.DamagePercent
end

function WQ:GetDamagePercent()
    return DamageSync.NormalizeDamagePercent(self.DamagePercent)
end

local function GetDamageInstigator(self)
    if self == nil then
        return nil
    end

    local ownerPawn = self.DamageOwnerPawn
    if ownerPawn ~= nil and UGCGameSystem.GetPlayerControllerByPlayerPawn ~= nil then
        local success, controller = pcall(UGCGameSystem.GetPlayerControllerByPlayerPawn, ownerPawn)
        if success and controller ~= nil then
            return controller
        end
    end

    if self.GetInstigatorController ~= nil then
        local success, controller = pcall(self.GetInstigatorController, self)
        if success and controller ~= nil then
            return controller
        end
    end

    if self.GetUltimateController ~= nil then
        local success, controller = pcall(self.GetUltimateController, self)
        if success and controller ~= nil then
            return controller
        end
    end

    local owner = nil
    if self.GetOwner ~= nil then
        local success, result = pcall(self.GetOwner, self)
        if success then
            owner = result
        end
    end

    if owner ~= nil and owner.PlayerKey ~= nil then
        return owner
    end

    if owner ~= nil and UGCGameSystem.GetPlayerControllerByPlayerPawn ~= nil then
        local success, controller = pcall(UGCGameSystem.GetPlayerControllerByPlayerPawn, owner)
        if success and controller ~= nil then
            return controller
        end
    end

    if owner ~= nil and owner.GetPlayerControllerSafety ~= nil then
        local success, controller = pcall(owner.GetPlayerControllerSafety, owner)
        if success then
            return controller
        end
    end

    return nil
end

-- [Editor Generated Lua] function define Begin:
function WQ:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    self.HitActors = self.HitActors or {}
    self:SetDamagePercent(self.DamagePercent or 100)
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:
    -- [Editor Generated Lua] BindingEvent End;
end

function WQ:TryDamageMonster(DamageBox, OtherActor)
    if not self:HasAuthority() then
        return nil;
    end

    if OtherActor == nil then
        return nil;
    end

    local isPlayer = false
    if UGCGameSystem.GetPlayerControllerByPlayerPawn ~= nil then
        local success, controller = pcall(UGCGameSystem.GetPlayerControllerByPlayerPawn, OtherActor)
        isPlayer = success and controller ~= nil
    end
    if isPlayer then
        return nil;
    end

    self.HitActors = self.HitActors or {}
    self.HitActors[DamageBox] = self.HitActors[DamageBox] or {}
    if self.HitActors[DamageBox][OtherActor] then
        return nil;
    end

    -- Each Box can hit each monster once. Persistent overlap from the orbit movement
    -- will not repeat damage from the same Box.
    self.HitActors[DamageBox][OtherActor] = true

    local instigatorController = GetDamageInstigator(self)
    local damage = DamageSync.GetAttackPercentDamage(instigatorController, self, self:GetDamagePercent())
    if instigatorController == nil or damage == nil or damage <= 0 then
        return nil;
    end

    -- ApplyDamage is a native server API and must be called directly.
    -- Wrapping it in pcall causes a server-side native crash.
    UGCGameSystem.ApplyDamage(OtherActor, damage, instigatorController, self, {})
    UnrealNetwork.CallUnrealRPC(instigatorController, instigatorController, "Client_PlayWQHitEffect", OtherActor)

    return nil;
end

function WQ:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    return self:TryDamageMonster(OverlappedComponent, OtherActor)
end

-- [Editor Generated Lua] function define End;

return WQ
