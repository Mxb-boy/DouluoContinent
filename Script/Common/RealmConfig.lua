local RealmConfig = {}

RealmConfig.MaxLevel = 10

local ProjectRootPath = UGCMapInfoLib.GetRootLongPackagePath()

local function GetSoulRingIconPath(Level)
    return ProjectRootPath
        .. "Asset/Blueprint/Lin/Monster/Model/Icon/Pic_"
        .. tostring(Level)
        .. ".Pic_"
        .. tostring(Level)
end

local ItemIDs = {
    SoulRing1 = 8310048,
    SoulRing2 = 8310049,
    SoulRing3 = 8310051,
    SoulRing4 = 8310053,
    SoulRing5 = 8310054,
    SoulRing6 = 8310055,
    SoulRing7 = 8310056,
    SoulRing8 = 8310057,
    SoulRing9 = 8310052,
    SoulRing10 = 8310052,

    RHY = 8310037,
    HSZZ = 8310038,
    LYZH = 8310039,
    FZSP = 8310040,
    DHY = 8310041,
    SHY = 8310042,
    SSZX = 8310043,
    FHSY = 8310044,
    JSSG = 8310045,
}

RealmConfig.LuckyItemText =
    "幸运道具：突破成功率+15%，单境界单次最多叠加1张\n例：九魂基础15%，用护符后 15+15=30%"

RealmConfig.Levels = {
    [1] = {
        Stage = "一魂",
        Name = "启灵境",
        IconPath = GetSoulRingIconPath(1),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：------",
        NeedItems = {},
        SuccessRate = 90,
        GuaranteeFailCount = 3,
        SuccessBonuses = { "生命值+15%", "攻击值+10%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败3次\n下一次突破必定成功\n重置失败计数",
    },
    [2] = {
        Stage = "二魂",
        Name = "融身境",
        IconPath = GetSoulRingIconPath(2),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第一魂环x1\n第二魂环x1",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing1, Count = 1, Name = "第一魂环", IconPath = GetSoulRingIconPath(1) },
            { ItemID = ItemIDs.SoulRing2, Count = 1, Name = "第二魂环", IconPath = GetSoulRingIconPath(2) },
        },
        SuccessRate = 85,
        GuaranteeFailCount = 3,
        SuccessBonuses = { "生命值+22%", "攻击值+16%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败3次\n下一次突破必定成功\n重置失败计数",
    },
    [3] = {
        Stage = "三魂",
        Name = "魂师境",
        IconPath = GetSoulRingIconPath(3),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第三魂环x1\n融魂玉x5",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing3, Count = 1, Name = "第三魂环", IconPath = GetSoulRingIconPath(3) },
            { ItemID = ItemIDs.RHY, Count = 5, Name = "融魂玉" },
        },
        DevConditionText = "融魂玉：海神岛副本掉落",
        SuccessRate = 80,
        GuaranteeFailCount = 3,
        SuccessBonuses = { "生命值+30%", "攻击值+23%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败3次\n下一次突破必定成功\n重置失败计数",
    },
    [4] = {
        Stage = "四魂",
        Name = "魂宗境",
        IconPath = GetSoulRingIconPath(4),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第四魂环x1\n魂师之证x1",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing4, Count = 1, Name = "第四魂环", IconPath = GetSoulRingIconPath(4) },
            { ItemID = ItemIDs.HSZZ, Count = 1, Name = "魂师之证" },
        },
        DevConditionText = "魂师之证：副本魂兽Boss掉落",
        SuccessRate = 72,
        GuaranteeFailCount = 3,
        SuccessBonuses = { "生命值+39%", "攻击值+31%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败3次\n下一次突破必定成功\n重置失败计数",
    },
    [5] = {
        Stage = "五魂",
        Name = "魂王境",
        IconPath = GetSoulRingIconPath(5),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第五魂环x1\n领域之核x1",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing5, Count = 1, Name = "第五魂环", IconPath = GetSoulRingIconPath(5) },
            { ItemID = ItemIDs.LYZH, Count = 1, Name = "领域之核" },
        },
        DevConditionText = "领域之核：击杀副本魂兽Boss概率掉落",
        SuccessRate = 60,
        GuaranteeFailCount = 5,
        SuccessBonuses = { "生命值+50%", "攻击值+40%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败5次\n下一次突破必定成功\n重置失败计数",
    },
    [6] = {
        Stage = "六魂",
        Name = "魂帝境",
        IconPath = GetSoulRingIconPath(6),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第六魂环x1\n法则碎片x10",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing6, Count = 1, Name = "第六魂环", IconPath = GetSoulRingIconPath(6) },
            { ItemID = ItemIDs.FZSP, Count = 10, Name = "法则碎片" },
        },
        DevConditionText = "法则碎片：挑战“法则回廊”副本",
        SuccessRate = 48,
        GuaranteeFailCount = 5,
        SuccessBonuses = { "生命值+63%", "攻击值+51%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败5次\n下一次突破必定成功\n重置失败计数",
    },
    [7] = {
        Stage = "七魂",
        Name = "魂圣境",
        IconPath = GetSoulRingIconPath(7),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第七魂环x1\n帝魂印x1",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing7, Count = 1, Name = "第七魂环", IconPath = GetSoulRingIconPath(7) },
            { ItemID = ItemIDs.DHY, Count = 1, Name = "帝魂印" },
        },
        DevConditionText = "帝魂印：集齐99个魂帝令碎片合成；魂帝令碎片掉落于所有万年魂兽",
        SuccessRate = 38,
        GuaranteeFailCount = 5,
        SuccessBonuses = { "生命值+78%", "攻击值+64%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败5次\n下一次突破必定成功\n重置失败计数",
    },
    [8] = {
        Stage = "八魂",
        Name = "魂尊境",
        IconPath = GetSoulRingIconPath(8),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第八魂环x1\n圣魂玉x20",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing8, Count = 1, Name = "第八魂环", IconPath = GetSoulRingIconPath(8) },
            { ItemID = ItemIDs.SHY, Count = 20, Name = "圣魂玉" },
        },
        DevConditionText = "圣魂玉：熔炼10个年魂环合成1个，或拍卖行购买",
        SuccessRate = 28,
        GuaranteeFailCount = 8,
        SuccessBonuses = { "生命值+96%", "攻击值+79%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败8次\n下一次突破必定成功\n重置失败计数",
    },
    [9] = {
        Stage = "九魂",
        Name = "封号斗罗",
        IconPath = GetSoulRingIconPath(9),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第九魂环x1\n神兽之血x1",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing9, Count = 1, Name = "第九魂环", IconPath = GetSoulRingIconPath(9) },
            { ItemID = ItemIDs.SSZX, Count = 1, Name = "神兽之血" },
        },
        DevConditionText = "神兽之血：击杀特定魂兽“九头天蛇”或“冰晶凤凰”必掉",
        SuccessRate = 15,
        GuaranteeFailCount = 8,
        SuccessBonuses = { "生命值+120%", "攻击值+98%" },
        FailText = "全部突破道具回收",
        GuaranteeText = "连续失败8次\n下一次突破必定成功\n重置失败计数",
    },
    [10] = {
        Stage = "十魂",
        Name = "神境",
        IconPath = GetSoulRingIconPath(10),
        NeedPowerText = "战力门槛：------",
        NeedItemText = "所需道具：第十魂环x1\n封号神印x1\n九色神光x9",
        NeedItems = {
            { ItemID = ItemIDs.SoulRing10, Count = 1, Name = "第十魂环", IconPath = GetSoulRingIconPath(10) },
            { ItemID = ItemIDs.FHSY, Count = 1, Name = "封号神印" },
            { ItemID = ItemIDs.JSSG, Count = 9, Name = "九色神光" },
        },
        DevConditionText = "封号神印：全服唯一掉落，刷新于“封号之巅”，可被抢夺，持有者全服公告\n九色神光：每完成一次天道试炼跑酷得1道",
        SuccessRate = 0,
        GuaranteeFailCount = 0,
        SuccessBonuses = {},
        FailText = "已达最高境界",
        GuaranteeText = "已达最高境界",
    },
}

function RealmConfig.Get(Level)
    return RealmConfig.Levels[tonumber(Level) or 1]
end

function RealmConfig.GetNext(Level)
    local NextLevel = (tonumber(Level) or 1) + 1
    if NextLevel > RealmConfig.MaxLevel then
        return nil
    end

    return RealmConfig.Levels[NextLevel]
end

function RealmConfig.GetDisplayName(Config)
    if Config == nil then
        return ""
    end

    return tostring(Config.Stage or "") .. "·" .. tostring(Config.Name or "")
end

function RealmConfig.ParseBonusText(BonusText)
    BonusText = tostring(BonusText or "")
    local Label, Value = string.match(BonusText, "^%s*(.-)%s*%+%s*([%d%.]+)%%%s*$")
    if Label ~= nil and Value ~= nil then
        return Label, tonumber(Value) or 0
    end

    Label, Value = string.match(BonusText, "^%s*(.-)加成%s*([%d%.]+)%%%s*$")
    if Label ~= nil and Value ~= nil then
        return Label, tonumber(Value) or 0
    end

    return BonusText, 0
end

function RealmConfig.GetAttrBonuses(Level)
    local Config = RealmConfig.Get(Level)
    local Result = {
        HPPercent = 0,
        AttackPercent = 0,
    }
    if Config == nil then
        return Result
    end

    for _, BonusText in ipairs(Config.SuccessBonuses or {}) do
        local Label, Value = RealmConfig.ParseBonusText(BonusText)
        if string.find(Label, "生命") ~= nil then
            Result.HPPercent = tonumber(Value) or 0
        elseif string.find(Label, "攻击") ~= nil then
            Result.AttackPercent = tonumber(Value) or 0
        end
    end

    return Result
end

function RealmConfig.RollBreakResult(Level, CurrentFailCount, ExtraRate)
    local Config = RealmConfig.Get(Level)
    if Config == nil then
        return false, false, 0
    end

    CurrentFailCount = tonumber(CurrentFailCount) or 0
    local GuaranteeFailCount = tonumber(Config.GuaranteeFailCount) or 0
    if GuaranteeFailCount > 0 and CurrentFailCount >= GuaranteeFailCount then
        return true, true, 100
    end

    local Rate = (tonumber(Config.SuccessRate) or 0) + (tonumber(ExtraRate) or 0)
    Rate = math.max(0, math.min(100, Rate))
    return math.random(1, 100) <= Rate, false, Rate
end

return RealmConfig
