---@class WBP_RankMonument_C:UUserWidget
---@field RankRow_10 WBP_RankRow_C
---@field RankRow_01 WBP_RankRow_C
---@field RankRow_02 WBP_RankRow_C
---@field RankRow_03 WBP_RankRow_C
---@field RankRow_04 WBP_RankRow_C
---@field RankRow_05 WBP_RankRow_C
---@field RankRow_06 WBP_RankRow_C
---@field RankRow_07 WBP_RankRow_C
---@field RankRow_08 WBP_RankRow_C
---@field RankRow_09 WBP_RankRow_C
---@field Text_Title UTextBlock
--Edit Below--
UGCGameSystem.UGCRequire("Script.Blueprint.Xiao.WBP_RankRow")

local WBP_RankMonument = { bInitDoOnce = false } 

function WBP_RankMonument:Construct()
    self:CacheRankRows()
end

function WBP_RankMonument:CacheRankRows()
    self.RankRows = {}
    for Index = 1, 10 do
        local WidgetName = string.format("RankRow_%02d", Index)
        self.RankRows[Index] = self[WidgetName]
    end
end

local function GetPlayerName(Entry)
    return Entry.PlayerName or Entry.ShowName or Entry.Name or "加载中..."
end

---刷新前十名。Entry 支持 Rank、PlayerName/ShowName/Name、Score 字段。
---@param Entries table
---@param ScoreFormatter function|nil
function WBP_RankMonument:SetRankListData(Entries, ScoreFormatter)
    if self.RankRows == nil then
        self:CacheRankRows()
    end

    Entries = Entries or {}
    for Index = 1, 10 do
        local Row = self.RankRows[Index]
        local Entry = Entries[Index]
        if Row ~= nil then
            if Entry ~= nil then
                local Score = Entry.Score or 0
                if ScoreFormatter ~= nil then
                    local bSuccess, FormattedScore = pcall(ScoreFormatter, Score, Entry, Index)
                    if bSuccess then
                        Score = FormattedScore
                    end
                end
                Row:SetData(Entry.Rank or Index, GetPlayerName(Entry), Score)
            else
                Row:Clear()
            end
        end
    end
end

function WBP_RankMonument:ClearRankList()
    self:SetRankListData({})
end

function WBP_RankMonument:SetRankTitle(Title)
    if self.Text_Title ~= nil then
        self.Text_Title:SetText(tostring(Title or ""))
    end
end

return WBP_RankMonument
