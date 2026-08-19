---@class SignInEvent_Main_UIBP_C:UUserWidget
---@field CloseButton UNewButton
---@field Content UDynaCanvasPanel
---@field HelpButton UButton
---@field PeriodText UTextBlock
---@field SimpleText UTextBlock
---@field TabMenu UGC_ReuseList2_C
---@field TileText UTextBlock
---@field AutoOpen bool
---@field Tabs ULuaArrayHelper<FFEventTabInfo__pf2420962350>
---@field TipUIClassPath FSoftClassPath
---@field SupplementPopUpPath FSoftClassPath
---@field SupplementTipPath FSoftClassPath
---@field ItemGetPopupPath FSoftClassPath
---@field RulePopupPath FSoftClassPath
--Edit Below--
local SignInEvent_Main_UIBP = 
{ 
    bInitDoOnce = false;

    TabButtons = {};
    ValidTabs = nil;

    AvailableTabButton = nil;
    Tip = nil;
    SupplementPopUp = nil;
    SupplementTip = nil;
    ItemGet = nil;
    RuleTip = nil;
    SelectedEventID = -1;
} 

function SignInEvent_Main_UIBP:Construct()
    
    self:BindEvent();
    self:PreLoadUI();
end

function SignInEvent_Main_UIBP:PreLoadUI()
    
    Common.LoadObjectWithSoftPathAsync(self.TipUIClassPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(self);
                self.Tip = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                self.Tip:AddToViewport(20000);
                self.Tip:SetVisibility(ESlateVisibility.Collapsed);
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.SupplementPopUpPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(self);
                self.SupplementPopUp = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                self.SupplementPopUp:AddToViewport(20000);
                self.SupplementPopUp:SetVisibility(ESlateVisibility.Collapsed);
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.SupplementTipPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(self);
                self.SupplementTip = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                self.SupplementTip:AddToViewport(20000);
                self.SupplementTip:SetVisibility(ESlateVisibility.Collapsed);
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.ItemGetPopupPath, 
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(self);
                self.ItemGet = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                self.ItemGet:AddToViewport(20000);
                self.ItemGet:SetVisibility(ESlateVisibility.Collapsed);
            end
        end
    );

    Common.LoadObjectWithSoftPathAsync(self.RulePopupPath,
        function (Object)
            if self ~= nil and Object ~= nil then
                local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(self);
                self.RuleTip = UserWidget.NewWidgetObjectBP(PlayerController, Object);
                self.RuleTip:AddToViewport(20000);
                self.RuleTip:SetVisibility(ESlateVisibility.Collapsed);
            end 
        end
    )
end

function SignInEvent_Main_UIBP:BindEvent()
    
    self.TabMenu.OnUpdateItem:Add(self.RefreshTabMenuButton, self);
    self.CloseButton.OnClicked:Add(self.Close, self);
    self.HelpButton.OnClicked:Add(self.HelpClick, self);
end

function SignInEvent_Main_UIBP:Close()

    self:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_Main_UIBP:HelpClick()
    
    local ConfigData = SignInEventManager:GetEventConfigData(self.SelectedEventID);
    self:ShowRuleTip(ConfigData.Desc);
end

function SignInEvent_Main_UIBP:Refresh()
    
    print("[SignInEvent_Main_UIBP:Refresh] Start Refresh");

    self.ValidTabs = {};

    local CurrentTime = Common.GetCurrentTime();
    for _, Tab in ipairs(self.Tabs) do
        local Config = SignInEventManager:GetEventConfigData(Tab.EventID);

        if CurrentTime >= Config.StartTime and CurrentTime < Config.EndTime then
            table.insert(self.ValidTabs, Tab:Copy());
        elseif self.SelectedEventID == Tab.EventID then
            self.SelectedEventID = -1;
        end
    end

    if #self.ValidTabs == 0 then
        print("[SignInEvent_Main_UIBP:Refresh] No SignInEvent yet!");
        self:SetVisibility(ESlateVisibility.Collapsed);
    end

    if #self.ValidTabs > 0 then
        if self.SelectedEventID == -1 then
            self.SelectedEventID = self.ValidTabs[1].EventID;
            self.bShowPeriod = self.ValidTabs[1].ShowPeriod;
        end
        self:RefreshContent();
    end

    self.TabMenu:Reload(#self.ValidTabs);
end

function SignInEvent_Main_UIBP:RefreshContent()

    self:Reset();

    local ConfigData = SignInEventManager:GetEventConfigData(self.SelectedEventID);

    self.Content:SetAllDynaWidgetVisibility(ESlateVisibility.Collapsed);

    if ConfigData.Type == ESignInEventType.Weekly or ConfigData.Type == ESignInEventType.OneOff then
        local WeeklyUI = self.Content:GetDynaWidget("Weekly");
        WeeklyUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        WeeklyUI:Refresh(self.SelectedEventID);
    elseif ConfigData.Type == ESignInEventType.Monthly then
        local MonthlyUI = self.Content:GetDynaWidget("Monthly");
        MonthlyUI:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
        MonthlyUI:Refresh(self.SelectedEventID);
    end

    -- 标题刷新
    local Title = "";
    if ConfigData.EventName == "" then
        if ConfigData.Type == ESignInEventType.Monthly then
            Title = string.format("%d月签到", Common.GetCurrentDate().month);
        elseif ConfigData.Type == ESignInEventType.Weekly then
            Title = string.format("每周签到");
        elseif ConfigData.Type == ESignInEventType.OneOff then
            Title = string.format("%d日签到", #ConfigData.Awards);
        end
    else
        Title = ConfigData.EventName;
    end

    -- 起止日期
    if self.bShowPeriod == true then
        self.PeriodText:SetVisibility(ESlateVisibility.HitTestInvisible);
        self.SimpleText:SetVisibility(ESlateVisibility.HitTestInvisible);

        local StartDate = os.date("*t", ConfigData.StartTime);
        local EndDate = os.date("*t", ConfigData.EndTime);
        self.PeriodText:SetText(string.format("%04d.%02d.%02d-%04d.%02d.%02d", 
                                StartDate.year, StartDate.month, StartDate.day, EndDate.year, EndDate.month, EndDate.day));
    end

    if ConfigData.Desc ~= "" then
        self.HelpButton:SetVisibility(ESlateVisibility.Visible);
    end

    self.TileText:SetText(Title);
end

function SignInEvent_Main_UIBP:Reset()
    
    self.PeriodText:SetVisibility(ESlateVisibility.Collapsed);
    self.SimpleText:SetVisibility(ESlateVisibility.Collapsed);
    self.HelpButton:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_Main_UIBP:RefreshTabMenuButton(TabButton, Idx)

    TabButton.EventID = self.ValidTabs[Idx+1].EventID;
    TabButton.bShowPeriod = self.ValidTabs[Idx+1].ShowPeriod;
    TabButton:SetTabName(self.ValidTabs[Idx+1].TabName);

    if self.SelectedEventID == -1 then
        self.SelectedEventID = TabButton.EventID;
    end

    if TabButton.EventID == self.SelectedEventID then
        TabButton:Select();
        self.bShowPeriod = TabButton.bShowPeriod;
        self:RefreshContent();
    else
        TabButton:Deselect();
    end
    
    TabButton:ShouldShowRedDot(Common.GetCurrentTime() > SignInEventManager:GetEventData(TabButton.EventID).NextDayTime);

    self.TabButtons[TabButton.EventID] = TabButton;
end

function SignInEvent_Main_UIBP:SelectEvent(EventID)
    
    if EventID == self.SelectedEventID then
        return;
    end

    self.TabButtons[EventID]:Select();
    self.TabButtons[self.SelectedEventID]:Deselect();
    self.SelectedEventID = EventID;
    self.bShowPeriod = self.TabButtons[self.SelectedEventID].bShowPeriod;

    self:RefreshContent();
end

function SignInEvent_Main_UIBP:ShowTip(ItemID, Position)

    self.Tip:Refresh(ItemID, Position);
    self.Tip:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
end

function SignInEvent_Main_UIBP:ShowSupplementPopUp(EventID, ItemID, Num)
    
    self.SupplementPopUp:Refresh(EventID, ItemID, Num);
    self.SupplementPopUp:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
end

function SignInEvent_Main_UIBP:ShowSupplementTip(Message)
    
    self.SupplementTip:SetVisibility(ESlateVisibility.HitTestInvisible);
    self.SupplementTip:ShowMessageTip(Message);
end

function SignInEvent_Main_UIBP:ShowItemGetPopup(ItemID, Num, ExtraItemID, ExtraNum)
    
    self.ItemGet:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.ItemGet:Popup(ItemID, Num, ExtraItemID, ExtraNum);
end

function SignInEvent_Main_UIBP:ShowRuleTip(Text)
    
    self.RuleTip:SetVisibility(ESlateVisibility.SelfHitTestInvisible);
    self.RuleTip:Refresh(Text);
end

return SignInEvent_Main_UIBP
