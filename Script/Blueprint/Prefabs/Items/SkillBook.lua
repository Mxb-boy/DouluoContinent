---@class SkillBook_C:UGCItemHandle_ConsumeBase_C
--Edit Below--
---@class SkillBook_C:UGCItemHandle_ConsumeBase_C
local SkillBook = {}

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")
local TalentMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentMgr")

local function GetPlayerController(ItemHandle)
    if UGCItemSystemV2 == nil or UGCItemSystemV2.GetOwnBackpackComponent == nil then
        return nil
    end

    local BackpackComponent = UGCItemSystemV2.GetOwnBackpackComponent(ItemHandle)
    return BackpackComponent ~= nil and BackpackComponent:GetOwner() or nil
end

function SkillBook:CanUseV2()
    local PlayerController = GetPlayerController(self)
    local PlayerState = PlayerController ~= nil and PlayerController.PlayerState or nil
    local PointsPerUse = math.max(1, math.floor(tonumber(TalentConfig.SkillBookPointsPerUse) or 1))
    return PlayerState ~= nil and PlayerState.bArchiveLoaded == true and
               TalentMgr:CanGrantTalentPoints(PlayerState, PointsPerUse)
end

function SkillBook:OnUseV2()
    local PlayerController = GetPlayerController(self)
    local PlayerState = PlayerController ~= nil and PlayerController.PlayerState or nil
    if PlayerState == nil or PlayerState.bArchiveLoaded ~= true then
        return
    end

    local ItemID = tonumber(self.ItemID) or tonumber(TalentConfig.SkillBookItemID)
    local PointsPerUse = math.max(1, math.floor(tonumber(TalentConfig.SkillBookPointsPerUse) or 1))
    if ItemID ~= tonumber(TalentConfig.SkillBookItemID) or
        not TalentMgr:CanGrantTalentPoints(PlayerState, PointsPerUse) then
        return
    end

    local ItemCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(PlayerController, ItemID)) or 0
    if ItemCount < 1 then
        return
    end

    local RemovedCount = tonumber(UGCBackpackSystemV2.RemoveItemV2(PlayerController, ItemID, 1)) or 0
    if RemovedCount < 1 then
        return
    end

    if not TalentMgr:GrantTalentPoints(PlayerState, PointsPerUse) then
        local RefundedCount = tonumber(UGCBackpackSystemV2.AddItemV2(PlayerController, ItemID, 1)) or 0
        ugcprint("[Talent] SkillBook grant failed; refunded=" .. tostring(RefundedCount >= 1))
        return
    end

    ugcprint("[Talent] SkillBook used item=" .. tostring(ItemID) .. " granted=" .. tostring(PointsPerUse) ..
                 " points=" .. tostring(PlayerState:GetTalentPoints()))
    if PlayerController.Server_RequestTalentState ~= nil then
        PlayerController:Server_RequestTalentState()
    end
end

return SkillBook
