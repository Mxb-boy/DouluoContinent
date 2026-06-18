---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
 local PathMgr = UGCGameSystem.UGCRequire('Script.Lin.PathMgr')
 local L_Enum_Event = UGCGameSystem.UGCRequire('Script.Lin.L_Enum_Event')
local MonsterSpawnMgr =UGCGameSystem.UGCRequire("Script.Lin.MonsSpawMgr")
local UGCGameState = {}; 

function UGCGameState:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)

    if self:HasAuthority()==false then
        local MainUIPath = UGCMapInfoLib.GetRootLongPackagePath().. "Asset/Blueprint/UI/UI02.UI02_C";
        local MainUIClass=UE.LoadClass(MainUIPath)
        local PlayerController=GameplayStatics.GetPlayerController(UGCGameSystem.GameState,0)
        local MainUI=UserWidget.NewWidgetObjectBP(PlayerController,MainUIClass);
        if MainUI ~=nil then
            MainUI:AddToViewport();
        end

--[[   local RankListBtnClass = UE.LoadClass(UGCMapInfoLib.GetRootLongPackagePath().. "ExtendResource/RankingList/OfficialPackage/Asset/RankingList/Blueprint/WBP_RankingListBtn.WBP_RankingListBtn_C")
    local RankListBtn = UserWidget.NewWidgetObjectBP(PlayerController, RankListBtnClass)
    if RankListBtn ~= nil then
        RankListBtn:AddToViewport(1000)
        ugcprint("[UGCGameState] Ranking list debug button added")
    else
        ugcprint("[UGCGameState] Ranking list debug button create failed")
    end
--]]


    --[[local TaskBtnClass = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath("ExtendResource/TaskTemplate/OfficialPackage/Asset/Task/Blueprint/WBP_TaskMainUIButton.WBP_TaskMainUIButton_C"));
    local TaskBtn = UGCWidgetManagerSystem.CreateWidget(TaskBtnClass);
    TaskBtn:AddToViewport();
     ]]--


        --[[local GiftPackUIClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath("ExtendResource/GiftPack/OfficialPackage/Asset/GiftPack/Blueprint/WBP_GiftPackBtn.WBP_GiftPackBtn_C"));
        if GiftPackUIClass ~= nil and PlayerController ~= nil then
            local GiftPackUI = UserWidget.NewWidgetObjectBP(PlayerController, GiftPackUIClass);
            if GiftPackUI ~= nil then
                GiftPackUI:AddToViewport(12000);
            else
                ugcprint("[UGCGameState] GiftPackUI create failed");
            end
        else
            ugcprint("[UGCGameState] GiftPackUIClass or PlayerController is nil");
        end
        --]]
    end
end
return UGCGameState;
