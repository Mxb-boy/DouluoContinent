---@class UI02_C:UUserWidget
---@field Button_0 UButton
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
---@field Image_0 UImage
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

local UI02 = { bInitDoOnce = false }

function UI02:Construct()
    self:LuaInit()
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

    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.Test_01)
    UGCGenericMessageSystem.RegisterUserDefinedMessage(L_Enum_Event.Enum.ReFreshZhanLi)
    
    UGCGenericMessageSystem.ListenGlobalMessage(self, L_Enum_Event.Enum.Test_01, self, self.OnhandleTest)
    local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if playerPawn ~= nil then
        UGCGenericMessageSystem.ListenObjectMessage(playerPawn, L_Enum_Event.Enum.ReFreshZhanLi, self, self.OnHandleReFreshZHanli)
        if playerPawn.ShowZhanLi ~= nil then
            playerPawn:ShowZhanLi()
        end
    end
end

--签到
function UI02:Button_145_OnClicked()
    ugcprint("[UI02:Button_145_OnClicked] Open official sign in UI")
    SignInEventManager:OpenMainUI()
end
--商城
function UI02:Button_144_OnClicked()
    ugcprint("[UI02:Button_144_OnClicked] Open official shop UI")
    if ShopV2Manager == nil then
        ugcprint("[UI02:Button_144_OnClicked] ShopV2Manager is nil")
        return
    end

    ShopV2Manager:OpenMainUI()
end
--排行榜
function UI02:Button_150_OnClicked()
    ugcprint("[UI02:Button_150_OnClicked] Open official ranking list UI")
    if RankingListManager == nil then
        ugcprint("[UI02:Button_150_OnClicked] RankingListManager is nil")
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
    ugcprint("[UI02:Button_152_OnClicked] Open official task UI")

    if TaskManager == nil then
        ugcprint("[UI02:Button_152_OnClicked] TaskManager is nil")
        return
    end

    local TaskComponent = TaskManager:GetTaskTemplateComponent()
    if TaskComponent == nil then
        ugcprint("[UI02:Button_152_OnClicked] TaskTemplateComponent is nil")
        return
    end

    TaskManager:OpenTaskMainUI()
end

function UI02:TeleportToHome()
    local pc = GameplayStatics.GetPlayerController(self, 0)
    if pc then
        UnrealNetwork.CallUnrealRPC(pc, pc, "Server_TeleportToSpawn", 1)
    end

    local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
    UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(playerPawn, L_Enum_Event.Enum.Test_01, 66)
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
local playerPawn=UGCGameSystem.GetLocalPlayerPawn()
if playerPawn ~= nil and playerPawn.PlayerState ~= nil then
    local playerState=playerPawn.PlayerState
    local HunHuan=playerState:GetHunHuan()
    playerState:SetHunHuan(HunHuan + 1)
end

end

function UI02:OnhandleTest(UID, level)
    local Text = tostring(UID) .. " open level " .. tostring(level)
    if self.TextBlock_1 ~= nil then
        self.TextBlock_1:SetText(Text)
    else
        ugcprint("[UI02:OnhandleTest] " .. Text)
    end
end

function UI02:OnHandleReFreshZHanli(str)
        self.TextBlock_303:SetText(tostring(str))
end

return UI02
