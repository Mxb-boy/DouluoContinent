---@class BP_RankMonument_C:AActor
---@field RankWidget UWidgetComponent
---@field DefaultSceneRoot USceneComponent
---@field RankID int32
---@field RankTitle FString
--Edit Below--
UGCGameSystem.UGCRequire("ExtendResource.RankingList.OfficialPackage.Script.RankingList.RankingListManager")
local Ma_NumShow = UGCGameSystem.UGCRequire("Script.Ma.Ma_NumShow")

local BP_RankMonument = { bInitDoOnce = false }

local MAX_RANK_COUNT = 10
local ZHANLI_RANK_ID = 1
local WEALTH_RANK_ID = 2
local TOWER_RANK_ID = 3
local ZHANLI_RANKING_CYCLE = 0 -- 临时测试本期；正式展示上一期时改为 1
local RANKING_CYCLE_BY_ID = {
    [ZHANLI_RANK_ID] = ZHANLI_RANKING_CYCLE,
    [WEALTH_RANK_ID] = 0, -- 财富榜显示本期
    [TOWER_RANK_ID] = 0,  -- 爬塔榜显示本期
}
local DEFAULT_RANK_TITLE_BY_ID = {
    [ZHANLI_RANK_ID] = "战力榜",
    [WEALTH_RANK_ID] = "财富榜",
    [TOWER_RANK_ID] = "爬塔榜",
}
local MAX_INIT_RETRY_COUNT = 30
local INIT_RETRY_INTERVAL = 0.5
local DATA_POLL_COUNT = 10
local DATA_POLL_INTERVAL = 0.5
local PERIODIC_REFRESH_INTERVAL = 30

local function IsNonEmptyString(Value)
    return Value ~= nil and tostring(Value) ~= ""
end

local function SafeCall(Object, MethodName, ...)
    if Object == nil or Object[MethodName] == nil then
        return nil
    end

    local bSuccess, Result = pcall(Object[MethodName], Object, ...)
    if bSuccess then
        return Result
    end
    return nil
end

local function GetRuntimeObjectName(Object)
    if Object == nil then
        return ""
    end
    if UGCObjectUtility ~= nil and UGCObjectUtility.GetObjectName ~= nil then
        local bSuccess, ObjectName = pcall(UGCObjectUtility.GetObjectName, Object)
        if bSuccess and ObjectName ~= nil then
            return tostring(ObjectName)
        end
    end
    if KismetSystemLibrary ~= nil and KismetSystemLibrary.GetObjectName ~= nil then
        local bSuccess, ObjectName = pcall(KismetSystemLibrary.GetObjectName, Object)
        if bSuccess and ObjectName ~= nil then
            return tostring(ObjectName)
        end
    end
    return ""
end

function BP_RankMonument:ApplyRuntimeRankConfig()
    local ObjectName = GetRuntimeObjectName(self)
    local RankID = ZHANLI_RANK_ID

    -- 三个场景实例复用同一蓝图，按实例对象名前缀自动决定显示哪张榜。
    if string.find(ObjectName, "BP_RankMonument3", 1, true) ~= nil then
        RankID = TOWER_RANK_ID
    elseif string.find(ObjectName, "BP_RankMonument2", 1, true) ~= nil then
        RankID = WEALTH_RANK_ID
    end

    self.RankID = RankID
    self.RankTitle = DEFAULT_RANK_TITLE_BY_ID[RankID]
    ugcprint(string.format("[BP_RankMonument] ObjectName=%s RankID=%s RankTitle=%s",
        ObjectName, tostring(self.RankID), tostring(self.RankTitle)))
end

function BP_RankMonument:ReceiveBeginPlay()
    BP_RankMonument.SuperClass.ReceiveBeginPlay(self)

    self.bRankMonumentEnded = false
    self:ApplyRuntimeRankConfig()
    self:TryInitializeRankDisplay(0)
end

function BP_RankMonument:ReceiveEndPlay()
    self.bRankMonumentEnded = true
    self:UnbindRankDelegates()
    BP_RankMonument.SuperClass.ReceiveEndPlay(self)
end

function BP_RankMonument:GetRankWidgetObject()
    if self.RankWidget == nil then
        return nil
    end

    return self.RankWidget:GetUserWidgetObject()
end

function BP_RankMonument:GetLocalRankingListComponent(PlayerController)
    if PlayerController == nil or RankingListManager == nil or
        RankingListManager.GetRankingListComponent == nil then
        return nil
    end

    -- 始终显式传入本地控制器，兼容客户端、单机和监听服务器。
    return SafeCall(RankingListManager, "GetRankingListComponent", PlayerController)
end

function BP_RankMonument:GetRankingCycles()
    return RANKING_CYCLE_BY_ID[tonumber(self.RankID)] or 0
end

function BP_RankMonument:ApplyRankTitle()
    local RankWidgetObject = self:GetRankWidgetObject()
    if RankWidgetObject == nil or RankWidgetObject.SetRankTitle == nil then
        return
    end

    local Title = self.RankTitle
    if not IsNonEmptyString(Title) and RankingListManager ~= nil and
        RankingListManager.GetRankConfigData ~= nil then
        local RankConfig = SafeCall(RankingListManager, "GetRankConfigData", tonumber(self.RankID) or 0)
        if RankConfig ~= nil then
            Title = RankConfig.TabName
        end
    end
    if not IsNonEmptyString(Title) then
        Title = DEFAULT_RANK_TITLE_BY_ID[tonumber(self.RankID)]
    end
    if not IsNonEmptyString(Title) then
        Title = "排行榜"
    end

    RankWidgetObject:SetRankTitle(Title)
end

function BP_RankMonument:TryInitializeRankDisplay(RetryCount)
    if self.bRankMonumentEnded == true or self.bRankDisplayInitialized == true then
        return false
    end

    RetryCount = tonumber(RetryCount) or 0
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    local RankWidgetObject = self:GetRankWidgetObject()
    local RankingListComponent = self:GetLocalRankingListComponent(PlayerController)
    local RankID = tonumber(self.RankID) or 0

    if PlayerController ~= nil and RankWidgetObject ~= nil and
        RankWidgetObject.SetRankListData ~= nil and RankingListComponent ~= nil and RankID > 0 then
        self.LocalPlayerController = PlayerController
        self.RankingListComponent = RankingListComponent
        self.bRankDisplayInitialized = true

        self:ApplyRankTitle()
        RankWidgetObject:ClearRankList()
        self:BindRankDelegates()
        self:RequestAndRefreshRankData()
        self:SchedulePeriodicRefresh()
        return true
    end

    if RetryCount >= MAX_INIT_RETRY_COUNT then
        ugcprint(string.format(
            "[BP_RankMonument] init failed: RankID=%s PlayerController=%s RankWidget=%s RankingListComponent=%s",
            tostring(RankID), tostring(PlayerController ~= nil), tostring(RankWidgetObject ~= nil),
            tostring(RankingListComponent ~= nil)))
        return false
    end

    UGCTimerUtility.CreateLuaTimer(INIT_RETRY_INTERVAL, function()
        if UE.IsValid(self) and self.bRankMonumentEnded ~= true then
            self:TryInitializeRankDisplay(RetryCount + 1)
        end
    end, false)
    return false
end

function BP_RankMonument:BindRankDelegates()
    if self.bRankDelegatesBound == true then
        return
    end

    local GlobalActor = UGCGamePartSystem.GetGamePartGlobalActor("RankingListManager")
    if not UE.IsValid(GlobalActor) then
        return
    end

    if GlobalActor.ShowRankDataChangeDelegate ~= nil then
        GlobalActor.ShowRankDataChangeDelegate:Add(self.OnRankDataChanged, self)
    end
    if GlobalActor.ProfileDataChangeDelegate ~= nil then
        GlobalActor.ProfileDataChangeDelegate:Add(self.OnRankProfileDataChanged, self)
    end

    self.RankingListGlobalActor = GlobalActor
    self.bRankDelegatesBound = true
end

function BP_RankMonument:UnbindRankDelegates()
    if self.bRankDelegatesBound ~= true then
        return
    end

    local GlobalActor = self.RankingListGlobalActor
    if UE.IsValid(GlobalActor) then
        if GlobalActor.ShowRankDataChangeDelegate ~= nil then
            GlobalActor.ShowRankDataChangeDelegate:Remove(self.OnRankDataChanged, self)
        end
        if GlobalActor.ProfileDataChangeDelegate ~= nil then
            GlobalActor.ProfileDataChangeDelegate:Remove(self.OnRankProfileDataChanged, self)
        end
    end

    self.RankingListGlobalActor = nil
    self.bRankDelegatesBound = false
end

function BP_RankMonument:RequestRankData()
    local PlayerController = self.LocalPlayerController
    local Component = self.RankingListComponent
    local RankID = tonumber(self.RankID) or 0
    local RankingCycles = self:GetRankingCycles()
    if PlayerController == nil or Component == nil or RankID <= 0 then
        return false
    end

    -- 官方封装在本地权威端会多传一个 PlayerController，导致参数错位；这里直接调用服务端函数。
    if PlayerController.HasAuthority ~= nil and PlayerController:HasAuthority() then
        if Component.Server_RequestRankListData ~= nil then
            Component:Server_RequestRankListData(RankID, 1, MAX_RANK_COUNT, RankingCycles)
            return true
        end
    elseif Component.RequestRankingListDataByRankID ~= nil then
        Component:RequestRankingListDataByRankID(RankID, 1, MAX_RANK_COUNT, RankingCycles)
        return true
    end

    return false
end

function BP_RankMonument:GetPlayerDisplayName(UID)
    local Component = self.RankingListComponent
    local RankID = tonumber(self.RankID) or 0
    if Component == nil or UID == nil then
        return "加载中..."
    end

    local ProfileData = SafeCall(Component, "GetProfileDataByUID", RankID, UID)
    if type(ProfileData) ~= "table" or next(ProfileData) == nil then
        return "加载中..."
    end

    local SelfUID = SafeCall(Component, "GetSelfUID")
    local bUseProfileShowName = ProfileData.IsAnonymous == true or ProfileData.IsHided == true or
        tonumber(SelfUID) == tonumber(UID)
    if not bUseProfileShowName then
        local PrivacyState = SafeCall(Component, "GetPrivacySettingByUID", UID)
        if tonumber(PrivacyState) == 1 then
            return "隐藏玩家"
        end
    end

    if IsNonEmptyString(ProfileData.ShowName) then
        return tostring(ProfileData.ShowName)
    end
    if IsNonEmptyString(ProfileData.PlayerName) then
        return tostring(ProfileData.PlayerName)
    end
    return "加载中..."
end

function BP_RankMonument:FormatRankScore(Score)
    if tonumber(self.RankID) == ZHANLI_RANK_ID and Ma_NumShow ~= nil and Ma_NumShow.Format ~= nil then
        return Ma_NumShow.Format(Score)
    end
    return Score
end

function BP_RankMonument:BuildDisplayEntries(RankData)
    local Entries = {}
    if type(RankData) ~= "table" then
        return Entries
    end

    local Count = math.min(#RankData, MAX_RANK_COUNT)
    for Index = 1, Count do
        local RawEntry = RankData[Index]
        if RawEntry ~= nil then
            Entries[Index] = {
                Rank = tonumber(RawEntry.Rank) or Index,
                UID = RawEntry.UID,
                PlayerName = self:GetPlayerDisplayName(RawEntry.UID),
                Score = self:FormatRankScore(RawEntry.Score or 0),
            }
        end
    end
    return Entries
end

function BP_RankMonument:RefreshRankData()
    local Component = self.RankingListComponent
    local RankWidgetObject = self:GetRankWidgetObject()
    local RankID = tonumber(self.RankID) or 0
    local RankingCycles = self:GetRankingCycles()
    if Component == nil or RankWidgetObject == nil or RankWidgetObject.SetRankListData == nil or RankID <= 0 then
        return false
    end

    local RankData = SafeCall(Component, "GetRankListData", RankID, RankingCycles)
    if type(RankData) ~= "table" then
        return false
    end

    local Entries = self:BuildDisplayEntries(RankData)
    RankWidgetObject:SetRankListData(Entries)
    if self.RankWidget ~= nil and self.RankWidget.RequestRedraw ~= nil then
        self.RankWidget:RequestRedraw()
    end
    return true
end

function BP_RankMonument:ScheduleDataPoll(RemainingCount)
    RemainingCount = tonumber(RemainingCount) or 0
    if RemainingCount <= 0 then
        return
    end

    UGCTimerUtility.CreateLuaTimer(DATA_POLL_INTERVAL, function()
        if UE.IsValid(self) and self.bRankMonumentEnded ~= true then
            self:RefreshRankData()
            self:ScheduleDataPoll(RemainingCount - 1)
        end
    end, false)
end

function BP_RankMonument:RequestAndRefreshRankData()
    self:RequestRankData()
    self:RefreshRankData()
    self:ScheduleDataPoll(DATA_POLL_COUNT)
end

function BP_RankMonument:SchedulePeriodicRefresh()
    UGCTimerUtility.CreateLuaTimer(PERIODIC_REFRESH_INTERVAL, function()
        if UE.IsValid(self) and self.bRankMonumentEnded ~= true then
            self:RequestAndRefreshRankData()
            self:SchedulePeriodicRefresh()
        end
    end, false)
end

function BP_RankMonument:OnRankDataChanged(RankID, RankingCycles)
    if tonumber(RankID) == tonumber(self.RankID) and
        tonumber(RankingCycles) == self:GetRankingCycles() then
        self:RefreshRankData()
    end
end

function BP_RankMonument:OnRankProfileDataChanged(RankID)
    if tonumber(RankID) == tonumber(self.RankID) then
        self:RefreshRankData()
    end
end

return BP_RankMonument
