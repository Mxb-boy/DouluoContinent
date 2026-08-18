---@class JT_2_C:PESkillTemplate_Base_C
--Edit Below--
local JT_2 = {}
 
function JT_2:DisableFaceRotation()
    self.Owner.Owner.bDisableFaceRotation = true
end

function JT_2:EnableFaceRotation()
    self.Owner.Owner.bDisableFaceRotation = false
end

-- function JT_2:OnEnableSkill_BP()
-- end

-- function JT_2:OnDisableSkill_BP(DeltaTime)
   
-- end

-- function JT_2:OnActivateSkill_BP()
    
-- end

function JT_2:OnDeActivateSkill_BP()
    JT_2.SuperClass.OnDeActivateSkill_BP(self)
    -- 确保技能结束后，恢复角色面向旋转
    self:EnableFaceRotation() 
end

-- function JT_2:CanActivateSkill_BP()
-- end



return JT_2