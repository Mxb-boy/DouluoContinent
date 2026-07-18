---@class UI08_C:UUserWidget
---@field Button_88 UButton
---@field Button_159 UButton
---@field EditorUtilityEditableTextBox_216 UEditorUtilityEditableTextBox
---@field Image_0 UImage
---@field Image_16 UImage
---@field Image_18 UImage
---@field Image_34 UImage
---@field Image_97 UImage
---@field Image_209 UImage
---@field Image_210 UImage
---@field Image_286 UImage
-- Edit Below--
local UI08 = {
    bInitDoOnce = false
}

--[[----------------------初始化兑换码界面------------------------]]
function UI08:Construct()
    self:LuaInit();

end

-- function UI08:Tick(MyGeometry, InDeltaTime)

-- end

-- function UI08:Destruct()

-- end

-- [Editor Generated Lua] function define Begin:
--[[----------------------绑定兑换码界面事件------------------------]]
function UI08:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:
    self.Button_88.OnClicked:Add(self.Button_88_OnClicked, self);
    self.Button_159.OnClicked:Add(self.Button_159_OnClicked, self);
    -- [Editor Generated Lua] BindingEvent End;
end

--[[----------------------提交兑换码测试------------------------]]
function UI08:Button_88_OnClicked()
    local Player_Controller = UGCGameSystem.GetLocalPlayerController()  -- 本地玩家控制器
    if Player_Controller == nil then
        return
    end

    local Redemption_Code = "XXXX-XXXX-XXXX"  -- 默认测试兑换码
    if self.EditorUtilityEditableTextBox_216 ~= nil and self.EditorUtilityEditableTextBox_216.GetText ~= nil then
        local Input_Text = tostring(self.EditorUtilityEditableTextBox_216:GetText())  -- 输入框内容
        if Input_Text ~= "" then
            Redemption_Code = Input_Text
        end
    end

    UnrealNetwork.CallUnrealRPC(Player_Controller, Player_Controller, "UseRedemptionCode", Redemption_Code)

end

--[[----------------------关闭兑换码界面------------------------]]
function UI08:Button_159_OnClicked()
    self:SetVisibility(ESlateVisibility.Collapsed)
end

-- [Editor Generated Lua] function define End;

return UI08
