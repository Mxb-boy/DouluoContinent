MonsterSpawnMgr = MonsterSpawnMgr or {}

MonsterSpawnMgr.ClassCache = MonsterSpawnMgr.ClassCache or {}
MonsterSpawnMgr.LevelPointCache = MonsterSpawnMgr.LevelPointCache or {}

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
        if point
            and point.Scene == Scene
            and point.BigLevel == BigLevel
            and point.LittleLevel == LittleLevel
        then
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

function MonsterSpawnMgr.SpawnMonsters(
    WorldContext,
    MonsterPath,
    Location,
    Rotation,
    Count,
    Owner
)
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

        local spawnLocation = Vector.New(
            Location.X + (column - 1) * spacing,
            Location.Y + row * spacing,
            Location.Z
        )

        local monster = UGCActorComponentUtility.SpawnActor(
            WorldContext,
            MonsterClass,
            spawnLocation,
            Rotation,
            Vector.New(1, 1, 1),
            Owner
        )

        if monster then
            table.insert(spawnedMonsters, monster)
        end
    end

    return spawnedMonsters
end

function MonsterSpawnMgr.SpawnAtLevelPoints(
    WorldContext,
    Scene,
    BigLevel,
    LittleLevel,
    Owner
)
    local sceneName = "MainScene"
    local monsterClass = MonsterSpawnMgr.GetCachedClass(MonsterSpawnMgr.PatchPath(sceneName, BigLevel, LittleLevel))
    if monsterClass == nil then
        return {}
    end

    local matchedPoints = MonsterSpawnMgr.GetCachedLevelPoints(WorldContext, Scene, BigLevel, LittleLevel)

    local monsters = {}
    for _, point in ipairs(matchedPoints or {}) do
        local monster = UGCActorComponentUtility.SpawnActor(
            WorldContext,
            monsterClass,
            point:K2_GetActorLocation(),
            point:K2_GetActorRotation(),
            Vector.New(1, 1, 1),
            Owner
        )

        if monster then
            table.insert(monsters, monster)
        end
    end

    return monsters
end

function MonsterSpawnMgr.PatchPath(Scene, BigLevel, LittleLevel)
    return string.format(
        "%sAsset/Blueprint/Prefabs/Monsters/%s/BigLevel_%02d/LittleLevel_%02d/BaseMons.BaseMons_C",
        UGCMapInfoLib.GetRootLongPackagePath(),
        Scene,
        BigLevel,
        LittleLevel
    )
end

return MonsterSpawnMgr
