---@class Avarar_frame_C:UAEUserWidget
---@field Avatar Common_Avatar_BP_C
---@field HeadImage UImage
---@field ProfileFrameImage UImage
---@field SizeBox_0 USizeBox
---@field HeadImagePath FString
---@field HeadImageType TEnumAsByte<GetHeadImageTypeEnum>
---@field ProfileFrameAssetPath FString
--Edit Below--
---@class Avarar_frame:UUAEUserWidget
local Avarar_frame = {
	PlayerKey = nil,
	Character = nil,
	Size = 100,
	AvatarRefreshRetryCount = 0,
	MaxAvatarRefreshRetryCount = 5,
}
function Avarar_frame:print(msg)
	print(string.format("[Avarar_frame]: %s", msg))
end

function Avarar_frame:Construct()
	self:print("Construct")
	self:ShowUI(nil)
end

function Avarar_frame:ShowUI(InCharacter)
	self:print("ShowUI")
	self:SetProfileFrameByAssetPath()
	self:SetWidthAndHeight(self.Size)
	if self.HeadImageType == 0 then --根据PlayerID设置头像
		self.HeadImage:SetVisibility(ESlateVisibility.Collapsed)
		self.Avatar:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
		local Character = nil
		if UE.IsValid(InCharacter) then
			Character = InCharacter
		else
			local PC = GameplayStatics.GetPlayerController(self, 0)
			Character = PC and PC:GetPlayerCharacterSafety() or nil
		end
		if not UE.IsValid(Character) then
			self:ScheduleRefreshAvatar()
			return
		end
		self.Character = Character
		self:GetPlayerKeyByCharacter(Character)
		if not self:SetHeadImageByPlayerKey(self.PlayerKey) then
			self:ScheduleRefreshAvatar()
		end
	elseif self.HeadImageType == 1 then --根据Asset路径设置头像
		self:print("set head image by asset path")
		self:SetHeadImageByAssetPath()
		self.HeadImage:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
		self.Avatar:SetVisibility(ESlateVisibility.Collapsed)
	end
end
function Avarar_frame:GetPlayerKeyByCharacter(Character)
	local PC = Character:GetPlayerControllerSafety()
	if PC ~= nil then
		self.PlayerKey = PC.PlayerKey
	end
end
function Avarar_frame:SetHeadImageByPlayerKey(PlayerKey)
	if PlayerKey == nil then
		return false
	end
	self:print("SetHeadImageByPlayerKey --" .. PlayerKey)
	local AccountInfo = UGCPlayerStateSystem.GetPlayerAccountInfo(PlayerKey)
	if AccountInfo == nil or AccountInfo.UID == nil then
		return false
	end
	local UID = AccountInfo.UID
	local IconURL = AccountInfo.IconURL
	self:print(string.format("UID:%s,IconURL:%s,playerlevel:%s", tostring(UID), tostring(IconURL), tostring(AccountInfo.PlayerLevel)))
	self.Avatar:InitView(2, UID, IconURL, AccountInfo.Gender, 0, AccountInfo.PlayerLevel, false, false)
	if IconURL == nil or IconURL == "" then
		return false
	end
	self.AvatarRefreshRetryCount = 0
	return true
end
function Avarar_frame:ScheduleRefreshAvatar()
	if self.AvatarRefreshRetryCount >= self.MaxAvatarRefreshRetryCount then
		return
	end
	self.AvatarRefreshRetryCount = self.AvatarRefreshRetryCount + 1
	UGCTimerUtility.CreateLuaTimer(1, function()
		self:ShowUI(self.Character)
	end, false)
end
function Avarar_frame:ResetHeadImagePath(NewPath)
	self.HeadImagePath = NewPath
end
function Avarar_frame:ResetProfileFrameAssetPath(NewPath)
	self.ProfileFrameAssetPath = NewPath
end
--Type=0为PlayerUD,Type=1为Asset路径
function Avarar_frame:ResetHeadImageType(Type)
	self.HeadImageType = Type
end
function Avarar_frame:SetHeadImageByAssetPath()
	FuncUtil.SetImageWithPathAsync(self.HeadImage, self.HeadImagePath)
end
function Avarar_frame:SetProfileFrameByAssetPath()
	FuncUtil.SetImageWithPathAsync(self.ProfileFrameImage, self.ProfileFrameAssetPath)
end
function Avarar_frame:SetWidthAndHeight(Size)
	self.SizeBox_0:SetWidthOverride(Size)
	self.SizeBox_0:SetHeightOverride(Size)
end
return Avarar_frame

