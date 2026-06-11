---@class AI_01_C:STExtraSimpleCharacter
---@field UAEMonsterAnimList UUAEMonsterAnimListComponent
---@field UAESkillManager UUAESkillManagerComponent
---@field Capsule UCapsuleComponent
--Edit Below--
local AI_01 = {}
 
--[[
function AI_01:ReceiveBeginPlay()
    AI_01.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function AI_01:ReceiveTick(DeltaTime)
    AI_01.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function AI_01:ReceiveEndPlay()
    AI_01.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function AI_01:GetReplicatedProperties()
    return
end
--]]

--[[
function AI_01:GetAvailableServerRPCs()
    return
end
--]]

return AI_01