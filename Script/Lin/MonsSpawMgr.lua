 MonsterSpawnMgr = {}

function MonsterSpawnMgr.SpawnMonsters(
    WorldContext,
    MonsterPath,
    Location,
    Rotation,
    Count,
    Owner
)
    local MonsterClass = UE.LoadClass(MonsterPath)
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

    local monsterClass = UE.LoadClass(MonsterSpawnMgr.PatchPath(sceneName, BigLevel, LittleLevel))
    local spawnPointClass = UE.LoadClass(PathMgr.MonsStartPoint_C)
    local allPoints = UGCActorComponentUtility.GetAllActorsOfClass(WorldContext,spawnPointClass)

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

    -- 按出生点编号排序，方便调试
    table.sort(matchedPoints, function(a, b)
        return (a.StartPoint or 0) < (b.StartPoint or 0)
    end)

    local monsters = {}
    for _, point in ipairs(matchedPoints) do
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