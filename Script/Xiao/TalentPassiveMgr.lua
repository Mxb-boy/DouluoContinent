local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")
local TalentMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentMgr")

local TalentPassiveMgr = {}
local BuffClassCache = {}

local function BuildPassiveNodes()
    local PassiveNodes = {}

    for NodeID, Node in pairs(TalentConfig.Nodes or {}) do
        local Effects = type(Node) == "table" and Node.Effects or nil
        local BuffKey = type(Effects) == "table" and Effects.PassiveBuffKey or nil
        if type(BuffKey) == "string" and BuffKey ~= "" then
            table.insert(PassiveNodes, {
                NodeID = tonumber(Node.ID) or tonumber(NodeID),
                BuffKey = BuffKey
            })
        end
    end

    table.sort(PassiveNodes, function(Left, Right)
        return (Left.NodeID or 0) < (Right.NodeID or 0)
    end)
    return PassiveNodes
end

local PassiveNodes = BuildPassiveNodes()

local function GetBuffClass(BuffKey, Config)
    if BuffClassCache[BuffKey] ~= nil then
        return BuffClassCache[BuffKey]
    end

    local RelativePath = type(Config) == "table" and Config.Path or nil
    if type(RelativePath) ~= "string" or RelativePath == "" then
        return nil
    end

    local BuffPath = RelativePath
    if UGCGameSystem.GetUGCResourcesFullPath ~= nil then
        local Success, Result = pcall(UGCGameSystem.GetUGCResourcesFullPath, RelativePath)
        if Success and type(Result) == "string" and Result ~= "" then
            BuffPath = Result
        end
    end

    if UGCObjectUtility ~= nil and UGCObjectUtility.LoadClass ~= nil then
        local Success, Result = pcall(UGCObjectUtility.LoadClass, BuffPath)
        if Success then
            BuffClassCache[BuffKey] = Result
        end
    end
    if BuffClassCache[BuffKey] == nil and UE ~= nil and UE.LoadClass ~= nil then
        local Success, Result = pcall(UE.LoadClass, BuffPath)
        if Success then
            BuffClassCache[BuffKey] = Result
        end
    end

    return BuffClassCache[BuffKey]
end

local function TryAddBuff(TargetActor, BuffKey, Config)
    local Chance = math.max(0, math.min(1, tonumber(Config.Chance) or 0))
    if math.random() >= Chance then
        return false
    end

    local BuffClass = GetBuffClass(BuffKey, Config)
    if BuffClass == nil then
        ugcprint("[TalentPassive] buff class load failed: key=" .. tostring(BuffKey) ..
                     ", path=" .. tostring(Config.Path))
        return false
    end

    local Success, Result = pcall(UGCPersistEffectSystem.AddBuffByClass, TargetActor, BuffClass, TargetActor)
    if not Success then
        ugcprint("[TalentPassive] add buff failed: " .. tostring(BuffKey) .. ", " .. tostring(Result))
        return false
    end

    local BuffCount = -1
    if UGCPersistEffectSystem.GetBuffsByClass ~= nil then
        local QuerySuccess, Buffs = pcall(UGCPersistEffectSystem.GetBuffsByClass, TargetActor, BuffClass)
        if QuerySuccess and Buffs ~= nil then
            local CountSuccess, Count = pcall(function()
                return #Buffs
            end)
            if CountSuccess then
                BuffCount = tonumber(Count) or -1
            end
        end
    end
    if Result == nil then
        return BuffCount > 0
    end
    return true
end

function TalentPassiveMgr:TryTriggerOnDamage(CauserActor, PlayerState)
    if CauserActor == nil or PlayerState == nil or UGCPersistEffectSystem == nil or
        UGCPersistEffectSystem.AddBuffByClass == nil then
        return 0
    end
    if UGCGameSystem.IsServer ~= nil and not UGCGameSystem.IsServer() then
        return 0
    end

    local TriggeredCount = 0
    for _, PassiveNode in ipairs(PassiveNodes) do
        if TalentMgr:HasLearnedTalent(PlayerState, PassiveNode.NodeID) then
            local Config = TalentConfig.PassiveBuffs ~= nil and
                               TalentConfig.PassiveBuffs[PassiveNode.BuffKey] or nil
            if type(Config) == "table" and TryAddBuff(CauserActor, PassiveNode.BuffKey, Config) then
                TriggeredCount = TriggeredCount + 1
            end
        end
    end
    return TriggeredCount
end

return TalentPassiveMgr
