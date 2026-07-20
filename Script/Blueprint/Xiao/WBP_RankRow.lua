---@class WBP_RankRow_C:UUserWidget
---@field Text_PlayerName UTextBlock
---@field Text_Rank UTextBlock
---@field Text_Score UTextBlock
--Edit Below--
local WBP_RankRow = { bInitDoOnce = false }

local NORMAL_FONT_SCALE = 1.0
local TOP_THREE_FONT_SCALE = 1.3

local function ToDisplayText(Value, DefaultValue)
    if Value == nil then
        return DefaultValue or ""
    end
    return tostring(Value)
end

local function ApplyTextFontScale(Owner, Widget, BaseSizeKey, Scale)
    if Widget == nil or Widget.SetFont == nil or Widget.Font == nil then
        return
    end

    local FontInfo = Widget.Font
    local BaseSize = tonumber(Owner[BaseSizeKey])
    if BaseSize == nil then
        BaseSize = tonumber(FontInfo.Size)
        Owner[BaseSizeKey] = BaseSize
    end
    if BaseSize == nil then
        return
    end

    FontInfo.Size = math.max(1, math.floor(BaseSize * Scale + 0.5))
    Widget:SetFont(FontInfo)
end

function WBP_RankRow:ApplyRankFontSize(Rank)
    local NumericRank = tonumber(Rank)
    local Scale = NORMAL_FONT_SCALE
    if NumericRank ~= nil and NumericRank >= 1 and NumericRank <= 3 then
        Scale = TOP_THREE_FONT_SCALE
    end

    -- RenderScale 不参与 UMG 布局计算，会把固定宽度的 TextBlock 一并放大并造成裁切。
    -- 始终恢复为 1.0，只动态修改字体字号，让文字按正常布局规则重新测量。
    local NormalRenderScale = { X = 1.0, Y = 1.0 }
    if self.Text_Rank ~= nil and self.Text_Rank.SetRenderScale ~= nil then
        self.Text_Rank:SetRenderScale(NormalRenderScale)
    end
    if self.Text_PlayerName ~= nil and self.Text_PlayerName.SetRenderScale ~= nil then
        self.Text_PlayerName:SetRenderScale(NormalRenderScale)
    end
    if self.Text_Score ~= nil and self.Text_Score.SetRenderScale ~= nil then
        self.Text_Score:SetRenderScale(NormalRenderScale)
    end

    ApplyTextFontScale(self, self.Text_Rank, "BaseRankFontSize", Scale)
    ApplyTextFontScale(self, self.Text_PlayerName, "BasePlayerNameFontSize", Scale)
    ApplyTextFontScale(self, self.Text_Score, "BaseScoreFontSize", Scale)
end

---设置单行排行榜数据。
---@param Rank number|string
---@param PlayerName string
---@param Score number|string
function WBP_RankRow:SetData(Rank, PlayerName, Score)
    self:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:ApplyRankFontSize(Rank)

    if self.Text_Rank ~= nil then
        self.Text_Rank:SetText(ToDisplayText(Rank, "-"))
    end
    if self.Text_PlayerName ~= nil then
        self.Text_PlayerName:SetText(ToDisplayText(PlayerName, "加载中..."))
    end
    if self.Text_Score ~= nil then
        self.Text_Score:SetText(ToDisplayText(Score, "0"))
    end
end

---清空并隐藏没有数据的行。
function WBP_RankRow:Clear()
    self:ApplyRankFontSize(nil)

    if self.Text_Rank ~= nil then
        self.Text_Rank:SetText("")
    end
    if self.Text_PlayerName ~= nil then
        self.Text_PlayerName:SetText("")
    end
    if self.Text_Score ~= nil then
        self.Text_Score:SetText("")
    end

    self:SetVisibility(ESlateVisibility.Collapsed)
end

return WBP_RankRow
