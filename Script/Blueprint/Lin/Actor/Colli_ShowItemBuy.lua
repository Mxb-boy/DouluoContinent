---@class Colli_ShowItemBuy_C:AActor
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field ID_Shop int32
---@field IS_ShowCJ bool
--Edit Below--
local Colli_ShowItemBuy = {}
local L_Com = UGCGameSystem.UGCRequire("Script.Lin.L_Com")

--[[----------------------绑定商品购买区域碰撞事件------------------------]]
function Colli_ShowItemBuy:ReceiveBeginPlay()
    Colli_ShowItemBuy.SuperClass.ReceiveBeginPlay(self)
    self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
    self.Box.OnComponentEndOverlap:Add(self.Box_OnComponentEndOverlap, self);
end

--[[
function Colli_ShowItemBuy:ReceiveTick(DeltaTime)
    Colli_ShowItemBuy.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function Colli_ShowItemBuy:ReceiveEndPlay()
    Colli_ShowItemBuy.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function Colli_ShowItemBuy:GetReplicatedProperties()
    return
end
--]]

--[[
function Colli_ShowItemBuy:GetAvailableServerRPCs()
    return
end
--]]

-- [Editor Generated Lua] function define Begin:
--[[----------------------初始化商品购买区域------------------------]]
function Colli_ShowItemBuy:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    -- [Editor Generated Lua] BindingProperty Begin:
    -- [Editor Generated Lua] BindingProperty End;

    -- [Editor Generated Lua] BindingEvent Begin:

    -- [Editor Generated Lua] BindingEvent End;
end

--[[----------------------玩家进入区域时显示对应界面------------------------]]
function Colli_ShowItemBuy:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex,
    bFromSweep, SweepResult)
    local Player_Controller = UGCGameSystem.GetPlayerControllerByPlayerPawn(OtherActor)
    if Player_Controller == nil or not Player_Controller:IsLocalPlayerController() then
        return nil;
    end

    if self.IS_ShowCJ then
        local Main_UI = Player_Controller.MainUIInstance -- 主界面实例
        self.CJ_UI = Main_UI and Main_UI.UI14Instance or Player_Controller.UI14Instance -- 召唤界面实例
        if self.CJ_UI == nil then
            local UI14_Path = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/UI/UI14.UI14_C') -- 召唤界面路径
            local UI14_Class = UE.LoadClass(UI14_Path) -- 召唤界面类
            if UI14_Class == nil then
                return nil;
            end

            self.CJ_UI = UserWidget.NewWidgetObjectBP(Player_Controller, UI14_Class)
            if self.CJ_UI == nil then
                return nil;
            end

            self.CJ_UI:AddToViewport(11000)
            if Main_UI ~= nil then
                Main_UI.UI14Instance = self.CJ_UI
            else
                Player_Controller.UI14Instance = self.CJ_UI
            end
        end
        self.CJ_UI:Open()
        return nil;
    end

    self.Is_Player_Inside = true -- 玩家是否在区域内

    local Promise_Future = L_Com.BuyShopProduct(self.ID_Shop)
    if Promise_Future ~= nil then
        Promise_Future:Then(function(Result)
            local Buy_Product_UI = Result:Get()
            if self.Is_Player_Inside then
                self.Buy_Product_UI = Buy_Product_UI
            elseif Buy_Product_UI ~= nil then
                Buy_Product_UI.ConfirmationOperationDelegate:Broadcast(false)
            end
        end)
    end
end

--[[----------------------玩家离开区域时关闭对应界面------------------------]]
function Colli_ShowItemBuy:Box_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    local Player_Controller = UGCGameSystem.GetPlayerControllerByPlayerPawn(OtherActor)
    if Player_Controller == nil or not Player_Controller:IsLocalPlayerController() then
        return nil;
    end

    if self.IS_ShowCJ then
        if self.CJ_UI ~= nil then
            self.CJ_UI:Close()
        end
        return nil;
    end

    self.Is_Player_Inside = false -- 玩家是否在区域内
    if self.Buy_Product_UI ~= nil then
        self.Buy_Product_UI.ConfirmationOperationDelegate:Broadcast(false)
        self.Buy_Product_UI = nil
    end
end

-- [Editor Generated Lua] function define End;

return Colli_ShowItemBuy
