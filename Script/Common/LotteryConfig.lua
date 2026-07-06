local LotteryConfig = {}

local PoolTablePath = "Data/Table/Customized/LotteryPoolConfig"
local AwardTablePath = "Data/Table/Customized/LotteryAwardConfig"
local ProjectRootPath = UGCMapInfoLib.GetRootLongPackagePath()
local IsValidIconPath

local function NormalizeIconPath(IconPath)
    IconPath = tostring(IconPath or "")
    -- Strip trailing pointer " @0x..."
    local Path = string.match(IconPath, "^%S+%s+(/%S+)") or string.match(IconPath, "^(%S+)") or IconPath
    -- Strip "Texture2D'/path'" wrapper
    Path = string.match(Path, "^Texture2D'(.-)'$") or Path
    -- Strip simple quotes
    Path = string.match(Path, "^'(.-)'$") or Path
    if string.find(Path, "Asset/") == 1 then
        return ProjectRootPath .. Path
    end
    local AssetPath = string.match(Path, "/Asset/(.+)")
    if AssetPath ~= nil then
        return ProjectRootPath .. "Asset/" .. AssetPath
    end
    return Path
end

local function GetTableIconPath(IconPath)
    if IconPath == nil or IconPath == "" then
        return ""
    end
    local Path = NormalizeIconPath(IconPath)
    if IsValidIconPath(Path) then
        return Path
    end
    return ""
end

local function IsOpen(Value)
    return Value == true or Value == 1 or Value == "1" or Value == "true" or Value == "True"
end

function IsValidIconPath(IconPath)
    return type(IconPath) == "string"
        and IconPath ~= ""
        and IconPath ~= "None"
        and string.find(IconPath, "ByteProperty_") ~= 1
        and (string.find(IconPath, "/") ~= nil or string.find(IconPath, "Asset/") == 1)
end

local function ToHardcodedPath(FullPath)
    local AssetPart = string.match(FullPath, "/Asset/(.+)$")
    if AssetPart then
        return ProjectRootPath .. "Asset/" .. AssetPart
    end
    return FullPath
end

-- Hardcoded fallback from LotteryAwardConfig CSV
local HardcodedIcons = {
    -- Weapon pool
    [8310000] = ToHardcodedPath("/Douluo/Asset/cs/HWSCJ_B.HWSCJ_B"),                                      -- 海王三叉戟
    [8310064] = ToHardcodedPath("/Douluo/Asset/ui/Icon/w_20260630125242_14.w_20260630125242_14"),          -- 爬塔传送券
    [8310065] = ToHardcodedPath("/Douluo/Asset/ui/Icon/lvx2.lvx2"),                                       -- 十分钟双倍药水
    [8310035] = ToHardcodedPath("/Douluo/Asset/ui/Icon/rghj.rghj"),                                      -- 魂骨融晶
    [8310059] = ToHardcodedPath("/Douluo/Asset/ChiBang/Icon/Chibang8Icon.Chibang8Icon"),                   -- 骸骨亡灵骨翼
    [8310053] = ToHardcodedPath("/Douluo/Asset/Blueprint/Lin/Monster/Model/Icon/Pic_4.Pic_4"),            -- 万年魂环
    [8310049] = ToHardcodedPath("/Douluo/Asset/Blueprint/Lin/Monster/Model/Icon/Pic_2.Pic_2"),            -- 百年魂环
    -- Wing pool
    [8310010] = ToHardcodedPath("/Douluo/Asset/ChiBang/Icon/CB_2T.CB_2T"),                                -- 星澜幻彩羽翼
    [8310036] = ToHardcodedPath("/Game/Arts/UI/TableIcons/ItemIcon/Inkjet/2021newyear_128.2021newyear_128"), -- 千年魂核
    [8310004] = ToHardcodedPath("/Douluo/Asset/cs/LCSL/LCSL_T.LCSL_T"),                                   -- 影罗夺命镰
    [8310066] = ToHardcodedPath("/Douluo/Asset/ui/Icon/fx2.fx2"),                                         -- 30分钟双倍药水
    [8310037] = ToHardcodedPath("/Douluo/Asset/ui/Icon/hszz.hszz"),                                       -- 魂师之证
    -- Title pool
    [8310061] = ToHardcodedPath("/Douluo/Asset/ui/huaban_6553688612.huaban_6553688612"),                  -- 富甲一方
    [8310051] = ToHardcodedPath("/Douluo/Asset/Blueprint/Lin/Monster/Model/Icon/Pic_3.Pic_3"),            -- 千年魂环
    [8310068] = ToHardcodedPath("/Douluo/Asset/ui/Icon/lvx10.lvx10"),                                     -- 10分钟10倍药水
    [8310039] = ToHardcodedPath("/Douluo/Asset/ui/Icon/lyzh.lyzh"),                                       -- 领域之核
    [8310060] = ToHardcodedPath("/Douluo/Asset/ui/huaban_6553688608.huaban_6553688608"),                  -- 丹青妙手
    -- FHSY pool
    [8310044] = ToHardcodedPath("/Douluo/Asset/ui/Icon/w_20260630125242_2.w_20260630125242_2"),           -- 封号神印
    [8310042] = ToHardcodedPath("/Douluo/Asset/ui/Icon/shy.shy"),                                         -- 圣魂玉
    [8310045] = ToHardcodedPath("/Douluo/Asset/ui/Icon/fhsy.fhsy"),                                       -- 九色神光
    [8310043] = ToHardcodedPath("/Douluo/Asset/ui/Icon/sszx.sszx"),                                       -- 神兽之血
}

local function GetHardcodedIconPath(ItemID)
    return HardcodedIcons[ItemID]
end

local function LoadUGCObjectIcons()
    local Icons = {}
    local Success, ObjectTable = pcall(UGCGameSystem.GetTableData, "Data/Table/UGCObject")
    if not Success or ObjectTable == nil then
        return Icons
    end

    for _, Row in pairs(ObjectTable) do
        local ItemID = tonumber(Row.ItemID)
        if ItemID ~= nil and Row.ItemSmallIcon ~= nil then
            local IconPath = KismetSystemLibrary.BreakSoftObjectPath(Row.ItemSmallIcon)
            if IsValidIconPath(IconPath) then
                Icons[ItemID] = NormalizeIconPath(IconPath)
            end
        end
    end
    return Icons
end

LotteryConfig.Types = {
    Weapon = 1,
    Wing = 2,
    Title = 3,
    FHSY = 4,
}

LotteryConfig.CostItemID = 8310008

LotteryConfig.RoundCosts = { 8, 38, 88, 128, 188, 268, 368 }
LotteryConfig.DiscountCosts = { 4, 19, 44, 64 }
LotteryConfig.DiscountRoundCount = 4
LotteryConfig.MaxRound = 7
LotteryConfig.SmallAwardWeight = 165
LotteryConfig.CompleteOnGrandPrize = true
LotteryConfig.GrantMissingAwardsOnGrandPrize = true
LotteryConfig.LockPoolOnComplete = true
LotteryConfig.ResetPoolOnComplete = false
LotteryConfig.Pools = {}
LotteryConfig.bLoadedTables = false

function LotteryConfig.LoadFromTables()
    LotteryConfig.bLoadedTables = true
    local SuccessPool, PoolTable = pcall(UGCGameSystem.GetTableData, PoolTablePath)
    local SuccessAward, AwardTable = pcall(UGCGameSystem.GetTableData, AwardTablePath)
    if not SuccessPool or not SuccessAward or PoolTable == nil or AwardTable == nil then
        ugcprint("[LotteryConfig] Load table failed")
        return false
    end

    local Pools = {}
    local PoolCount = 0
    for _, Row in pairs(PoolTable) do
        local PoolID = tonumber(Row.PoolID)
        if PoolID ~= nil and IsOpen(Row.IsOpen) then
            Pools[PoolID] = {
                Name = Row.PoolName or tostring(PoolID),
                GrandPrizeRound = tonumber(Row.GrandPrizeRound) or LotteryConfig.MaxRound,
                GrandPrize = nil,
                Awards = {},
            }
            PoolCount = PoolCount + 1
        end
    end

    if PoolCount <= 0 then
        ugcprint("[LotteryConfig] No open lottery pool")
        return false
    end

    local UGCObjectIcons = LoadUGCObjectIcons()
    for _, Row in pairs(AwardTable) do
        local PoolID = tonumber(Row.PoolID)
        local AwardIndex = tonumber(Row.AwardIndex)
        local Pool = Pools[PoolID]
        if Pool ~= nil and AwardIndex ~= nil then
            local ItemID = tonumber(Row.ItemID) or 0
            local RawIconPath = Row.IconPathText or Row.IconPathStr or Row.IconPath
            local IconPath = GetHardcodedIconPath(ItemID) or ""
            if not IsValidIconPath(IconPath) then
                IconPath = GetTableIconPath(RawIconPath)
            end
            if not IsValidIconPath(IconPath) then
                IconPath = UGCObjectIcons[ItemID] or ""
            end
            local Award = {
                ItemID = ItemID,
                Count = tonumber(Row.Count) or 1,
                Weight = tonumber(Row.Weight) or LotteryConfig.SmallAwardWeight,
                Name = Row.ItemName or "",
                IconPath = IconPath,
            }
            if AwardIndex == 0 then
                Pool.GrandPrize = Award
            elseif AwardIndex >= 1 and AwardIndex <= 6 then
                Pool.Awards[AwardIndex] = Award
            end
        end
    end

    for PoolID, Pool in pairs(Pools) do
        if Pool.GrandPrize == nil then
            ugcprint("[LotteryConfig] Pool missing grand prize: " .. tostring(PoolID))
            Pools[PoolID] = nil
        end
    end

    LotteryConfig.Pools = Pools
    return true
end

function LotteryConfig.EnsureLoaded()
    if not LotteryConfig.bLoadedTables then
        LotteryConfig.LoadFromTables()
    end
end

function LotteryConfig.GetPool(LotteryType)
    LotteryConfig.EnsureLoaded()
    return LotteryConfig.Pools[tonumber(LotteryType) or 0]
end

function LotteryConfig.GetRoundCost(RoundIndex)
    RoundIndex = tonumber(RoundIndex) or 1
    if RoundIndex <= LotteryConfig.DiscountRoundCount and LotteryConfig.DiscountCosts[RoundIndex] ~= nil then
        return LotteryConfig.DiscountCosts[RoundIndex]
    end

    return LotteryConfig.RoundCosts[RoundIndex] or LotteryConfig.RoundCosts[LotteryConfig.MaxRound]
end

function LotteryConfig.IsGrandPrizeRound(LotteryType, RoundIndex)
    local Pool = LotteryConfig.GetPool(LotteryType)
    return Pool ~= nil and tonumber(RoundIndex) == Pool.GrandPrizeRound
end

function LotteryConfig.GetAllAwards(LotteryType)
    local Pool = LotteryConfig.GetPool(LotteryType)
    if Pool == nil then
        return {}
    end

    local Awards = {}
    table.insert(Awards, Pool.GrandPrize)
    for _, Award in ipairs(Pool.Awards or {}) do
        table.insert(Awards, Award)
    end
    return Awards
end

function LotteryConfig.GetAwardByItemID(ItemID)
    LotteryConfig.EnsureLoaded()
    ItemID = tonumber(ItemID) or 0
    for _, Pool in pairs(LotteryConfig.Pools) do
        if Pool.GrandPrize ~= nil and tonumber(Pool.GrandPrize.ItemID) == ItemID then
            return Pool.GrandPrize
        end
        for _, Award in ipairs(Pool.Awards or {}) do
            if tonumber(Award.ItemID) == ItemID then
                return Award
            end
        end
    end
    return nil
end

function LotteryConfig.CanDrawCompletedPool()
    return not LotteryConfig.LockPoolOnComplete or LotteryConfig.ResetPoolOnComplete
end

return LotteryConfig
