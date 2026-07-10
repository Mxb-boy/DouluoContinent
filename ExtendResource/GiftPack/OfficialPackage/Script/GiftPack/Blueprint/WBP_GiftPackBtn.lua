---@class WBP_GiftPackBtn_C:UserWidgetUI
---@field ApplyGiftPackBtn UButton
---@field GiftPackInput USpinBox
--Edit Below--
local WBP_GiftPackBtn = { bInitDoOnce = false } 

function WBP_GiftPackBtn:Construct()
    self.ApplyGiftPackBtn.OnClicked:Add(self.ApplyGiftPack, self);
end

function WBP_GiftPackBtn:ApplyGiftPack()
    local GiftPackID = math.modf(self.GiftPackInput:GetValue());
    --点击“使用礼包”且礼包成功打开后，测试 UI 会自动隐藏
    local bOpened = GiftPackManager:OpenGiftPack(GiftPackID);
    if bOpened then
        self:SetVisibility(ESlateVisibility.Collapsed);
    end
end

-- function WBP_GiftPackBtn:Tick(MyGeometry, InDeltaTime)

-- end

-- function WBP_GiftPackBtn:Destruct()

-- end

return WBP_GiftPackBtn
