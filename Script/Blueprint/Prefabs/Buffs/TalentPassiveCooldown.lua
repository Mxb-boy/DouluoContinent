---@class TalentPassiveCooldown_C:PersistEffectBuff
---@field EnableMoveSpeed float
--Edit Below--
local TalentPassiveCooldown = {}
 
require("common.gameattribute.game_attribute_type")


function TalentPassiveCooldown:CanApply_BP(OwnerActor)
    -- 检查移速增幅是否大于50%
    local moveSpeed = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, NativeGameAttributeType.Character_UGCGeneralMoveSpeedScale)
    if moveSpeed > self.EnableMoveSpeed then
        return true
    else 
        return false
    end
end


function TalentPassiveCooldown:OnApply_BP(OwnerActor)
    ugcprint("TalentPassiveCooldown:OnApply_BP");
    local atk = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, CustomGameAttributeType.CustomAttribute_Example_BaseAttack)
    ugcprint("TalentPassiveCooldown atk: " .. atk)
end


function TalentPassiveCooldown:OnUnApply_BP(OwnerActor, Reason)
    local atk = UGCAttributeSystem.GetGameAttributeValue(OwnerActor, CustomGameAttributeType.CustomAttribute_Example_BaseAttack)
    ugcprint("TalentPassiveCooldown atk: " .. atk)
end

function TalentPassiveCooldown:OnStackChange_BP(PreNum, CurNum)
    self:RefreshBuff()
end

--[[
function @PersistEffectBuffName:CanMerge_BP(PersistEffect)

end
--]]

--[[
function @PersistEffectBuffName:OnMerge_BP(PersistEffect)

end
--]]


--[[
function @PersistEffectBuffName:OnInterrupted_BP(OwnerActor)

end
--]]

--[[
function @PersistEffectBuffName:OnTotalDurationChange_BP(PreTime, CurTime)

end
--]]

--[[
function @PersistEffectBuffName:OnStackChange_BP(PreNum, CurNum)

end
--]]

--[[
function @PersistEffectBuffName:OnTrigger_BP(Delta)

end
--]]


return TalentPassiveCooldown