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
			Character = GameplayStatics.GetPlayerController(self, 0):GetPlayerCharacterSafety()
		end
		self.Character = Character
		self:GetPlayerKeyByCharacter(Character)
		self:SetHeadImageByPlayerKey(self.PlayerKey)
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
	self:print("SetHeadImageByPlayerKey --" .. PlayerKey)
	local PS = UGCGameSystem.GetPlayerStateByPlayerKey(PlayerKey):GetTeamMatePlayerStateFromPlayerKey(PlayerKey)
	local AccountInfo = UGCPlayerStateSystem.GetPlayerAccountInfo(PlayerKey)
	local UID = PS:GetInt64UID()
	local IconURL = PS.IconURL
	self:print(string.format("UID:%d,IconURL:%s,playerlevel:%d", UID, IconURL, AccountInfo.PlayerLevel))
	self.Avatar:InitView(1, UID, IconURL, nil, nil, AccountInfo.PlayerLevel, true)
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

