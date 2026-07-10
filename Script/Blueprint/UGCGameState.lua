---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
 local PathMgr = UGCGameSystem.UGCRequire('Script.Lin.PathMgr')
 local L_Enum_Event = UGCGameSystem.UGCRequire('Script.Lin.L_Enum_Event')
local MonsterSpawnMgr =UGCGameSystem.UGCRequire("Script.Lin.MonsSpawMgr")
local UGCGameState = {}; 

-- 临时修复：官方公告模块未加载时，防止引擎框架报 nil 索引警告
if UpdateNoticeInGameUI == nil then
    UpdateNoticeInGameUI = {}
end


function UGCGameState:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self)

--[[   local RankListBtnClass = UE.LoadClass(UGCMapInfoLib.GetRootLongPackagePath().. "ExtendResource/RankingList/OfficialPackage/Asset/RankingList/Blueprint/WBP_RankingListBtn.WBP_RankingListBtn_C")
    local RankListBtn = UserWidget.NewWidgetObjectBP(PlayerController, RankListBtnClass)
    if RankListBtn ~= nil then
        RankListBtn:AddToViewport(1000)
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
            end
        else
        end
        --]]

    --[[local TaskBtnClass = UGCObjectUtility.LoadClass(UGCGameSystem.GetUGCResourcesFullPath("ExtendResource/TaskTemplate/OfficialPackage/Asset/Task/Blueprint/WBP_TaskMainUIButton.WBP_TaskMainUIButton_C"));
    local TaskBtn = UGCWidgetManagerSystem.CreateWidget(TaskBtnClass);
    TaskBtn:AddToViewport();
    --]]

    -- if not self:HasAuthority() then
    --     local btnClass = UE.LoadClass(UGCGameSystem.GetUGCResourcesFullPath('ExtendResource/Lottery/OfficialPackage/Asset/Lottery/Blueprint/WBP_OpenLotteryButton.WBP_OpenLotteryButton_C'))
    --     local btnUI = UserWidget.NewWidgetObjectBP(self, btnClass)
    --     btnUI:AddToViewport(100)
    -- end
end
return UGCGameState;
