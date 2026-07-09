---@class Boss_HealthBar_C:UGCGenericCharacterPositionWidget
---@field 030_NPC_HealthBar_Buff_01 UGC_NPC_HealthBar_Buff_UIBP_C
---@field 030_NPC_HealthBar_Buff_02 UGC_NPC_HealthBar_Buff_UIBP_C
---@field 030_NPC_HealthBar_Buff_03 UGC_NPC_HealthBar_Buff_UIBP_C
---@field 030_NPC_HealthBar_Buff_04 UGC_NPC_HealthBar_Buff_UIBP_C
---@field 030_NPC_HealthBar_Buff_05 UGC_NPC_HealthBar_Buff_UIBP_C
---@field 030_NPC_HealthBar_Buff_06 UGC_NPC_HealthBar_Buff_UIBP_C
---@field CanvasPanel_5 UCanvasPanel
---@field CanvasPanel_Arrow UCanvasPanel
---@field CanvasPanel_BuffItem UCanvasPanel
---@field CanvasPanel_HP UCanvasPanel
---@field HorizontalBox_1 UHorizontalBox
---@field Image_Arrow UImage
---@field Image_Icon UImage
---@field InScreenPnl UHorizontalBox
---@field OutScreenPnl UCanvasPanel
---@field ProgressBar_HP UProgressBar
---@field ProgressBar_LessBloodVFX UProgressBar
---@field SizeBox_3 USizeBox
---@field TextBlock_1 UTextBlock
---@field TextBlock_CurrentHP UTextBlock
---@field TextBlock_PlayInfo UTextBlock
---@field TextBlock_TotalHP UTextBlock
---@field UGC_ReuseList2_AttrBar UGC_ReuseList3_C
---@field isShowName bool
---@field IsShowBloodNum bool
---@field BloodFillImage ULuaMapHelper<float, FSlateBrush>
---@field BackgroundImage FSlateBrush
---@field Buffs ULuaArrayHelper<UPersistEffectBuff>
---@field BuffItems ULuaArrayHelper<UGC_NPC_HealthBar_Buff_UIBP_C>
---@field Last int32
---@field HealthPreDeductFillImage FSlateBrush
---@field GameAttributeFillImageMap ULuaArrayHelper<FGameAttributeHealthBarColor__pf964392390>
--Edit Below--
local Boss_HealthBar = { bInitDoOnce = false } 
local Ma_NumShow = UGCGameSystem.UGCRequire("Script.Ma.Ma_NumShow")

--[==[ Construct
function Boss_HealthBar:Construct()
	
end
-- Construct ]==]

function Boss_HealthBar:BP_CharacterHPChange(InHPCurrent, InHPMax)
	local Percent = 0
	if InHPMax > 0 then
		Percent = InHPCurrent / InHPMax
	end

	if self.ProgressBar_HP ~= nil then
		self.ProgressBar_HP:SetPercent(Percent)
	end
	if self.TextBlock_CurrentHP ~= nil then
		self.TextBlock_CurrentHP:SetText(Ma_NumShow.Format(InHPCurrent))
	end
	if self.TextBlock_TotalHP ~= nil then
		self.TextBlock_TotalHP:SetText(Ma_NumShow.Format(InHPMax))
	end

	-- 扣血缓降动画
	self:PlayLessBloodAnim()
end

function Boss_HealthBar:PlayLessBloodAnim()
	if self.ProgressBar_LessBloodVFX == nil or self.ProgressBar_HP == nil then
		return
	end

	local TimerName = "LessBloodAnim_" .. tostring(self)
	local AnimStep = 0.02
	local AnimInterval = 0.03

	UGCTimerUtility.RemoveLuaTimerByName(TimerName)
	UGCTimerUtility.CreateLuaTimer(AnimInterval, function()
		local vfxPercent = self.ProgressBar_LessBloodVFX:GetPercent()
		local hpPercent = self.ProgressBar_HP:GetPercent()

		if vfxPercent <= hpPercent then
			self.ProgressBar_LessBloodVFX:SetPercent(hpPercent)
			UGCTimerUtility.RemoveLuaTimerByName(TimerName)
			return
		end

		local newVFX = vfxPercent - AnimStep
		if newVFX < hpPercent then
			newVFX = hpPercent
		end
		self.ProgressBar_LessBloodVFX:SetPercent(newVFX)
	end, true, TimerName)
end

function Boss_HealthBar:Destruct()
	UGCTimerUtility.RemoveLuaTimerByName("LessBloodAnim_" .. tostring(self))
end

return Boss_HealthBar
