-- WQ 蓝图生成与旋转。
-- WQ.WQ_C 内部已经摆好了 8 把枪，因此这里只生成一个蓝图 Actor。

local AK47Orbit = {}

-- 武器环绕总开关。
AK47Orbit.FEATURE_ENABLED = true

function AK47Orbit.IsFeatureEnabled()
    return AK47Orbit.FEATURE_ENABLED == true
end

-- 蓝图资源路径。
local WQ_CLASS_PATH = "Asset/Blueprint/Ma/QIANG/QBZ/QBZ.QBZ_C"

-- 每秒旋转角度，数值越大转得越快。
local ROTATION_SPEED = 50

-- 相对人物 ActorLocation 的高度偏移；0 大约是人物腰部。
local HEIGHT_OFFSET = 0

-- 蓝图整体缩放。
local ACTOR_SCALE = Vector.New(1, 1, 1)

-- 蓝图刚进入游戏时可能尚未加载完成，最多重试 20 次。
local MAX_RETRY_COUNT = 20
local RETRY_INTERVAL = 0.25


-- 判断 UObject/Actor 当前是否有效。
local function IsValid(Object)
    return Object ~= nil and (UE == nil or UE.IsValid == nil or UE.IsValid(Object))
end

-- 解锁到第N档时累计显示第1到第N把武器：3档对应组合编码123。
local function BuildActiveGunCode(UnlockedTier)
    UnlockedTier = math.max(0, math.min(8, math.floor(tonumber(UnlockedTier) or 0)))
    local CodeText = ""
    for Index = 1, UnlockedTier do
        CodeText = CodeText .. tostring(Index)
    end
    return tonumber(CodeText) or 0
end

-- 输出本脚本专用日志，方便定位资源加载或生成问题。
local function Log(Message)
    if ugcprint ~= nil then
        ugcprint("[WQOrbit] " .. tostring(Message))
    end
end

-- 每个人物使用不同的重试计时器名称，避免互相覆盖。
local function GetRetryTimerName(Pawn)
    return "WQOrbitRetry_" .. tostring(Pawn)
end

-- 加载指定的旋转武器蓝图类。
local function LoadWQClassByPath(ClassPath)
    local FullPath = ClassPath
    if type(ClassPath) ~= "string" or ClassPath == "" then
        ClassPath = WQ_CLASS_PATH
        FullPath = ClassPath
    end
    if string.sub(ClassPath, 1, 1) ~= "/" then
        if UGCGameSystem == nil or UGCGameSystem.GetUGCResourcesFullPath == nil then
            return nil
        end
        local OkPath, ResolvedPath = pcall(UGCGameSystem.GetUGCResourcesFullPath, ClassPath)
        if not OkPath or ResolvedPath == nil then
            return nil
        end
        FullPath = ResolvedPath
    end

    if UGCObjectUtility ~= nil and UGCObjectUtility.LoadClass ~= nil then
        local OkClass, Class = pcall(UGCObjectUtility.LoadClass, FullPath)
        if OkClass and Class ~= nil then
            return Class
        end
    end

    -- 兼容部分环境没有 UGCObjectUtility.LoadClass 的情况。
    if UE ~= nil and UE.LoadClass ~= nil then
        local OkClass, Class = pcall(UE.LoadClass, FullPath)
        if OkClass then
            return Class
        end
    end
    return nil
end

local function LoadWQClass(Pawn)
    return LoadWQClassByPath(Pawn ~= nil and Pawn.OrbitWeaponClassPath or WQ_CLASS_PATH)
end

-- 读取人物当前位置。
local function GetPawnLocation(Pawn)
    if IsValid(Pawn) and Pawn.K2_GetActorLocation ~= nil then
        local Ok, Location = pcall(Pawn.K2_GetActorLocation, Pawn)
        if Ok then
            return Location
        end
    end
    return nil
end

-- 读取人物当前水平朝向。
local function GetPawnYaw(Pawn)
    if IsValid(Pawn) and Pawn.K2_GetActorRotation ~= nil then
        local Ok, Rotation = pcall(Pawn.K2_GetActorRotation, Pawn)
        if Ok and Rotation ~= nil then
            return tonumber(Rotation.Yaw) or 0
        end
    end
    return 0
end

-- 蓝图类暂时加载不到时，延迟后重新尝试生成。
local function ScheduleRetry(Pawn)
    if not AK47Orbit.IsFeatureEnabled() then
        return
    end
    if not IsValid(Pawn) then
        return
    end

    local RetryCount = tonumber(Pawn.AK47OrbitRetryCount) or 0
    if RetryCount >= MAX_RETRY_COUNT then
        Log("蓝图加载失败，已停止重试")
        return
    end
    Pawn.AK47OrbitRetryCount = RetryCount + 1

    if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
        local TimerName = GetRetryTimerName(Pawn)
        if UGCTimerUtility.RemoveLuaTimerByName ~= nil then
            pcall(UGCTimerUtility.RemoveLuaTimerByName, TimerName)
        end
        UGCTimerUtility.CreateLuaTimer(RETRY_INTERVAL, function()
            AK47Orbit.Start(Pawn)
        end, false, TimerName)
    end
end


-- 在人物腰部生成一个 WQ 蓝图 Actor。
function AK47Orbit.Start(Pawn, PreloadedClass)
    if not AK47Orbit.IsFeatureEnabled() then
        if Pawn ~= nil then
            AK47Orbit.Stop(Pawn)
        end
        return false
    end
    if not IsValid(Pawn) then
        return false
    end

    -- 已经生成过时不再重复生成。
    if Pawn.AK47OrbitState ~= nil then
        return
    end

    local WQClass = PreloadedClass or LoadWQClass(Pawn)
    local PawnLocation = GetPawnLocation(Pawn)
    if WQClass == nil or PawnLocation == nil then
        ScheduleRetry(Pawn)
        return
    end

    local SpawnLocation = Vector.New(
        PawnLocation.X,
        PawnLocation.Y,
        PawnLocation.Z + HEIGHT_OFFSET
    )
    local SpawnRotation = Rotator.New(0, GetPawnYaw(Pawn), 0)

    local OkSpawn, Actor = pcall(
        UGCActorComponentUtility.SpawnActor,
        Pawn,
        WQClass,
        SpawnLocation,
        SpawnRotation,
        ACTOR_SCALE,
        Pawn
    )
    if not OkSpawn or not IsValid(Actor) then
        Log("蓝图生成失败")
        ScheduleRetry(Pawn)
        return
    end

    -- 环绕枪只做展示，关闭碰撞并取消自动销毁。
    Actor.DamageOwnerPawn = Pawn
    Actor.HitEffectPath = Pawn.OrbitWeaponHitEffectPath
    if Actor.SetActiveGuns ~= nil then
        local ActiveGunCode = tonumber(Pawn.OrbitWeaponActiveGunIndex)
        if ActiveGunCode == nil then
            local PlayerLevel = Pawn.PlayerState ~= nil and Pawn.PlayerState.GetPlayerLevel ~= nil and
                tonumber(Pawn.PlayerState:GetPlayerLevel()) or 1
            ActiveGunCode = BuildActiveGunCode(PlayerLevel)
            Pawn.OrbitWeaponActiveGunIndex = ActiveGunCode
        end
        Actor:SetActiveGuns(ActiveGunCode)
    end
    if Actor.SetDamagePercent ~= nil and Pawn.OrbitWeaponDamagePercent ~= nil then
        Actor:SetDamagePercent(Pawn.OrbitWeaponDamagePercent)
    end
    if Actor.SetActorEnableCollision ~= nil then
        pcall(Actor.SetActorEnableCollision, Actor, true)
    end
    if Actor.SetLifeSpan ~= nil then
        pcall(Actor.SetLifeSpan, Actor, 0)
    end

    Pawn.AK47OrbitRetryCount = 0
    Pawn.AK47OrbitState = {
        Actor = Actor,
        Angle = 0,
        WeaponClassPath = Pawn.OrbitWeaponClassPath or WQ_CLASS_PATH,
    }
    Log("蓝图生成成功")
    return true
end

-- 切换旋转武器蓝图和命中特效；已开启时立即重建，关闭时仅记录配置。
function AK47Orbit.SetWeapon(Pawn, WeaponClassPath, HitEffectPath)
    if not IsValid(Pawn) then
        return false
    end

    local NewWeaponClass = LoadWQClassByPath(WeaponClassPath)
    if NewWeaponClass == nil then
        Log("切换失败，LT 不是可加载的蓝图类: " .. tostring(WeaponClassPath))
        return false
    end

    local OldWeaponClassPath = Pawn.OrbitWeaponClassPath
    local OldHitEffectPath = Pawn.OrbitWeaponHitEffectPath
    Pawn.OrbitWeaponClassPath = WeaponClassPath
    Pawn.OrbitWeaponHitEffectPath = HitEffectPath
    if not AK47Orbit.IsFeatureEnabled() then
        Pawn.bOrbitWeaponEnabled = false
        AK47Orbit.Stop(Pawn)
        return true
    end
    -- 重生同步期间开关字段可能短暂为nil/false，但已有Actor仍在显示。
    -- 只要旋转武器未被明确关闭，或当前Actor仍存在，换枪就必须立即重建。
    local bHasVisibleOrbitActor = Pawn.AK47OrbitState ~= nil and
        IsValid(Pawn.AK47OrbitState.Actor)
    local bShouldRebuild = Pawn.bOrbitWeaponEnabled ~= false or bHasVisibleOrbitActor
    if bShouldRebuild then
        Pawn.bOrbitWeaponEnabled = true
        AK47Orbit.Stop(Pawn)
        AK47Orbit.Start(Pawn, NewWeaponClass)
        if Pawn.AK47OrbitState == nil then
            Pawn.OrbitWeaponClassPath = OldWeaponClassPath
            Pawn.OrbitWeaponHitEffectPath = OldHitEffectPath
            AK47Orbit.Stop(Pawn)
            AK47Orbit.Start(Pawn)
            Log("新武器生成失败，已恢复原旋转武器")
            return false
        end
    end
    return true
end

function AK47Orbit.SetActiveGun(Pawn, GunIndex, DamagePercent)
    GunIndex = math.floor(tonumber(GunIndex) or 0)
    if not IsValid(Pawn) or GunIndex < 1 or GunIndex > 8 then
        return false
    end
    local ActiveGunCode = BuildActiveGunCode(GunIndex)
    Pawn.OrbitWeaponActiveGunIndex = ActiveGunCode
    DamagePercent = tonumber(DamagePercent)
    if DamagePercent ~= nil and DamagePercent > 0 then
        Pawn.OrbitWeaponDamagePercent = DamagePercent
    end
    local State = Pawn.AK47OrbitState
    if State ~= nil and IsValid(State.Actor) and State.Actor.SetActiveGuns ~= nil then
        State.Actor:SetActiveGuns(ActiveGunCode)
        if State.Actor.SetDamagePercent ~= nil and Pawn.OrbitWeaponDamagePercent ~= nil then
            State.Actor:SetDamagePercent(Pawn.OrbitWeaponDamagePercent)
        end
    end
    return true
end


-- 由人物 ReceiveTick 每帧调用，使蓝图平滑跟随并水平旋转。
function AK47Orbit.Update(Pawn, DeltaTime)
    if not IsValid(Pawn) then
        return
    end
    if not AK47Orbit.IsFeatureEnabled() then
        AK47Orbit.Stop(Pawn)
        return
    end

    local State = Pawn.AK47OrbitState
    if State == nil or not IsValid(State.Actor) then
        return
    end

    local PawnLocation = GetPawnLocation(Pawn)
    if PawnLocation == nil then
        return
    end

    -- 使用真实帧间隔计算角度，帧率变化时旋转速度仍然一致。
    local SafeDeltaTime = tonumber(DeltaTime) or 0
    State.Angle = (State.Angle - ROTATION_SPEED * SafeDeltaTime) % 360

    -- 每帧同步到人物腰部位置，消除旧计时器低频更新造成的顿挫。
    local NewLocation = Vector.New(
        PawnLocation.X,
        PawnLocation.Y,
        PawnLocation.Z + HEIGHT_OFFSET
    )
    if State.Actor.K2_SetActorLocation ~= nil then
        pcall(State.Actor.K2_SetActorLocation, State.Actor, NewLocation, true, nil, true)
    end

    -- 只改变 Yaw，让整个 WQ 蓝图沿水平方向转圈。
    local NewRotation = Rotator.New(0, GetPawnYaw(Pawn) + State.Angle, 0)
    if State.Actor.K2_SetActorRotation ~= nil then
        pcall(State.Actor.K2_SetActorRotation, State.Actor, NewRotation, false)
    end
end


-- 人物离场时销毁生成的蓝图并清理重试计时器。
function AK47Orbit.Stop(Pawn)
    if Pawn == nil then
        return
    end

    if UGCTimerUtility ~= nil and UGCTimerUtility.RemoveLuaTimerByName ~= nil then
        pcall(UGCTimerUtility.RemoveLuaTimerByName, GetRetryTimerName(Pawn))
    end

    local State = Pawn.AK47OrbitState
    Pawn.AK47OrbitState = nil
    Pawn.AK47OrbitRetryCount = 0

    if State ~= nil and IsValid(State.Actor) then
        local Actor = State.Actor

        -- 优先使用 Actor 自身的销毁接口，确保本地生成的 WQ 也能立即消失。
        if Actor.K2_DestroyActor ~= nil then
            pcall(Actor.K2_DestroyActor, Actor)
        end

        -- 部分运行环境不开放 K2_DestroyActor，使用 UGC 接口作为兜底。
        if IsValid(Actor) and UGCActorComponentUtility ~= nil and
            UGCActorComponentUtility.DestroyActor ~= nil then
            pcall(UGCActorComponentUtility.DestroyActor, Actor)
        end
    end
end

return AK47Orbit
