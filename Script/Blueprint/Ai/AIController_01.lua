---@class AIController_01_C:BaseAIController
--Edit Below--
local AIController_01 = {}
 
function AIController_01:GetBehaviorTreeObjectPath()
    return string.format('%sAsset/Blueprint/Ai/BeheaviorTree_01.BeheaviorTree_01', UGCMapInfoLib.GetRootLongPackagePath())
end

function AIController_01:OnPossess()
    self.SuperClass.OnPossess(self)
    self:RunBehaviorTree(UE.LoadObject(self:GetBehaviorTreeObjectPath()))
end


return AIController_01