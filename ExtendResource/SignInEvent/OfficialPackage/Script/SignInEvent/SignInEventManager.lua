SignInEventManager = SignInEventManager or 
{
    LocalComponent = nil;
    ConfigDatas = nil;
}

function SignInEventManager:RegisterComponentClass(CompClass)

    if CompClass ~= nil then
        self.ComponentClass = CompClass;
    end
end

function SignInEventManager:OpenMainUI()
    
    self:GetLocalComponent():OpenUI();
end

function SignInEventManager:ClearData()
    
    self:GetLocalComponent():ClearData();
end

function SignInEventManager:CloseMainUI()
    
    self:GetLocalComponent():CloseUI();
end

function SignInEventManager:SelectEvent(EventID)
    
    self:GetLocalComponent().MainUI:SelectEvent(EventID);
end

function SignInEventManager:ShowTip(ItemID, Position)
    
    self:GetLocalComponent():ShowTip(ItemID, Position);
end

function SignInEventManager:ShowSupplementPopup(EventID)
    
    local ConfigData = self.ConfigDatas[EventID];
    if ConfigData == nil then
        print("[SignInEventManager:ShowSupplementPopup] Invalid EventID");
    end

    self:GetLocalComponent():ShowSupplementPopup(EventID, ConfigData.SupplementItemID, ConfigData.SupplementItemNum);
end

function SignInEventManager:ShowSupplementTip(Message)
    
    self:GetLocalComponent():ShowSupplementTip(Message);
end

function SignInEventManager:GetDailySignInAward(EventID)
    if not self.bBlockRequest then
        self.bBlockRequest = true
        self:GetLocalComponent():GetDailySignInAward(EventID)
        UGCTimerUtility.CreateLuaTimer(1, function () self.bBlockRequest = false end)
    else
        print("[SignInEventManager:GetDailySignInAward] Too Frequent Calls")
    end
end

function SignInEventManager:UseSupplement(EventID)
    if not self.bBlockRequest then
        self.bBlockRequest = true
        self:GetLocalComponent():UseSupplement(EventID);
        UGCTimerUtility.CreateLuaTimer(1, function () self.bBlockRequest = false end)
    else
        print("[SignInEventManager:UseSupplement] Too Frequent Calls")
    end
end

function SignInEventManager:GetItemNum(ItemID)
    
    return self:GetLocalComponent():GetItemNum(ItemID);
end

--- 获取玩家的 SignInEventComponent
--- 生效范围：客户端&&服务器
function SignInEventManager:GetSignInEventComponent(PlayerController)

    if self.ComponentClass ~= nil then
        return PlayerController:GetComponentByClass(self.ComponentClass);
    else
        print("SignInEventComponentClass is nil!");
        return nil;
    end
end

--- 获取本地玩家的 SignInEventComponent
--- 生效范围：客户端
function SignInEventManager:GetLocalComponent()
    
    if self.LocalComponent == nil then
        if self.ComponentClass ~= nil and UGCGameSystem.GameState ~= nil then
            local PlayerController = STExtraGameplayStatics.GetFirstPlayerController(UGCGameSystem.GameState);
            self.LocalComponent = PlayerController:GetComponentByClass(self.ComponentClass);
        else
            print("SignInEventManager: Cannot get local component!");
        end
    end
        
    return self.LocalComponent;
end

---获取签到活动配置信息
---生效范围：客户端&&服务器
---@param EventID int @签到活动ID
---@return table
function SignInEventManager:GetEventConfigData(EventID)
    
    return self.ConfigDatas[EventID];
end

---获取签到活动累计签到天数
---生效范围：客户端&&服务器
---@param EventID int @签到活动ID
---@param PlayerController UUGCPlayerController @玩家控制器，客户端调用可以不传，即默认主控玩家控制器
---@return int
function SignInEventManager:GetEventDayNum(EventID, PlayerController)
    
    local Comp = nil;

    if PlayerController == nil then
        if UGCGameSystem.GameState:HasAuthority() == false then
            Comp = self:GetLocalComponent();
        else
            print("[SignInEventManager:GetEventDayNum] PlayerController is nil on DS");
            return 0;
        end
    else
        Comp = self:GetSignInEventComponent(PlayerController);
    end

    if Comp == nil then
        print("[SignInEventManager:GetEventDayNum] Comp is nil");
        return 0;
    end

    return Comp:GetEventDayNum(EventID);
end

function SignInEventManager:GetEventSupplementDayNum(EventID)
    
    return self:GetLocalComponent():GetEventSupplementDayNum(EventID);
end

function SignInEventManager:GetEventData(EventID)
    
    return self:GetLocalComponent():GetEventData(EventID);
end

function SignInEventManager:GetTodayEventDayNum(EventID)
    
    local EventData = self:GetLocalComponent():GetEventData(EventID);
    local DayNum = Common.GetCurrentTime() >= EventData.NextDayTime and EventData.DayNum or EventData.DayNum - 1;

    return DayNum - EventData.SupplementDayNum;
end

function SignInEventManager:GetEventNextDayTime(EventID)
    
    return self:GetLocalComponent():GetEventNextDayTime(EventID);
end

function SignInEventManager:AddItem(ItemID, Num)
    
    self:GetLocalComponent():AddItem(ItemID, Num);
end

function SignInEventManager:RemoveItem(ItemID, Num)
    
    self:GetLocalComponent():RemoveItem(ItemID, Num)
end