---@class kj06_C:UUserWidget
---@field Btn_Close UButton
---@field Button_55 UButton
---@field Button_56 UButton
---@field Image_2 UImage
---@field Image_3 UImage
---@field Image_4 UImage
---@field Image_5 UImage
---@field Image_6 UImage
---@field Image_9 UImage
---@field Image_10 UImage
---@field Image_11 UImage
---@field Image_45 UImage
---@field Image_107 UImage
---@field Image_108 UImage
---@field Image_109 UImage
---@field Image_110 UImage
---@field Image_134 UImage
--Edit Below--
---@class kj06_C:UUserWidget
---@field Btn_Close UButton
---@field Button_55 UButton
---@field Button_56 UButton
---@field Image_2 UImage
---@field Image_3 UImage
---@field Image_4 UImage
---@field Image_5 UImage
---@field Image_6 UImage
---@field Image_9 UImage
---@field Image_10 UImage
---@field Image_11 UImage
---@field Image_45 UImage
---@field Image_107 UImage
---@field Image_108 UImage
---@field Image_109 UImage
---@field Image_110 UImage
---@field Image_134 UImage
-- Edit Below--
---@class kj06_C:UUserWidget
---@field Btn_Close UButton
---@field Button_55 UButton
---@field Button_56 UButton
---@field Image_2 UImage
---@field Image_3 UImage
---@field Image_4 UImage
---@field Image_5 UImage
---@field Image_6 UImage
---@field Image_9 UImage
---@field Image_10 UImage
---@field Image_11 UImage
---@field Image_45 UImage
---@field Image_107 UImage
---@field Image_108 UImage
---@field Image_109 UImage
---@field Image_110 UImage
---@field Image_134 UImage
-- Edit Below--
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")
local kj06 = {
    bInitDoOnce = false
}
local PaTa_Ticket_Item_ID = 8310064 -- 爬塔传送券

--[[----------------------初始化界面------------------------]]
function kj06:Construct()
    self:LuaInit()
    self:RefreshPaTaButtons()
end

--[[----------------------绑定关闭按钮事件------------------------]]
function kj06:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    if self.Btn_Close ~= nil then
        self.Btn_Close.OnClicked:Add(self.Btn_Close_OnClicked, self)
    end

    if self.Button_55 ~= nil then
        self.Button_55.OnClicked:Add(self.Button_55_OnClicked, self)
    end

    if self.Button_56 ~= nil then
        self.Button_56.OnClicked:Add(self.Button_56_OnClicked, self)
    end
end

--[[----------------------关闭当前界面------------------------]]
function kj06:Btn_Close_OnClicked()
    if self.RemoveFromParent ~= nil then
        self:RemoveFromParent()
    elseif self.SetVisibility ~= nil then
        self:SetVisibility(ESlateVisibility.Collapsed)
    end
end

--[[----------------------用劵爬塔------------------------]]
function kj06:Button_55_OnClicked()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    local Pawn = PlayerController and PlayerController.Pawn
    local TicketCount = 0
    if Pawn ~= nil and UGCBackpackSystemV2 ~= nil and UGCBackpackSystemV2.GetItemCountV2 ~= nil then
        TicketCount = tonumber(UGCBackpackSystemV2.GetItemCountV2(Pawn, PaTa_Ticket_Item_ID)) or 0
    end

    if TicketCount <= 0 then
        L_Com.ShowToast("暂无爬塔卷")
        return
    end

    if PlayerController then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestTicketPaTa")
    end

end

--[[----------------------免费爬塔------------------------]]
function kj06:Button_56_OnClicked()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    if PlayerController then
        UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_RequestFreePaTa")
        if PlayerController.PlayerState ~= nil then
            PlayerController.PlayerState.PaTaRefreshDay = tonumber(os.date("%Y%m%d", os.time())) or 0
        end
    end
    self:RefreshPaTaButtons()

end

--[[----------------------刷新爬塔按钮状态------------------------]]
function kj06:RefreshPaTaButtons()
    local PlayerController = UGCGameSystem.GetLocalPlayerController()
    local PlayerState = PlayerController and PlayerController.PlayerState
    local Today = tonumber(os.date("%Y%m%d", os.time())) or 0
    local RefreshDay = 0
    if PlayerState ~= nil then
        RefreshDay = PlayerState.GetPaTaRefreshDay ~= nil and PlayerState:GetPaTaRefreshDay() or
                         (tonumber(PlayerState.PaTaRefreshDay) or 0)
    end

    if self.Button_55 ~= nil then
        self.Button_55:SetVisibility(ESlateVisibility.Collapsed)
    end

    if self.Button_56 ~= nil then
        self.Button_56:SetVisibility(ESlateVisibility.Collapsed)
    end

    if RefreshDay ~= Today then
        if self.Button_56 ~= nil then
            self.Button_56:SetVisibility(ESlateVisibility.Visible)
        end
    elseif self.Button_55 ~= nil then
        self.Button_55:SetVisibility(ESlateVisibility.Visible)
    end
end

return kj06
