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
--Edit Below--
UGCGameSystem.UGCRequire("ExtendResource.SignInEvent.OfficialPackage." .. "Script.SignInEvent.SignInEventManager")
UGCGameSystem.UGCRequire("ExtendResource.ShopV2.OfficialPackage." .. "Script.ShopV2.ShopV2Manager")
UGCGameSystem.UGCRequire("ExtendResource.RankingList.OfficialPackage." .. "Script.RankingList.RankingListManager")
UGCGameSystem.UGCRequire("ExtendResource.GiftPack.OfficialPackage.Script.GiftPack.GiftPackManager")
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

    UGCGenericMessageSystem.ListenGlobalMessage(self, L_Enum_Event.Enum.Test_01, self, self.OnhandleTest)
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
end

function UI02:OnhandleTest(UID, level)
    local Text = tostring(UID) .. " open level " .. tostring(level)
    if self.TextBlock_1 ~= nil then
        self.TextBlock_1:SetText(Text)
    else
        ugcprint("[UI02:OnhandleTest] " .. Text)
    end
end

return UI02
