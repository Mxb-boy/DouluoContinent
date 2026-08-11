local MA_CS = {}

local BDZ_SKILL_PATH = "Asset/Blueprint/Prefabs/Skills/TF/BDZ.BDZ_C"
local BDZ_SKILL_SLOT = "UI.UISlot.MainUISlot_Skill.Slot2"

local function Log(Message)
    if ugcprint ~= nil then
        ugcprint("[MA_CS] " .. tostring(Message))
    end
end

---Equip BDZ into the main UI skill slot 2.
---@param TargetActor AActor Player Pawn with a PersistBaseComponent
---@return UPersistEffectSkill|nil
function MA_CS.EquipBDZ(TargetActor)
    if TargetActor == nil then
        Log("EquipBDZ failed: TargetActor is nil")
        return nil
    end

    if TargetActor.MA_BDZSkillInstance ~= nil then
        return TargetActor.MA_BDZSkillInstance
    end

    if UGCPersistEffectSystem == nil or UGCPersistEffectSystem.AddSkillByClass == nil then
        Log("EquipBDZ failed: AddSkillByClass is unavailable")
        return nil
    end

    local SkillPath = UGCGameSystem.GetUGCResourcesFullPath(BDZ_SKILL_PATH)
    local Success, SkillInstance = pcall(
        UGCPersistEffectSystem.AddSkillByClass,
        TargetActor,
        SkillPath,
        nil,
        BDZ_SKILL_SLOT
    )
    if not Success or SkillInstance == nil then
        Log("EquipBDZ failed: path=" .. tostring(SkillPath) ..
            " slot=" .. BDZ_SKILL_SLOT .. " error=" .. tostring(SkillInstance))
        return nil
    end

    TargetActor.MA_BDZSkillInstance = SkillInstance
    Log("BDZ equipped: slot=" .. BDZ_SKILL_SLOT)
    return SkillInstance
end

return MA_CS
