---@class SignInEvent_Monthly_Item_UIBP_C:UUserWidget
---@field ConfirmButton UNewButton
---@field DayText UTextBlock
---@field Icon UImage
---@field Obtained UCanvasPanel
---@field QuantityText UTextBlock
---@field RedDot UImage
---@field StateSwitcher UWidgetSwitcher
---@field ShowTipPressTime float
--Edit Below--
local SignInEvent_Monthly_Item_UIBP = 
{ 
    bInitDoOnce = false;

    EventID = 0;
    DayIndex = 0;
} 

function SignInEvent_Monthly_Item_UIBP:Construct()
	
    self.ConfirmButton.OnClicked:Add(self.OnClick, self);
    self.ConfirmButton.OnPressed:Add(self.OnPress, self);
    self.ConfirmButton.OnReleased:Add(self.OnRelease, self);
end

function SignInEvent_Monthly_Item_UIBP:Refresh(EventID, DayIndex, SupplementDay)
    
    self:Reset();
    self.EventID = EventID;
    self.DayIndex = DayIndex;

    local Config = SignInEventManager:GetEventConfigData(EventID);
    local Awards = Config.Awards;

    if Awards[DayIndex] == nil then
        print("[SignInEvent_Weekly_Item_UIBP] Award table is not set correctly!");
        return;
    end

    self.DayText:SetText(Awards[DayIndex].DayName);
    self.QuantityText:SetText(Awards[DayIndex].ItemNum);

    local IconPath = Common.GetObjectDatas()[Awards[DayIndex].ItemID].ItemIcon;
    Common.LoadObjectAsync(IconPath, 
        function (IconTexture)
            if self ~= nil and UE.IsValid(self) then
                self.Icon:SetBrushFromTexture(IconTexture);
            end
        end
    );

    -- 签到状态
    local DayNum = SignInEventManager:GetEventDayNum(EventID);
    if DayIndex <= DayNum then                          -- 已签
        self.StateSwitcher:SetActiveWidgetIndex(2);
        self.Obtained:SetVisibility(ESlateVisibility.HitTestInvisible);
        return;
    end

    local TodayIndex = SignInEventManager:GetTodayEventDayNum(EventID) + 1;
    if DayIndex == TodayIndex then                                              -- 今日签到
        self.StateSwitcher:SetActiveWidgetIndex(1);
        self.RedDot:SetVisibility(ESlateVisibility.HitTestInvisible);
    elseif SignInEventManager:GetEventSupplementDayNum(EventID) < SupplementDay -- 今日补签
    and DayIndex <= TodayIndex + SupplementDay then                             
        self.StateSwitcher:SetActiveWidgetIndex(3);
    else                                                                        -- 待签
        self.StateSwitcher:SetActiveWidgetIndex(0);
    end
end

function SignInEvent_Monthly_Item_UIBP:Reset()
    
    self.RedDot:SetVisibility(ESlateVisibility.Collapsed);
    self.Obtained:SetVisibility(ESlateVisibility.Collapsed);
end

function SignInEvent_Monthly_Item_UIBP:OnClick()
    if not self.bBlockClick then
        self.bBlockClick = true

        local Index = self.StateSwitcher:GetActiveWidgetIndex();
        -- 签到
        if Index == 1 then
            SignInEventManager:GetDailySignInAward(self.EventID);
        -- 补签
        elseif Index == 3 then
            if SignInEventManager:GetEventDayNum(self.EventID) + 1 == self.DayIndex then
                SignInEventManager:ShowSupplementPopup(self.EventID);
            else
                print("[SignInEvent_Monthly_Item_UIBP] Must Check Previous Day First!");
                SignInEventManager:ShowSupplementTip("前一日签到后才能补签");
            end
        end
        
        UGCTimerUtility.CreateLuaTimer(1, function () self.bBlockClick = false end)
    end
end

function SignInEvent_Monthly_Item_UIBP:OnPress()
    
    self.PressTimerHandle = Timer.InsertTimer(
        0, 
        function ()
            local AbsPosition = SlateBlueprintLibrary.GetAbsolutePosition(self:GetCachedGeometry());
            local Position = SlateBlueprintLibrary.AbsoluteToLocal(WidgetLayoutLibrary.GetViewportWidgetGeometry(self), AbsPosition);
            local Config = SignInEventManager:GetEventConfigData(self.EventID);
            local Awards = Config.Awards;
            SignInEventManager:ShowTip(Config.Awards[self.DayIndex].ItemID, Position);
        end,
        false,
        "ShowTipPressTimer",
        self.ShowTipPressTime
    );
end

function SignInEvent_Monthly_Item_UIBP:OnRelease()
    
    if self.PressTimerHandle ~= nil then
        Timer.RemoveTimer(self.PressTimerHandle);
        self.PressTimerHandle = nil; 
    end
end

return SignInEvent_Monthly_Item_UIBP