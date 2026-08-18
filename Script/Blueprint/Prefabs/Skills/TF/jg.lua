---@class jg_C:PESkillTemplate_Base_C
---@field DamageValue float
--Edit Below--
local jg = {

}



function jg:TriggerConsume()
    self:ConsumeCD()
end

function jg:InitDamageValue()
    self.DamageValue = 5.0
end

function jg:AddDamageValue()
    self.DamageValue = self.DamageValue + 5.0
end

function jg:CustomDamage(DamageContext)
    print("自定义伤害开始")
    print(ExportText(DamageContext))
    local DamageTarget = UGCAttributeSystem.GetVictimFromContext(DamageContext)
    print(tostring(DamageTarget))
    local DamageSrc = self:GetOwnerActor()
    local DamageSrcPosition = DamageSrc:K2_GetActorLocation()
    local DamageTargetPosition = DamageTarget:K2_GetActorLocation()
    print("源位置"..tostring(DamageSrcPosition))
    print("目标位置"..tostring(DamageTargetPosition))
    local Dist = UGCMathUtility.VSize(UGCMathUtility.SubtractVector(DamageSrcPosition, DamageTargetPosition))
    print("目标距离"..tostring(Dist))
    --local DamageDistRate = UGCMathUtility.Clamp(Dist / 2000.0, 0.5, 2.0)
    local DamageDistRate = Dist / 2000.0
    print("伤害衰减系数"..tostring(DamageDistRate))
    print("基础伤害值"..tostring(self.DamageValue))
    print("自定义伤害结束")
    return self.DamageValue * DamageDistRate
end


return jg