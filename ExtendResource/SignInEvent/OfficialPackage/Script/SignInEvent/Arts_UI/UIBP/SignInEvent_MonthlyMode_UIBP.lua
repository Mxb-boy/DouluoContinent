---@class SignInEvent_MonthlyMode_UIBP_C:UUserWidget
---@field ItemList UUGC_ReuseList2_C
--Edit Below--
local SignInEvent_MonthlyMode_UIBP = 
{ 
    bInitDoOnce = false;
    
    EventID = 0;
    SupplementDay = 0;
} 

function SignInEvent_MonthlyMode_UIBP:Construct()
	
    self.ItemList.OnUpdateItem:Add(self.UpdateItem, self);
end

local function CalculateSupplementDay(EventID)

    local Config = SignInEventManager:GetEventConfigData(EventID);
    local EventData = SignInEventManager:GetEventData(EventID);
    local CurrentTime = Common.GetCurrentTime();
    local CurrentDate = os.date("*t", CurrentTime);
    local Day = CurrentDate.day - (SignInEventManager:GetTodayEventDayNum(EventID) + 1);

    -- return math.min(Day, Config.SupplementDay) - EventData.SupplementDayNum;
    return math.min(Day, Config.SupplementDay);
end

function SignInEvent_MonthlyMode_UIBP:Refresh(EventID)

    self.EventID = EventID;
    self.SupplementDay = CalculateSupplementDay(EventID);

    local EventData = SignInEventManager:GetEventConfigData(EventID);
    self.ItemList:Reload(31);
    self.ItemList:JumpByIdx(SignInEventManager:GetEventDayNum(EventID));
end

function SignInEvent_MonthlyMode_UIBP:UpdateItem(Item, Idx)

    Item:Refresh(self.EventID, Idx+1, self.SupplementDay);
end

return SignInEvent_MonthlyMode_UIBP