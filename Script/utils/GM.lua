local GM = {}
local PlayerInitialData = UGCGameSystem.UGCRequire("Script.Common.PlayerInitialData")

local PLAYER_SKILL_1_PATH = "Asset/Blueprint/Prefabs/Skills/Lin/PlayerSkill/PlayerSkill_1.PlayerSkill_1_C"

function GM:Register(DebugUI)
    local UGCGMUI = require("client.ingame.ugc.ugc_gmui")
    local CurFuncList = {}

    CurFuncList["调试"] = {
        ["玩家数据重置"] = {
            {UGCGMUI.ItemTypeEnum.Button, { {"重置当前玩家数据"}, {"清空当前玩家养成和背包，并重新发放初始物资"} },
             "S_ResetCurrentPlayerData"}
        }
    }
    return CurFuncList
end

local function GetPlayerPawn(PlayerController)
    if PlayerController == nil then
        return nil
    end
    if UGCGameSystem.GetPlayerPawnByPlayerController ~= nil then
        local Pawn = UGCGameSystem.GetPlayerPawnByPlayerController(PlayerController)
        if Pawn ~= nil then
            return Pawn
        end
    end
    return PlayerController.Pawn or
               (PlayerController.K2_GetPawn ~= nil and PlayerController:K2_GetPawn() or nil)
end

local function RemoveLevelSkill(PlayerPawn)
    if PlayerPawn == nil or UGCPersistEffectSystem == nil or
        UGCPersistEffectSystem.GetSkillsByClass == nil or UGCPersistEffectSystem.RemoveSkillInstance == nil then
        return
    end

    local SkillClassPath = UGCGameSystem.GetUGCResourcesFullPath(PLAYER_SKILL_1_PATH)
    local Success, Skills = pcall(UGCPersistEffectSystem.GetSkillsByClass, PlayerPawn, SkillClassPath)
    if not Success or Skills == nil then
        return
    end

    if type(Skills) ~= "table" then
        Skills = {Skills}
    end
    for _, SkillInstance in pairs(Skills) do
        pcall(UGCPersistEffectSystem.RemoveSkillInstance, PlayerPawn, SkillInstance)
    end
end

local function RefreshClientAndPawn(PlayerController, PlayerPawn, PlayerState)
    PlayerController.ProbabilityBonusPermanent = nil
    PlayerController.ProbabilityBonusPermanentValue = nil
    PlayerController.ProbabilityBonusRemainingSeconds = 0
    PlayerController.ProbabilityBonusTimedValue = nil
    if UGCTimerUtility.RemoveLuaTimerByName ~= nil then
        UGCTimerUtility.RemoveLuaTimerByName("ProbabilityBonus_" .. tostring(PlayerController.PlayerKey))
    end

    -- 保留无敌功能的购买权益，但将本局开关恢复为关闭。
    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
        PlayerState:SetYXWD_InvincibleBuffActive(false)
    else
        PlayerState.YXWD_InvincibleBuffActive = false
    end
    PlayerState.YXWD_InvincibleBuffToken = (tonumber(PlayerState.YXWD_InvincibleBuffToken) or 0) + 1
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_YXWDInvincibleActiveChanged", 0)

    PlayerPawn.EquippedTitleID = 0
    PlayerController.EquippedTitleID = 0
    local TitleActor = PlayerPawn.PlayerTitleActor
    if TitleActor ~= nil and UE.IsValid(TitleActor) and TitleActor.SetTitle ~= nil then
        TitleActor:SetTitle(0)
    end

    RemoveLevelSkill(PlayerPawn)
    if PlayerPawn.RefreshStateMgrProperty ~= nil then
        PlayerPawn:RefreshStateMgrProperty(true)
    else
        UGCPawnAttrSystem.SetHealthMax(PlayerPawn, 100)
        UGCPawnAttrSystem.SetHealth(PlayerPawn, 100)
        UGCAttributeSystem.SetGameAttributeValue(PlayerPawn, "AttackPower", 40)
    end
    if PlayerPawn.RefreshSoulMesh ~= nil then
        PlayerPawn:RefreshSoulMesh(1, true)
    end
    if PlayerPawn.RefreshWeaponAttackBonus ~= nil then
        PlayerPawn:RefreshWeaponAttackBonus(true)
    end
    if PlayerPawn.ForceRefreshPropertySnapshot ~= nil then
        PlayerPawn:ForceRefreshPropertySnapshot()
    end

    if PlayerController.SyncWeaponBackpackNames ~= nil then
        PlayerController:SyncWeaponBackpackNames()
    end
    if PlayerController.SyncSavedTitleState ~= nil then
        PlayerController:SyncSavedTitleState()
    end
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_SyncLotteryState", {})
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ProbabilityBonusChanged", 100)
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_RefreshPlayerExp", 0, 60, 1)
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_PlayerDataReset")
end

--- 服务端 GM：只重置点击按钮的当前玩家。
function GM:S_ResetCurrentPlayerData(Param, PlayerController)
    if not UGCGameSystem.IsServer() then
        return
    end

    local PlayerPawn = GetPlayerPawn(PlayerController)
    local PlayerState = PlayerController and PlayerController.PlayerState or nil
    if PlayerController == nil or PlayerPawn == nil or PlayerState == nil then
        ugcprint("[GMReset] rejected: PlayerController, Pawn or PlayerState is nil")
        return
    end
    if PlayerState.bArchiveLoaded ~= true or PlayerState.ResetProgressionToDefaults == nil then
        ugcprint("[GMReset] rejected: player archive is not ready")
        return
    end

    local BackpackCleared, RemovedCount = PlayerInitialData.ClearBackpack(PlayerPawn)
    if not BackpackCleared then
        ugcprint("[GMReset] failed: backpack still has items, player=" .. tostring(PlayerController.PlayerKey))
        return
    end

    if not PlayerState:ResetProgressionToDefaults() then
        ugcprint("[GMReset] failed: archive reset rejected, player=" .. tostring(PlayerController.PlayerKey))
        return
    end

    PlayerInitialData.Grant(PlayerPawn, _G.HTCLv2ItemID)
    RefreshClientAndPawn(PlayerController, PlayerPawn, PlayerState)
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
        "玩家数据已重置，初始物资已重新发放")
    ugcprint("[GMReset] completed: player=" .. tostring(PlayerController.PlayerKey) ..
                 " removedItemInstances=" .. tostring(RemovedCount))
end

return GM
