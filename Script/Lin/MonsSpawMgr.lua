MonsterSpawnMgr = MonsterSpawnMgr or {}

MonsterSpawnMgr.ClassCache = MonsterSpawnMgr.ClassCache or {}
MonsterSpawnMgr.LevelPointCache = MonsterSpawnMgr.LevelPointCache or {}

local First_Hit_Run_Away_Time = 2 -- 首次受击乱跑时间
local First_Hit_Run_Away_Distance = 900 -- 首次受击随机移动距离
local First_Hit_Run_Away_Stop_Radius = 80 -- 首次受击移动停止距离
local First_Hit_Run_Away_Reason = "FirstHitRunAway" -- 首次受击暂停行为树原因
local First_Hit_Run_Away_Speed_Scale = 2.5 -- 首次受击随机移动速度倍率
local First_Hit_Run_Away_Speed_Reason = 1001 -- 首次受击移动速度修改原因

--[[----------------------禁用怪物碰撞------------------------]]
function MonsterSpawnMgr.DisableMonsterCollision(monster)
    if monster.HitBox ~= nil then
        monster.HitBox:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end

    if monster.StaticMesh ~= nil then
        monster.StaticMesh:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    end
end

--[[----------------------获取伤害来源玩家------------------------]]
function MonsterSpawnMgr.GetInstigatorPawn(EventInstigator)
    if EventInstigator == nil then
        return nil
    end

    return UGCGameSystem.GetPlayerPawnByPlayerController(EventInstigator) or EventInstigator
end

--[[----------------------设置怪物追击目标------------------------]]
function MonsterSpawnMgr.SetMonsterTarget(monster, TargetPawn)
    local Blackboard = UGCGenericCharacterSystem.GetBlackboard(monster)
    if Blackboard ~= nil then
        Blackboard:SetValueAsObject("Target", TargetPawn)
    end
end

--[[----------------------恢复首次受击后的追击------------------------]]
function MonsterSpawnMgr.ResumeFirstHitBehavior(monster, TargetPawn, OldSpeed, SpeedReason, BehaviorReason)
    if UGCGenericCharacterSystem.IsAlive(monster) then
        UGCGenericCharacterSystem.StopMove(monster)
        UGCGenericCharacterSystem.SetMaxSpeed(monster, OldSpeed, SpeedReason)
        MonsterSpawnMgr.SetMonsterTarget(monster, TargetPawn)
        UGCGenericCharacterSystem.ResumeBehavior(monster, BehaviorReason)
    end
end

--[[----------------------首次受击随机移动后追击攻击者------------------------]]
function MonsterSpawnMgr.FirstHitRunAway(monster, EventInstigator, RunAwayTime, RunAwayDistance, StopRadius,
    BehaviorReason, SpeedScale, SpeedReason)
    RunAwayTime = RunAwayTime or First_Hit_Run_Away_Time
    RunAwayDistance = RunAwayDistance or First_Hit_Run_Away_Distance
    StopRadius = StopRadius or First_Hit_Run_Away_Stop_Radius
    BehaviorReason = BehaviorReason or First_Hit_Run_Away_Reason
    SpeedScale = SpeedScale or First_Hit_Run_Away_Speed_Scale
    SpeedReason = SpeedReason or First_Hit_Run_Away_Speed_Reason

    if monster.FirstHitRunAwayDone then
        return
    end

    if not monster:HasAuthority() then
        return
    end

    local TargetPawn = MonsterSpawnMgr.GetInstigatorPawn(EventInstigator)
    if TargetPawn == nil then
        return
    end

    local SelfLoc = monster:K2_GetActorLocation()
    local Angle = math.random() * 2 * math.pi
    local MoveLoc = Vector.New(SelfLoc.X + math.cos(Angle) * RunAwayDistance,
        SelfLoc.Y + math.sin(Angle) * RunAwayDistance, SelfLoc.Z)
    local OldSpeed = UGCGenericCharacterSystem.GetMaxSpeed(monster)

    monster.FirstHitRunAwayDone = true
    MonsterSpawnMgr.SetMonsterTarget(monster, TargetPawn)
    UGCGenericCharacterSystem.PauseBehavior(monster, BehaviorReason)
    UGCGenericCharacterSystem.SetMaxSpeed(monster, OldSpeed * SpeedScale, SpeedReason)
    UGCGenericCharacterSystem.MoveTo(monster, MoveLoc, StopRadius)
    UGCTimerUtility.CreateLuaTimer(RunAwayTime, function()
        MonsterSpawnMgr.ResumeFirstHitBehavior(monster, TargetPawn, OldSpeed, SpeedReason, BehaviorReason)
    end)
end

function MonsterSpawnMgr.GetCachedClass(ClassPath)
    if ClassPath == nil or ClassPath == "" then
        return nil
    end

    if MonsterSpawnMgr.ClassCache[ClassPath] == nil then
        MonsterSpawnMgr.ClassCache[ClassPath] = UE.LoadClass(ClassPath)
    end

    return MonsterSpawnMgr.ClassCache[ClassPath]
end

function MonsterSpawnMgr.MakeLevelPointCacheKey(Scene, BigLevel, LittleLevel)
    return string.format("%s_%s_%s", tostring(Scene), tostring(BigLevel), tostring(LittleLevel))
end

function MonsterSpawnMgr.IsActorListValid(ActorList)
    if ActorList == nil or #ActorList <= 0 then
        return false
    end

    for _, actor in ipairs(ActorList) do
        if actor == nil or UE.IsValid(actor) == false then
            return false
        end
    end

    return true
end

function MonsterSpawnMgr.GetCachedLevelPoints(WorldContext, Scene, BigLevel, LittleLevel)
    local cacheKey = MonsterSpawnMgr.MakeLevelPointCacheKey(Scene, BigLevel, LittleLevel)
    local cachedPoints = MonsterSpawnMgr.LevelPointCache[cacheKey]

    if MonsterSpawnMgr.IsActorListValid(cachedPoints) then
        return cachedPoints
    end

    local spawnPointClass = MonsterSpawnMgr.GetCachedClass(PathMgr.MonsStartPoint_C)
    if spawnPointClass == nil then
        return {}
    end

    local allPoints = UGCActorComponentUtility.GetAllActorsOfClass(WorldContext, spawnPointClass)
    local matchedPoints = {}

    for _, point in ipairs(allPoints or {}) do
        if point and point.Scene == Scene and point.BigLevel == BigLevel and point.LittleLevel == LittleLevel then
            table.insert(matchedPoints, point)
        end
    end

    table.sort(matchedPoints, function(a, b)
        return (a.StartPoint or 0) < (b.StartPoint or 0)
    end)

    MonsterSpawnMgr.LevelPointCache[cacheKey] = matchedPoints
    return matchedPoints
end

function MonsterSpawnMgr.ClearCache()
    MonsterSpawnMgr.ClassCache = {}
    MonsterSpawnMgr.LevelPointCache = {}
end

function MonsterSpawnMgr.SpawnMonsters(WorldContext, MonsterPath, Location, Rotation, Count, Owner)
    local MonsterClass = MonsterSpawnMgr.GetCachedClass(MonsterPath)
    if MonsterClass == nil then
        return {}
    end

    Count = math.max(1, math.floor(Count or 1))
    Rotation = Rotation or Rotator.New(0, 0, 0)

    local spawnedMonsters = {}
    local spacing = 150

    for index = 1, Count do
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)

        local spawnLocation = Vector.New(Location.X + (column - 1) * spacing, Location.Y + row * spacing, Location.Z)

        local monster = UGCActorComponentUtility.SpawnActor(WorldContext, MonsterClass, spawnLocation, Rotation,
            Vector.New(1, 1, 1), Owner)

        if monster then
            table.insert(spawnedMonsters, monster)
        end
    end

    return spawnedMonsters
end

function MonsterSpawnMgr.SpawnAtLevelPoints(WorldContext, Scene, BigLevel, LittleLevel, Owner)
    local sceneName = "MainScene"
    local monsterClass = MonsterSpawnMgr.GetCachedClass(MonsterSpawnMgr.PatchPath(sceneName, BigLevel, LittleLevel))
    if monsterClass == nil then
        return {}
    end

    local matchedPoints = MonsterSpawnMgr.GetCachedLevelPoints(WorldContext, Scene, BigLevel, LittleLevel)

    local monsters = {}
    for _, point in ipairs(matchedPoints or {}) do
        local monster = MonsterSpawnMgr.SpawnAtPointWithClass(WorldContext, monsterClass, point, Owner)

        if monster then
            table.insert(monsters, monster)
        end
    end

    return monsters
end

function MonsterSpawnMgr.SpawnAtPointWithClass(WorldContext, MonsterClass, Point, Owner)
    if MonsterClass == nil or Point == nil or UE.IsValid(Point) == false then
        return nil
    end

    local monster = UGCActorComponentUtility.SpawnActor(WorldContext, MonsterClass, Point:K2_GetActorLocation(),
        Point:K2_GetActorRotation(), Vector.New(1, 1, 1), Owner)

    if monster then
        monster.SpawnPoint = Point
    end

    return monster
end

function MonsterSpawnMgr.SpawnAtPoint(WorldContext, Scene, BigLevel, LittleLevel, Point, Owner)
    local sceneName = "MainScene"
    local monsterClass = MonsterSpawnMgr.GetCachedClass(MonsterSpawnMgr.PatchPath(sceneName, BigLevel, LittleLevel))
    return MonsterSpawnMgr.SpawnAtPointWithClass(WorldContext, monsterClass, Point, Owner)
end

function MonsterSpawnMgr.PatchPath(Scene, BigLevel, LittleLevel)
    return string.format("%sAsset/Blueprint/Prefabs/Monsters/%s/BigLevel_%02d/LittleLevel_%02d/BaseMons.BaseMons_C",
        UGCMapInfoLib.GetRootLongPackagePath(), Scene, BigLevel, LittleLevel)
end

return MonsterSpawnMgr
