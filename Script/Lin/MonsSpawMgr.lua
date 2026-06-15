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

return MonsterSpawnMgr