---@class SignInEventComponent_C:ActorComponent
---@field MainUIPath FSoftClassPath
---@field TestButtonPath FSoftClassPath
---@field ConfigTablePath FSoftObjectPath
---@field ShowTestButton bool
---@field SignInEventData TArray<FFSignInEventData__pf601935175>
--Edit Below--

UGCGameSystem.UGCRequire("ExtendResource.SignInEvent.OfficialPackage." .. "Script.SignInEvent.SignInEventManager");
UGCGameSystem.UGCRequire("ExtendResource.SignInEvent.OfficialPackage." .. "Script.Common.Common");

local Delegate = UGCGameSystem.UGCRequire("common.Delegate");
local STExtraGMDelegatesMgr = KismetLibrary.New("/Script/ShadowTrackerExtra.STExtraGMDelegatesMgr");

local SignInEventComponent = 
{
    MainUI = nil;

    LocalEventDatas = {};
    OnConfigDataLoaded = Delegate.New();
    OnUpdateSignInEventDataDelegate = Delegate.New();

    NextRefreshTime = 0;

    VirtualItemManager = nil;
}

function SignInEventComponent:ReceiveBeginPlay()

    local Authority = self:GetOwner():HasAuthority();

    if Authority == true then

        if STExtraGMDelegatesMgr ~= nil then
            self.bLoadData = true;
            STExtraGMDelegatesMgr.GetInstance().OnPlayerPostLoginDelegate:AddInstance(self.RefreshSignInData, self);
        end
        
        self:SetNextHourRefreshTime();
        self.RefreshTimer = Timer.InsertTimer(
            1, 
            function ()
                if self ~= nil then
                    self:HourRefresh(); 
                end
            end,
            true
        );

        self:ReadConfigTable();
    else
        self.InitUIDelegate = ObjectExtend.CreateDelegate(self, self.InitUI, self);
        STExtraBlueprintFunctionLibrary.GetAssetByAssetReferenceAsync(self.MainUIPath, self.InitUIDelegate, false);
        
        Common.LoadObjectWithSoftPathAsync(self.ConfigTablePath, 
            function (Asset)
                if self ~= nil then
                    self:ReadConfigTable();
                end
            end
        );
    end

    SignInEventManager:RegisterComponentClass(GameplayStatics.GetObjectClass(self));
    
    UGCGenericMessageSystem.ListenGlobalMessage(self, UGCGenericMessageSystem.Messages.UGC.GamePart.GamePartLoadedForPlayer, self, self.SetVirtualItemManager);
end

function SignInEventComponent:ReceiveEndPlay()
    
    if self.VirtualItemManager ~= nil then
        if self:GetOwner():HasAuthority() == false then
            self.VirtualItemManager.AddItemResultDelegate:Remove(self.OnAddVirtualItem, self);
        end
    end

    if self.RefreshTimer ~= nil then
        Timer.RemoveTimer(self.RefreshTimer);
        self.RefreshTimer = nil;
    end
end

function SignInEventComponent:CheckEventDurationTime(bRefresh)

    print("[SignInEventComponent:CheckEventDurationTime] Start check");

    if bRefresh == true then
        print("[SignInEventComponent:CheckEventDurationTime] Refresh MainUI");
        self:RefreshMainUI(); 
    end

    local CurrentDate = Common.GetCurrentDate();
    local SecToNextMinute = 60 - CurrentDate.sec + 1;
    self.CheckEventDurationTimer = Timer.InsertTimer(SecToNextMinute,
        function ()
            if self ~= nil then
                self:CheckEventDurationTime(true); 
            end
        end,
        false
    );
end

function SignInEventComponent:SetVirtualItemManager()
    
    print("[SignInEventComponent:SetVirtualItemManager] Start set VirtualItemManager");

    self.VirtualItemManager = UGCBlueprintFunctionLibrary.GetGamePartGlobalActor(UGCGameSystem.GameState, "VirtualItemManager");

    -- if self:GetOwner():HasAuthority() == false then
    --     self.VirtualItemManager.AddItemResultDelegate:Add(self.OnAddVirtualItem, self);
    -- end
end

function SignInEventComponent:RefreshSignInData()
    
    print("[SignInEventComponent:RefreshSignInData]: Start Refresh");

    local EventData = self:ReadData();
    local CurrentTime = Common.GetCurrentTime();
    local bRefreshed = false;
    local bValueChanged = false;

    -- 月、周、日刷新
    for EventID, Data in pairs(EventData) do  
        local ConfigData = SignInEventManager:GetEventConfigData(EventID);
        if ConfigData.Type ~= ESignInEventType.OneOff and CurrentTime >= Data.NextRefreshTime then
            bValueChanged = bValueChanged or Data.DayNum ~= 0;
            EventData[EventID].DayNum = 0;
            bRefreshed = true;
        end
    
        if CurrentTime >= Data.NextDayTime then
            bValueChanged = bValueChanged or Data.SupplementDayNum ~= 0;
            EventData[EventID].SupplementDayNum = 0;
            bRefreshed = true;
        end
    end

    if bRefreshed == true then
        print("[SignInEventComponent:RefreshSignInData]: Data Refreshed");
        -- 重置逻辑优化，避免后台过载
        -- self:WriteData(EventData);
        self.CachedEventData = EventData        
        self:SetSignInEventData(EventData);
        
        if bValueChanged == false then
            UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "RefreshMainUI");
        end
    elseif self.bLoadData == true then
        self:SetSignInEventData(EventData);
        self.bLoadData = false;
    end
end

function SignInEventComponent:InitUI()

    if self.MainUIPath == nil then
        print("[SignInEventComponent:InitUI] MainUIPath is nil!");
        return;
    end

    local MainUIClass = UE.LoadClass(KismetSystemLibrary.BreakSoftClassPath(self.MainUIPath));
    if MainUIClass == nil then
        print("[SignInEventComponent:InitUI] MainUIClass is nil!");
        return;
    end

    self.MainUI = UserWidget.NewWidgetObjectBP(self:GetOwner(), MainUIClass);
    self.MainUI:AddToViewport(15000);
    self.MainUI:SetVisibility(ESlateVisibility.Collapsed);

    if self.MainUI.AutoOpen == true then
        self.OnConfigDataLoaded:Add(self.OpenUI, self);
    end

    if self.ShowTestButton == true then
        local ButtonClass = Common.GetClassWithSoftPath(self.TestButtonPath);

        if ButtonClass ~= nil then
            local Button = UserWidget.NewWidgetObjectBP(self:GetOwner(), ButtonClass);
            Button:AddToViewport(10000); 
        end
    end
end

function SignInEventComponent:OpenUI()
    
    if self.MainUI ~= nil then
        self.MainUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        -- self.MainUI:RefreshContent();
        self.MainUI:Refresh();

        self:CheckEventDurationTime(false);
        self.OnUpdateSignInEventDataDelegate:Add(self.RefreshMainUI, self);

        self.VirtualItemManager.AddItemResultDelegate:Add(self.OnAddVirtualItem, self);
    end
end

function SignInEventComponent:CloseUI()

    if self.MainUI ~= nil then
        self.MainUI:SetVisibility(ESlateVisibility.Collapsed);
        
        Timer.RemoveTimer(self.CheckEventDurationTimer);
        self.OnUpdateSignInEventDataDelegate:Remove(self.RefreshMainUI, self);

        self.VirtualItemManager.AddItemResultDelegate:Remove(self.OnAddVirtualItem, self);
    end
end

function SignInEventComponent:RefreshMainUI()
    
    if self.MainUI ~= nil and self.MainUI:GetIsVisible() == true then
        self.MainUI:Refresh();
    end
end

function SignInEventComponent:ShowTip(ItemID, Position)
    
    if self.MainUI ~= nil then
        self.MainUI:ShowTip(ItemID, Position);
    end
end

function SignInEventComponent:ShowSupplementPopup(EventID, ItemID, Num)

    if self.MainUI ~= nil then
        self.MainUI:ShowSupplementPopUp(EventID, ItemID, Num);
    end
end

function SignInEventComponent:ShowSupplementTip(Message)
    
    if self.MainUI ~= nil then
        self.MainUI:ShowSupplementTip(Message);
    end
end

function SignInEventComponent:ShowItemGetPopup(ItemID, Num)
    
    if self.MainUI ~= nil then
        self.MainUI:ShowItemGetPopup(ItemID, Num);
    end
end

function SignInEventComponent:SetNextHourRefreshTime()
    
    local CurrentTime = os.date("*t", Common.GetCurrentTime(false));
    self.NextRefreshTime = os.time({year=CurrentTime.year, month=CurrentTime.month, day=CurrentTime.day, hour=CurrentTime.hour});
    self.NextRefreshTime = self.NextRefreshTime + 60 * 60;
end

function SignInEventComponent:HourRefresh()
    
    if self:GetOwner():HasAuthority() == true then
        local CurrentTime = Common.GetCurrentTime(false);
        if CurrentTime >= self.NextRefreshTime then
            self:RefreshSignInData();
            self:SetNextHourRefreshTime();
        end 
    end
end

function SignInEventComponent:ReadData()
    
    if self:GetOwner():HasAuthority() == false then
        return;
    end

    if self.CachedEventData ~= nil then
        return self.CachedEventData
    end

    local UID = self:GetOwner():GetInt64UID();

    print(string.format("SignInEventComponent: Begin read UID:%d PlayerData", UID));

    local PlayerData = UGCPlayerStateSystem.GetPlayerArchiveData(UID);

    if PlayerData == nil then
        print(string.format("SignInEventComponent:UID:%d PlayerData is empty, creating new one.", UID))

        PlayerData = {
            SignInEvent = {}
        };

        UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData);
    end

    if PlayerData["SignInEvent"] == nil then
        print(string.format("SignInEventComponent:UID:%d SignInEvent data is empty, creating new one.", UID))
        
        PlayerData["SignInEvent"] = {};

        UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData);
    end

    print(string.format("SignInEventComponent:Read UID:%d PlayerData Success", UID));

    self.CachedEventData = PlayerData["SignInEvent"]

    -- return PlayerData["SignInEvent"];
    return self.CachedEventData
end

function SignInEventComponent:WriteData(Data)
    
    local UID = self:GetOwner():GetInt64UID();
    local PlayerData = UGCPlayerStateSystem.GetPlayerArchiveData(UID);
    PlayerData["SignInEvent"] = Data;

    print(string.format("SignInEventComponent: Begin write UID:%d PlayerData", UID));

    local bSuccess = UGCPlayerStateSystem.SavePlayerArchiveData(UID, PlayerData);
    if bSuccess == true then
        print(string.format("SignInEventComponent: Write UID:%d PlayerData Success", UID));
        self.CachedEventData = Data
    else
        print(string.format("SignInEventComponent: Write UID:%d PlayerData Failed", UID));
    end
end

function SignInEventComponent:SetSignInEventData(EventData)
    
    self.SignInEventData:Empty();

    for EventID, Data in pairs(EventData) do
        local EventData = {};
        EventData.EventID = EventID;
        EventData.DayNum = Data.DayNum;
        EventData.SupplementDayNum = Data.SupplementDayNum;
        EventData.NextDayTime = Data.NextDayTime;

        self.SignInEventData:Add(EventData);
    end
end

function SignInEventComponent:GetEventData(EventID)
    
    if self:GetOwner():HasAuthority() == false then   
        if self.LocalEventDatas[EventID] == nil then
            self.LocalEventDatas[EventID] = {};
            self.LocalEventDatas[EventID].DayNum = 0;
            self.LocalEventDatas[EventID].NextDayTime = 0;
            self.LocalEventDatas[EventID].SupplementDayNum = 0;
        end

        return self.LocalEventDatas[EventID];
    else
        local EventData = self:ReadData()[EventID];
        if EventData == nil then
            EventData = {};
            EventData.DayNum = 0;
            EventData.NextDayTime = 0;
            EventData.SupplementDayNum = 0;
        end

        return EventData;
    end
end

function SignInEventComponent:GetEventDayNum(EventID)
    
    if self:GetOwner():HasAuthority() == false then        
        return self.LocalEventDatas[EventID] == nil and 0 or self.LocalEventDatas[EventID].DayNum;
    else
        local EventData = self:ReadData()[EventID];
        return EventData == nil and 0 or EventData.DayNum;
    end
end

function SignInEventComponent:GetEventNextDayTime(EventID)
    
    if self:GetOwner():HasAuthority() == false then        
        return self.LocalEventDatas[EventID] == nil and 0 or self.LocalEventDatas[EventID].NextDayTime;
    else
        local EventData = self:ReadData()[EventID];
        return EventData == nil and 0 or EventData.NextDayTime;
    end
end

function SignInEventComponent:GetEventSupplementDayNum(EventID)
    
    if self:GetOwner():HasAuthority() == false then
        return self.LocalEventDatas[EventID] == nil and 0 or self.LocalEventDatas[EventID].SupplementDayNum;
    else
        local EventData = self:ReadData()[EventID];
        return EventData == nil and 0 or EventData.SupplementDayNum;
    end
end

function SignInEventComponent:OnRep_SignInEventData()
    
    print("[SignInEventComponent] SignInEventData Replicated!");

    self.LocalEventDatas = {};

    for _, EventData in ipairs(self.SignInEventData) do
        self.LocalEventDatas[EventData.EventID] = {};
        self.LocalEventDatas[EventData.EventID].DayNum = EventData.DayNum;
        self.LocalEventDatas[EventData.EventID].NextDayTime = EventData.NextDayTime;
        self.LocalEventDatas[EventData.EventID].SupplementDayNum = EventData.SupplementDayNum;
    end

    self.OnUpdateSignInEventDataDelegate(self.LocalEventDatas);
end

function SignInEventComponent:GetDailySignInAward(EventID)
    
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_GetDailySignInAward", EventID, self:GetEventData(EventID));
end

function SignInEventComponent:UseSupplement(EventID)
    
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_UseSupplement", EventID, self:GetEventData(EventID));
end

function SignInEventComponent:GetSignInAward(EventID, LocalEventDatas)
    print("[SignInEventComponent] GetSignInAward");

    if not self:GetOwner():HasAuthority() then
        print("[SignInEventComponent] GetSignInAward cannot be called on client!")
        return
    end

    local Config = SignInEventManager:GetEventConfigData(EventID);
    if Common.CheckStartEndTime(Config.StartTime, Config.EndTime) == false and Config.EndTime ~= 0 then
        print("[SignInEventComponent] StartDate or EndDate validation failed!]");
        return;
    end

    local Data = self:ReadData();

    if Data[EventID] ~= nil then
        --校验客户端ds数据一致性
        if Data[EventID].DayNum ~= LocalEventDatas.DayNum
        or Data[EventID].NextDayTime ~= LocalEventDatas.NextDayTime
        or Data[EventID].SupplementDayNum ~= LocalEventDatas.SupplementDayNum then
            print("[SignInEventComponent:GetSignInAward] LocalEventData does not match with ds EventData")
            return
        end
    else
        Data[EventID] = { DayNum=0, NextDayTime=0, SupplementDayNum = 0, NextRefreshTime = 0};
    end

    --校验是否已到最大累计签到天数
    if Data[EventID].DayNum == #Config.Awards then
        print("[SignInEventComponent] Reach max DayNum")
        return
    end

    Data[EventID].DayNum = Data[EventID].DayNum + 1;

    if Common.GetCurrentTime() < Data[EventID].NextDayTime then
        Data[EventID].SupplementDayNum = Data[EventID].SupplementDayNum + 1;
    end

    local CurrentDate = Common.GetCurrentDate();
    local NextDayTime = os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=0}) +  24 * 60 * 60;
    if Config.Type ~= ESignInEventType.OneOff then
        Data[EventID].NextDayTime = NextDayTime
    elseif Data[EventID].DayNum < #Config.Awards then
        --一次性签到未完成时才需要更新NextDayTime
        Data[EventID].NextDayTime = NextDayTime
    else
        Data[EventID].NextDayTime = math.huge
    end

    if Config.Type == ESignInEventType.Monthly then
        local NextMonth = CurrentDate.month % 12 + 1
        local YearIncreasement = NextMonth == 1 and 1 or 0;
        Data[EventID].NextRefreshTime = os.time({year=CurrentDate.year + YearIncreasement, month=NextMonth, day=1, hour=0});
    elseif Config.Type == ESignInEventType.Weekly then
        local WeekDay = CurrentDate.wday - 1;
        WeekDay = WeekDay == 0 and 7 or WeekDay;
        local NextRefreshTime = os.time({year=CurrentDate.year, month=CurrentDate.month, day=CurrentDate.day, hour=0});
        Data[EventID].NextRefreshTime = NextRefreshTime + (8 - WeekDay) * 24 * 60 * 60;
    end

    self:WriteData(Data);

    -- 同步到客户端
    self:SetSignInEventData(Data);

    local Award = Config.Awards[Data[EventID].DayNum];

    self.VirtualItemManager:AddVirtualItem(self:GetOwner(), Award.ItemID, Award.ItemNum);
end

function SignInEventComponent:Server_GetDailySignInAward(EventID, LocalEventDatas)
    local Data = self:ReadData();
    if Data[EventID] == nil then
        Data[EventID] = { DayNum=0, NextDayTime=0, SupplementDayNum = 0, NextRefreshTime = 0};
    end

    --校验当日是否已经进行签到
    if UGCGameSystem.GetServerTimeSec() < Data[EventID].NextDayTime then
        print("[SignInEventComponent] Daily award already claimed!")
        return
    end

    self:GetSignInAward(EventID, LocalEventDatas)
end

function SignInEventComponent:Server_UseSupplement(EventID, LocalEventDatas)
    local ConfigData = SignInEventManager:GetEventConfigData(EventID)

    local Data = self:ReadData();
    if Data[EventID] ~= nil then
        --校验客户端ds数据一致性
        if Data[EventID].DayNum ~= LocalEventDatas.DayNum
        or Data[EventID].NextDayTime ~= LocalEventDatas.NextDayTime
        or Data[EventID].SupplementDayNum ~= LocalEventDatas.SupplementDayNum then
            print("[SignInEventComponent:Server_UseSupplement] LocalEventData does not match with ds EventData")
            return
        end
    else
        Data[EventID] = { DayNum=0, NextDayTime=0, SupplementDayNum = 0, NextRefreshTime = 0};
    end

    if Common.GetCurrentTime() >= Data[EventID].NextDayTime then
        UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "ShowSupplementTip", "签到已刷新，请重新签到")
        return
    end

    --校验补签天数是否到达上限
    if Data[EventID].SupplementDayNum >= ConfigData.SupplementDay then
        print("[SignInEventComponent] Reach max daily supplement day num!")
        return
    end

    local SupplementItemNum = self.VirtualItemManager:GetItemNum(ConfigData.SupplementItemID, self:GetOwner());
    if SupplementItemNum >= ConfigData.SupplementItemNum then
        self:Server_RemoveItem(ConfigData.SupplementItemID, ConfigData.SupplementItemNum,
            function (Result)
                if Result.bSucceeded then
                    self:GetSignInAward(EventID, LocalEventDatas); 
                end
            end
        );
    end
end

function SignInEventComponent:ReadConfigTable()
    
    if self.ConfigTablePath == nil then
        print("SignInEventComponent: ConfigTablePath is nil!");
        return;
    end

    local Table = UGCGameSystem.GetTableData(Common.GetDataTablePath(self.ConfigTablePath));

    SignInEventManager.ConfigDatas = {};

    local EventCnt = 0;
    local Cnt = 0;
    for _, Data in pairs(Table) do
        local ConfigData = {};

        ConfigData.EventID           = Data.EventID;
        ConfigData.EventName         = Data.EventName;
        ConfigData.Type              = Data.Type;
        ConfigData.StartTime         = Common.GetTimestampFromDateTime(Data.StartTime);
        ConfigData.EndTime           = Common.GetTimestampFromDateTime(Data.EndTime);
        ConfigData.Desc              = Data.Desc;
        ConfigData.SupplementDay     = Data.SupplementDay;
        ConfigData.SupplementItemID  = Data.SupplementItemID;
        ConfigData.SupplementItemNum = Data.SupplementItemNum;
        ConfigData.Highlight7thDay   = Data.HighLight7thDay;

        Common.LoadObjectWithSoftPathAsync(Data.AwardTablePath, 
            function (Asset)
                if self ~= nil then
                    ConfigData.Awards = self:ReadAwardTable(Data.AwardTablePath);
                    Cnt = Cnt + 1;
                    if Cnt == EventCnt then
                        self.OnConfigDataLoaded();
                    end
                end
            end
        )

        SignInEventManager.ConfigDatas[Data.EventID] = ConfigData;
        EventCnt = EventCnt + 1;
    end
end

function SignInEventComponent:ReadAwardTable(TablePath)

    if TablePath == nil then
        print("SignInEventComponent: AwardTablePath is nil!");
        return nil;
    end

    local Table = UGCGameSystem.GetTableData(Common.GetDataTablePath(TablePath));

    local AwardDatas = {};
    local Count = 1;
    for DayName, Data in pairs(Table) do
        local Award = {};
        
        Award.DayName  = DayName;
        Award.DayIndex = Count;
        Award.ItemID   = Data.ItemID;
        Award.ItemNum  = Data.ItemNum;

        table.insert(AwardDatas, Award);
        Count = Count + 1;
    end

    return AwardDatas;
end

function SignInEventComponent:GetAvailableServerRPCs()
    return
        "Server_GetDailySignInAward",
        "Server_ClearData",
        "Server_AddItem",
        "Server_RemoveItem",
        "Server_UseSupplement";
end

function SignInEventComponent:ClearData()
    
    print("[SignInEventComponent:ClearData] Request clear data");
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_ClearData");
end

function SignInEventComponent:Server_ClearData()
    
    print("[SignInEventComponent:ClearData] Clear player data");

    local EventData = self:ReadData();

    for EventID, Data in pairs(EventData) do
        EventData[EventID].DayNum = 0;
        EventData[EventID].SupplementDayNum = 0;
        EventData[EventID].NextDayTime = 0;
        EventData[EventID].NextRefreshTime = 0;
    end

    self:WriteData(EventData);
    self:SetSignInEventData(EventData);
end

function SignInEventComponent:AddItem(ItemID, Num)
    
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_AddItem", ItemID, Num);
end

function SignInEventComponent:RemoveItem(ItemID, Num)
    
    UnrealNetwork.CallUnrealRPC(self:GetOwner(), self, "Server_RemoveItem", ItemID, Num);
end

function SignInEventComponent:Server_AddItem(ItemID, Num)
    
    if self.VirtualItemManager == nil then
        return;
    end

    print(string.format("[SignInEventComponent:Server_AddItem] Add %d %d", ItemID, Num));

    self.VirtualItemManager:AddVirtualItem(self:GetOwner(), ItemID, Num);
end

function SignInEventComponent:Server_RemoveItem(ItemID, Num, Callback)
    
    if self.VirtualItemManager == nil then
        return;
    end

    print(string.format("[SignInEventComponent:Server_AddItem] Remove %d %d", ItemID, Num));

    self.VirtualItemManager:RemoveItem(self:GetOwner(), ItemID, Num, Callback);
end

function SignInEventComponent:GetItemNum(ItemID)
    
    if self.VirtualItemManager == nil then
        return 0;
    end

    return self.VirtualItemManager:GetItemNum(ItemID);
end

function SignInEventComponent:OnAddVirtualItem(Result)
    
    if Result.bSucceeded == false then
        return;
    end

    if self.MainUI and self.MainUI.SupplementPopUp then
        --避免弱网情况，第二次打开补签弹窗的情况下，第一次补签成功后的重复补签
        self.MainUI.SupplementPopUp:SetVisibility(ESlateVisibility.Collapsed)
    end

    for ItemID, Num in pairs(Result.ItemList) do
        self:ShowItemGetPopup(ItemID, Num);
        return;
    end
end

return SignInEventComponent