---@class WBP_RankingListBtn_C:UUserWidget
---@field ClearRankData UButton
---@field IsIncremental UEditableTextBox
---@field RankID UEditableTextBox
---@field Score UEditableTextBox
---@field UID UEditableTextBox
---@field UpdateRankScore UButton
--Edit Below--
local WBP_RankingListBtn = { bInitDoOnce = false } 

function WBP_RankingListBtn:Construct()
    self.UpdateRankScore.OnClicked:Add(self.UpdateRankListScore, self);
    self.ClearRankData.OnClicked:Add(self.ClearAllRankData, self);
end

function WBP_RankingListBtn:UpdateRankListScore()
    if self.RankID.Text == nil or self.RankID.Text == "" or self.Score.Text == nil or self.Score.Text == "" or self.UID.Text == nil or self.UID.Text == "" then
        return;
    end

    local RankID = tonumber(self.RankID.Text);
    local Score = tonumber(self.Score.Text);
    local UID = tonumber(self.UID.Text);
    local IsIncremental = tonumber(self.IsIncremental.Text);

    -- RankingList test patch: forward score updates to server.
    local PC = STExtraGameplayStatics.GetFirstPlayerController(self);
    if PC ~= nil then
        UnrealNetwork.CallUnrealRPC(PC, PC, "Server_UpdateRankingListScore", UID, RankID, Score, IsIncremental);
    end
end

function WBP_RankingListBtn:ClearAllRankData()
    -- RankingList test patch: forward clear action to server.
    local PC = STExtraGameplayStatics.GetFirstPlayerController(self);
    if PC ~= nil then
        UnrealNetwork.CallUnrealRPC(PC, PC, "Server_ClearAllRankingListData");
    end
end

return WBP_RankingListBtn
