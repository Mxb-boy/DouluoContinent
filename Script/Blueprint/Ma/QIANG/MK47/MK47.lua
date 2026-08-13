---@class MK47_C:AActor
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
---@field qe UStaticMeshComponent
---@field StaticMesh_5 UStaticMeshComponent
---@field aa UStaticMeshComponent
---@field StaticMesh_4 UStaticMeshComponent
---@field StaticMesh55 UStaticMeshComponent
---@field StaticMesh_3 UStaticMeshComponent
---@field StaticMesh33 UStaticMeshComponent
---@field StaticMesh_2 UStaticMeshComponent
---@field StaticMesh111 UStaticMeshComponent
---@field StaticMesh_1 UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local MK47 = {}
local DamageSync = UGCGameSystem.UGCRequire('Script.Common.DamageSync')
local DamageOnlyCollision = UGCGameSystem.UGCRequire('Script.Common.DamageOnlyCollision')
local HIT_EFFECT_PATH = "Asset/Blueprint/Ma/QIANG/MK47/AK47_LZ.AK47_LZ"
local DAMAGE_BOX_NAMES = { "Box", "Box1", "Box2", "Box3", "Box4", "Box5", "Box6", "Box7" }
local GUN_MESH_NAMES = {
    "StaticMesh_1",
    "StaticMesh_2",
    "StaticMesh_3",
    "StaticMesh_4",
    "StaticMesh_5",
    "StaticMesh_6",
    "StaticMesh_7",
    "StaticMesh_8",
}

local function GetComponentByName(self, componentName)
    local success, component = pcall(function()
        return self[componentName]
    end)
    if success then
        return component
    end
    return nil
end

local function SetComponentTreeActive(RootComponent, bActive)
    if RootComponent == nil then
        return
    end

    -- 第二个参数为true：父组件的显隐递归传递给全部子组件。
    RootComponent:SetVisibility(bActive, true)
    RootComponent:SetActive(bActive, true)

    -- SetActive本身不向下传播，因此显式切换全部后代组件。
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
        if ChildComponent ~= nil and ChildComponent.SetActive ~= nil then
            ChildComponent:SetActive(bActive, true)
        end
    end
end

function MK47:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)
    DamageOnlyCollision.Apply(self, GUN_MESH_NAMES, DAMAGE_BOX_NAMES, GetComponentByName)

    -- 临时模拟外部传入12345：激活第1、2、3、4、5把枪。
    if not self.GunDisplayInitialized then
        self.GunDisplayInitialized = true
        self:SetActiveGuns(12345678)
    end

    if self.DamageBoxesBound then
        return
    end

    self.DamageBoxesBound = true
    for _, boxName in ipairs(DAMAGE_BOX_NAMES) do
        local box = GetComponentByName(self, boxName)
        if box ~= nil and box.OnComponentBeginOverlap ~= nil then
            box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self)
        end
        if box ~= nil and box.OnComponentEndOverlap ~= nil then
            box.OnComponentEndOverlap:Add(self.Box_OnComponentEndOverlap, self)
        end
    end
end

-- 把外部传入的组合编码解析为需要激活的枪编号。
local function ParseActiveGuns(GunCode)
    local ActiveGuns = {}
    local CodeText = tostring(GunCode or "")

    -- 每一位数字代表一把枪；只接受1~8，重复数字自动忽略。
    for Digit in string.gmatch(CodeText, "%d") do
        local GunIndex = tonumber(Digit)
        if GunIndex ~= nil and GunIndex >= 1 and GunIndex <= #GUN_MESH_NAMES then
            ActiveGuns[GunIndex] = true
        end
    end

    return ActiveGuns
end

-- 对外接口：123激活1、2、3；126激活1、2、6；0全部隐藏。
function MK47:SetActiveGuns(GunCode)
    self.ActiveGuns = ParseActiveGuns(GunCode)
    self.ActiveGunCode = GunCode

    for Index, MeshName in ipairs(GUN_MESH_NAMES) do
        local Mesh = GetComponentByName(self, MeshName)
        if Mesh ~= nil then
            DamageOnlyCollision.SetComponentTreeActive(Mesh, self.ActiveGuns[Index] == true)
        end
    end

    DamageOnlyCollision.RefreshActiveBoxes(self, self.ActiveGuns, DAMAGE_BOX_NAMES, GetComponentByName)

    return self.ActiveGuns
end


-- 保留原调用名，旧代码调用ActivateGun(126)也支持组合激活。
function MK47:SetActiveGun(GunCode)
    return self:SetActiveGuns(GunCode)
end

function MK47:ActivateGun(GunCode)
    return self:SetActiveGuns(GunCode)
end

function MK47:ActivateGuns(GunCode)
    return self:SetActiveGuns(GunCode)
end

function MK47:GetActiveGuns()
    return self.ActiveGuns or {}
end

local function IsDamageBoxActive(self, DamageBox)
    local ActiveGuns = self.ActiveGuns or {}
    for GunIndex, BoxName in ipairs(DAMAGE_BOX_NAMES) do
        if ActiveGuns[GunIndex] and DamageBox == GetComponentByName(self, BoxName) then
            return true
        end
    end

    return false
end

-- Public API: 50 and 0.5 both mean 50% of AttackPower.
function MK47:SetDamagePercent(percent)
    self.DamagePercent = DamageSync.SetAttackPercentDamageSource(self, percent)
    return self.DamagePercent
end

function MK47:GetDamagePercent()
    return DamageSync.NormalizeDamagePercent(self.DamagePercent)
end

function MK47:GetHitEffectPath()
    return self.HitEffectPath or HIT_EFFECT_PATH
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
function MK47:LuaInit()
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

function MK47:TryDamageMonster(DamageBox, OtherActor)
    if not self:HasAuthority() then
        return nil;
    end

    -- 隐藏/未激活枪的碰撞盒不再造成伤害。
    if not IsDamageBoxActive(self, DamageBox) then
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
    UnrealNetwork.CallUnrealRPC(instigatorController, instigatorController, "Client_PlayWQHitEffect", OtherActor,
        self:GetHitEffectPath())

    return nil;
end

function MK47:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    return self:TryDamageMonster(OverlappedComponent, OtherActor)
end

function MK47:Box_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor ~= nil and self.HitActors ~= nil and self.HitActors[OverlappedComponent] ~= nil then
        self.HitActors[OverlappedComponent][OtherActor] = nil
    end
    return nil
end

-- [Editor Generated Lua] function define End;

return MK47
