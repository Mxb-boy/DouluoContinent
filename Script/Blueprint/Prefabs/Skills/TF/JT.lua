---@class JT_C:PESkillTemplate_Charge_C
--Edit Below--
local JT = {}
 
function JT:DisableFaceRotation()
    self.Owner.Owner.bDisableFaceRotation = true
end

function JT:EnableFaceRotation()
    self.Owner.Owner.bDisableFaceRotation = false
end

-- function JT:OnEnableSkill_BP()
-- end

-- function JT:OnDisableSkill_BP(DeltaTime)
   
-- end

-- function JT:OnActivateSkill_BP()
    
-- end

function JT:OnDeActivateSkill_BP()
    JT.SuperClass.OnDeActivateSkill_BP(self)
    -- 确保技能结束后，恢复角色面向旋转
    self:EnableFaceRotation() 
end

-- function JT:CanActivateSkill_BP()
-- end



return JT