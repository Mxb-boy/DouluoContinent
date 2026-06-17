---@class SignInEvent_WeeklyMode_UIBP_C:UUserWidget
---@field ItemList UGC_ReuseList2_C
--Edit Below--
local SignInEvent_WeeklyMode_UIBP = 
{ 
    bInitDoOnce = false;
    
    EventID = 0;
    SupplementDay = 0;
    MaxDay = 0;

    LastScrollOffset = 0;
    bScrollRight = false;
} 

function SignInEvent_WeeklyMode_UIBP:Construct()
	
    self.ItemList.OnUpdateItem:Add(self.UpdateItem, self);
end

local function CalculateSupplementDay(EventID)

    local Config = SignInEventManager:GetEventConfigData(EventID);
    local EventData = SignInEventManager:GetEventData(EventID);
    local CurrentTime = Common.GetCurrentTime();
    local CurrentDate = os.date("*t", CurrentTime);

    -- 剩于总共能够补签的天数
    local Day = 0;
    if Config.Type == ESignInEventType.OneOff then
        local StartDate = os.date("*t", Config.StartTime);
        local Time = CurrentTime - os.time({year=StartDate.year, month=StartDate.month, day=StartDate.day, hour=0});
        local MaxDay = math.min(14, math.floor(Time / (24 * 60 * 60)) + 1);
        Day = MaxDay - (SignInEventManager:GetTodayEventDayNum(EventID) + 1);
    elseif Config.Type == ESignInEventType.Weekly then
        local WeekDay = CurrentDate.wday - 1;
        WeekDay = WeekDay == 0 and 7 or WeekDay;
        Day = WeekDay - (SignInEventManager:GetTodayEventDayNum(EventID) + 1);
    end

    return math.min(Day, Config.SupplementDay);
end

function SignInEvent_WeeklyMode_UIBP:Refresh(EventID)

    self.EventID = EventID;
    self.SupplementDay = CalculateSupplementDay(EventID);

    local Config = SignInEventManager:GetEventConfigData(EventID);
    self.MaxDay = #Config.Awards;

    if Config.Type == ESignInEventType.Weekly then
        self.MaxDay = 7;
    elseif Config.Type == ESignInEventType.OneOff then
        self.MaxDay = math.min(14, self.MaxDay);
        if self.MaxDay < 14 then
            self.MaxDay = 7;
        end

        -- 因为前面计算的是到开始日期的补签天数，可能会大于最大的天数
        self.SupplementDay = math.min(self.MaxDay, self.SupplementDay);
    end
    self.ItemList:Reload(self.MaxDay);
    
    local DayIndex = SignInEventManager:GetEventDayNum(EventID);
    if DayIndex >= 7 then
        self.ItemList:JumpByIdxStyle(7, EReuseListJumpStyle.Begin); 
    end
end

function SignInEvent_WeeklyMode_UIBP:UpdateItem(Item, Idx)

    Item:Refresh(self.EventID, Idx+1, self.SupplementDay);
end

return SignInEvent_WeeklyMode_UIBP