---@class UI02_C:UUserWidget
---@field Button_0 UButton
---@field Button_93 UButton
---@field Button_94 UButton
---@field Button_144 UButton
---@field Button_145 UButton
---@field Button_147 UButton
---@field Button_149 UButton
---@field Button_150 UButton
---@field Button_151 UButton
---@field Button_152 UButton
---@field Button_153 UButton
---@field Button_154 UButton
---@field Button_155 UButton
---@field Button_156 UButton
---@field Button_157 UButton
---@field Button_158 UButton
---@field gjl UTextBlock
---@field hp UTextBlock
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_70 UImage
---@field Image_225 UImage
---@field Image_246 UImage
---@field Image_302 UImage
---@field Image_303 UImage
---@field Image_386 UImage
---@field Image_387 UImage
---@field Image_388 UImage
---@field Image_389 UImage
---@field Image_392 UImage
---@field Image_393 UImage
---@field Image_395 UImage
---@field Image_396 UImage
---@field Image_397 UImage
---@field Image_398 UImage
---@field Image_542 UImage
---@field ProgressBar_0 UProgressBar
---@field ProgressBar_1 UProgressBar
---@field ProgressBar_122 UProgressBar
---@field TextBlock_303 UTextBlock
--Edit Below--
UGCGameSystem.UGCRequire("ExtendResource.SignInEvent.OfficialPackage." .. "Script.SignInEvent.SignInEventManager")
UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.ShopV2.ShopV2Manager")
UGCGameSystem.UGCRequire("ExtendResource.RankingList.OfficialPackage." .. "Script.RankingList.RankingListManager")
UGCGameSystem.UGCRequire("ExtendResource.GiftPack.OfficialPackage.Script.GiftPack.GiftPackManager")
local TaskManager = UGCGameSystem.UGCRequire(
    "ExtendResource.TaskTemplate.OfficialPackage.Script.Task.TaskManager"
)
local L_Enum_Event = UGCGameSystem.UGCRequire("Script.Lin.L_Enum_Event")
local UIEffectUtil = UGCGameSystem.UGCRequire("Script.Common.UIEffectUtil")
local Property = UGCGameSystem.UGCRequire("Script.property.property")

local UI02 = { bInitDoOnce = false }

function UI02:Construct()
    self:LuaInit()
end

function UI02:ApplyButtonEffect(Button)
    UIEffectUtil.SetButtonStateBrushSameAsNormal(Button)
    UIEffectUtil.BindPressScale(self, Button, Button, 1.06, 1.0)
end

function UI02:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    self.Button_145.OnClicked:Add(self.Button_145_OnClicked, self)
    self.Button_157.OnClicked:Add(self.Button_157_OnClicked, self)
    self.Button_144.OnClicked:Add(self.Button_144_OnClicked,self)
    self.Button_150.OnClicked:Add(self.Button_150_OnClicked, self)
    self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self)
    self.Button_152.OnClicked:Add(self.Button_152_OnClicked, self)
    self.Button_153.OnClicked:Add(self.Button_153_OnClicked, self)
    self.Button_149.OnClicked:Add(self.Button_149_OnClicked, self)

    self:ApplyButtonEffect(self.Button_0)
    self:ApplyButtonEffect(self.Button_144)
    self:ApplyButtonEffect(self.Button_145)
    self:ApplyButtonEffect(self.Button_147)
    self:ApplyButtonEffect(self.Button_149)
    self:ApplyButtonEffect(self.Button_150)
    self:ApplyButtonEffect(self.Button_151)
    self:ApplyButtonEffect(self.Button_152)
    self:ApplyButtonEffect(self.Button_153)
    self:ApplyButtonEffect(self.Button_154)
    self:ApplyButtonEffect(self.Button_155)
    self:ApplyButtonEffect(self.Button_156)
    self:ApplyButtonEffect(self.Button_157)
    self:ApplyButtonEffect(self.Button_158)
    UGCGenericMessageSystem.ListenGlobalMessage(self, L_Enum_Event.Enum.Test_01, self, self.OnhandleTest)
    self.PropertyRefreshElapsed = 0
    Property.RefreshUI(self)
end

function UI02:Tick(MyGeometry, InDeltaTime)
    self.PropertyRefreshElapsed = (self.PropertyRefreshElapsed or 0) + (tonumber(InDeltaTime) or 0.016)
    if self.PropertyRefreshElapsed < 0.2 then
        return
    end

    self.PropertyRefreshElapsed = 0
    Property.RefreshUI(self)
end

--签到
function UI02:Button_145_OnClicked()
    SignInEventManager:OpenMainUI()
end
--商城
function UI02:Button_144_OnClicked()
    if ShopV2Manager == nil then
        return
    end

    ShopV2Manager:OpenMainUI()
end
--排行榜
function UI02:Button_150_OnClicked()
    if RankingListManager == nil then
        return
    end

    RankingListManager:OpenRankingList()
end
--回城
function UI02:Button_157_OnClicked()
    self:TeleportToHome()
end
--任务
function UI02:Button_152_OnClicked()
    if TaskManager == nil then
        return
    end

    local TaskComponent = TaskManager:GetTaskTemplateComponent()
    if TaskComponent == nil then
        return
    end

    TaskManager:OpenTaskMainUI()
end

-- 称号
function UI02:Button_149_OnClicked()
    if self.TitleUIInstance ~= nil then
        self.TitleUIInstance:Open()
        return
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    local TitleUIPath =
        UGCMapInfoLib.GetRootLongPackagePath()
        .. "Asset/Blueprint/UI/UI06.UI06_C"
    local TitleUIClass = UE.LoadClass(TitleUIPath)

    if PlayerController == nil or TitleUIClass == nil then
        return
    end

    self.TitleUIInstance =
        UserWidget.NewWidgetObjectBP(PlayerController, TitleUIClass)

    if self.TitleUIInstance == nil then
        return
    end

    self.TitleUIInstance:AddToViewport(1000)
    self.TitleUIInstance:Open()
end

function UI02:Button_153_OnClicked()
    if self.UI10Instance ~= nil then
        if self.UI10Instance.InitWeaponWidgets ~= nil then
            self.UI10Instance:InitWeaponWidgets()
        end
        self.UI10Instance:SetVisibility(ESlateVisibility.Visible)
        return
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    local UI10Path = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/UI10.UI10_C"
    local UI10Class = UE.LoadClass(UI10Path)
    if UI10Class == nil then
        return
    end

    self.UI10Instance = UserWidget.NewWidgetObjectBP(PlayerController, UI10Class)
    if self.UI10Instance == nil then
        return
    end

    self.UI10Instance:AddToViewport(11000)
end

function UI02:TeleportToHome()
    local pc = GameplayStatics.GetPlayerController(self, 0)
    if pc then
        UnrealNetwork.CallUnrealRPC(pc, pc, "Server_TeleportToSpawn", 1)
    end

    -- local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
    -- UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(playerPawn, L_Enum_Event.Enum.Test_01, 66)
end

--礼包
function UI02:Button_0_OnClicked()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)

    local GiftPackUIClass = UE.LoadClass(
        UGCGameSystem.GetUGCResourcesFullPath(
            "ExtendResource/GiftPack/OfficialPackage/Asset/GiftPack/Blueprint/WBP_GiftPackBtn.WBP_GiftPackBtn_C"
        )
    )

    if PlayerController and GiftPackUIClass then
        local GiftPackUI =
            UserWidget.NewWidgetObjectBP(PlayerController, GiftPackUIClass)

        if GiftPackUI then
            GiftPackUI:AddToViewport(12000)
        end
    end

--[[----------------------LJP测试------------------------]]--
local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
if playerPawn ~= nil and playerPawn.PlayerState ~= nil then
    local playerState = playerPawn.PlayerState
    local HunHuan = playerState:GetHunHuan()
    if HunHuan == 10 then
        HunHuan = 0
    end
    playerState:SetHunHuan(HunHuan + 1)

end
 --[[----------------------测试发送事件-----------------------]]--
if PlayerController ~= nil then
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_AddProbabilityBonus", 10)
end
end

function UI02:OnhandleTest(str)
    if self.TextBlock_303 ~= nil then
        self.TextBlock_303:SetText(tostring(str))
    end
end

return UI02
