---@class PlayerSkill_1_C:PESkillTemplate_Base_C
--Edit Below--
local PlayerSkill_1 = {}
 
--[[
function PlayerSkill_1:OnEnableSkill_BP()
end

function PlayerSkill_1:OnDisableSkill_BP(DeltaTime)
end

function PlayerSkill_1:OnActivateSkill_BP()
end

function PlayerSkill_1:OnDeActivateSkill_BP()
end

function PlayerSkill_1:CanActivateSkill_BP()
end

--]]

function PlayerSkill_1:OnActivateSkill_BP()
    print("PlayerSkill_1:OnActivateSkill_BP -- 技能触发")
    if self:HasAuthority() then
        print("PlayerSkill_1:OnActivateSkill_BP -- 设置无敌状态")
        --self.Owner.Owner:SetInvincible(true) 
        self:GetNetOwnerActor():SetInvincible(true)
    end

    PlayerSkill_1.SuperClass.OnActivateSkill_BP(self);
end

function PlayerSkill_1:OnDeActivateSkill_BP()
    print("PlayerSkill_1:OnDeActivateSkill_BP -- 退出技能")
    if self:HasAuthority() then
        --关闭无敌状态
        print("PlayerSkill_1:OnDeActivateSkill_BP -- 关闭无敌状态")
        --self.Owner.Owner:SetInvincible(false)
        self:GetNetOwnerActor():SetInvincible(false)
    end
    PlayerSkill_1.SuperClass.OnDeActivateSkill_BP(self);
end

return PlayerSkill_1