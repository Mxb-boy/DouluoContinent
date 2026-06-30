---@class UI02_C:UUserWidget
---@field Button_0 UButton
---@field Button_3 UButton
---@field Button_4 UButton
---@field Button_92 UButton
---@field Button_93 UButton
---@field Button_94 UButton
---@field Button_95 UButton
---@field Button_97 UButton
---@field Button_99 UButton
---@field Button_134 UButton
---@field Button_135 UButton
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
---@field Button_226 UButton
---@field Button_227 UButton
---@field Button_228 UButton
---@field gjl UTextBlock
---@field hp UTextBlock
---@field Image_0 UImage
---@field Image_1 UImage
---@field Image_2 UImage
---@field Image_70 UImage
---@field Image_109 UImage
---@field Image_169 UImage
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
---@field ProgressBar_2 UProgressBar
---@field ProgressBar_122 UProgressBar
---@field TextBlock_0 UTextBlock
---@field TextBlock_1 UTextBlock
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
    self.Button_151.OnClicked:Add(self.Button_151_OnClicked, self)
    self.Button_155.OnClicked:Add(self.Button_155_OnClicked, self)
    self.Button_227.OnClicked:Add(self.Button_227_OnClicked, self)
    self.Button_3.OnClicked:Add(self.Button_3_OnClicked, self)

    self:ApplyButtonEffect(self.Button_0)
    self:ApplyButtonEffect(self.Button_3)
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
    self:ApplyButtonEffect(self.Button_227)
    self:ApplyButtonEffect(self.Button_228)

    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshProperty)
    UGCGenericMessageSystem.ListenGlobalMessage(self, L_Enum_Event.Enum.Test_01, self, self.OnhandleTest)
    UGCGenericMessageSystem.ListenGlobalMessage(self, L_Enum_Event.Enum.ReFreshProperty, self, self.OnRefreshProperty)
    self:RefreshYXWDBuffIcon()
    Property.RefreshUI(self)
end

function UI02:OnRefreshProperty()
    Property.RefreshUI(self)
    self:RefreshYXWDBuffIcon()
end

--签到
function UI02:GetLocalPlayerState()
    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController ~= nil and PlayerController.PlayerState ~= nil then
        return PlayerController.PlayerState
    end

    if UGCGameSystem ~= nil and UGCGameSystem.GetLocalPlayerState ~= nil then
        local Success, Result = pcall(UGCGameSystem.GetLocalPlayerState)
        if Success and Result ~= nil then
            return Result
        end
    end

    if UGCGameSystem ~= nil and UGCGameSystem.GetLocalPlayerPawn ~= nil then
        local PlayerPawn = UGCGameSystem.GetLocalPlayerPawn()
        if PlayerPawn ~= nil then
            return PlayerPawn.PlayerState
        end
    end

    return nil
end

function UI02:HasYXWDInvincibleBuff()
    if self.YXWDBuffIconActive == true then
        return true
    end

    local PlayerState = self:GetLocalPlayerState()
    if PlayerState == nil then
        return false
    end

    if PlayerState.GetYXWD_InvincibleBuff ~= nil then
        return PlayerState:GetYXWD_InvincibleBuff() == true
    end

    return tonumber(PlayerState.YXWD_InvincibleBuff) == 1
end

function UI02:HideYXWDBuffIcon()
    self.YXWDBuffIconActive = false
    self.YXWDInvincibleActive = false
    self.YXWDBuffIconDurationSeconds = 0
    self.YXWDBuffIconExpireToken = (self.YXWDBuffIconExpireToken or 0) + 1

    if self.Button_228 ~= nil then
        self.Button_228:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UI02:ShowYXWDBuffIcon(DurationSeconds)
    if self.Button_228 == nil then
        return
    end

    local Duration = tonumber(DurationSeconds)
    if Duration == nil then
        Duration = -2
    end

    if Duration ~= -2 and Duration <= 0 then
        self:HideYXWDBuffIcon()
        return
    end

    self.YXWDBuffIconActive = true
    if self.YXWDInvincibleActive == nil then
        self.YXWDInvincibleActive = true
    end
    self.YXWDBuffIconDurationSeconds = Duration
    self.YXWDBuffIconExpireToken = (self.YXWDBuffIconExpireToken or 0) + 1
    local ExpireToken = self.YXWDBuffIconExpireToken

    self.Button_228:SetVisibility(ESlateVisibility.Visible)

    if Duration == -2 then
        return
    end

    if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
        UGCTimerUtility.CreateLuaTimer(Duration, function()
            if self ~= nil and self.YXWDBuffIconExpireToken == ExpireToken then
                self:HideYXWDBuffIcon()
            end
        end, false)
    end
end

function UI02:RefreshYXWDBuffIcon()
    if self.Button_228 == nil then
        return
    end

    local bHasBuff = self:HasYXWDInvincibleBuff()
    if bHasBuff then
        self:ShowYXWDBuffIcon(-2)
    end

    if self.YXWDBuffIconActive == true then
        self.Button_228:SetVisibility(ESlateVisibility.Visible)
    else
        self.Button_228:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UI02:OnYXWDInvincibleBuffChanged(bEnabled, DurationSeconds)
    if self.Button_228 == nil then
        return
    end

    if bEnabled == true or tonumber(bEnabled) == 1 then
        self.YXWDInvincibleActive = true
        self:ShowYXWDBuffIcon(DurationSeconds)
    else
        self:HideYXWDBuffIcon()
    end
end

function UI02:OnYXWDInvincibleActiveChanged(bActive)
    if self:HasYXWDInvincibleBuff() ~= true then
        self.YXWDInvincibleActive = false
        return
    end

    self.YXWDInvincibleActive = bActive == true or tonumber(bActive) == 1
    self:ShowYXWDBuffIcon(self.YXWDBuffIconDurationSeconds or -2)
end

function UI02:Button_3_OnClicked()
    if self:HasYXWDInvincibleBuff() ~= true then
        return
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    local bNextActive = not (self.YXWDInvincibleActive == true)
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Server_SetYXWDInvincibleBuffActive",
        bNextActive and 1 or 0)
end

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

-- 境界
function UI02:Button_151_OnClicked()
    ugcprint("[UI02:Button_151_OnClicked] Open UI08 realm panel")

    if self.UI08Instance ~= nil then
        if self.UI08Instance.Open ~= nil then
            self.UI08Instance:Open()
        else
            self.UI08Instance:SetVisibility(ESlateVisibility.Visible)
        end
        return
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        ugcprint("[UI02:Button_151_OnClicked] PlayerController is nil")
        return
    end

    local UI08Path = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/Blueprint/UI/UI08.UI08_C"
    local UI08Class = UE.LoadClass(UI08Path)
    if UI08Class == nil then
        ugcprint("[UI02:Button_151_OnClicked] UI08 class load failed: " .. UI08Path)
        return
    end

    self.UI08Instance = UserWidget.NewWidgetObjectBP(PlayerController, UI08Class)
    if self.UI08Instance == nil then
        ugcprint("[UI02:Button_151_OnClicked] UI08 create failed")
        return
    end

    self.UI08Instance:AddToViewport(11000)
    if self.UI08Instance.Open ~= nil then
        self.UI08Instance:Open()
    end
end

-- 传送
function UI02:Button_155_OnClicked()
    if self.TeleportUIInstance ~= nil then
        -- 重新刷新战力门槛（玩家升级后按钮状态会更新）
        if self.TeleportUIInstance.RefreshList then
            self.TeleportUIInstance:RefreshList()
        end
        self.TeleportUIInstance:SetVisibility(ESlateVisibility.Visible)
        return
    end

    local PlayerController = GameplayStatics.GetPlayerController(self, 0)
    if PlayerController == nil then
        return
    end

    local UI12Path = UGCMapInfoLib.GetRootLongPackagePath() .. "Asset/UI12.UI12_C"
    local UI12Class = UE.LoadClass(UI12Path)
    if UI12Class == nil then
        ugcprint("[UI02:Button_155] UI12 class load failed: " .. UI12Path)
        return
    end

    self.TeleportUIInstance = UserWidget.NewWidgetObjectBP(PlayerController, UI12Class)
    if self.TeleportUIInstance == nil then
        ugcprint("[UI02:Button_155] UI12 create failed")
        return
    end

    self.TeleportUIInstance:AddToViewport(11000)
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
end


--自动拾取
function UI02:Button_227_OnClicked()
    local PC = GameplayStatics.GetPlayerController(self, 0)
    self.bAutoPickEnabled = not self.bAutoPickEnabled

    UnrealNetwork.CallUnrealRPC(PC, PC, "Server_SetAutoPickEnabled", self.bAutoPickEnabled)

    self:OnhandleTest(self.bAutoPickEnabled and "自动拾取已开启" or "自动拾取已关闭")
end

function UI02:OnhandleTest(str)
    if self.TextBlock_303 ~= nil then
        self.TextBlock_303:SetText(tostring(str))
    end
end

return UI02
