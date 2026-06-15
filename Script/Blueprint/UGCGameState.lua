---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
 local PathMgr = UGCGameSystem.UGCRequire('Script.Lin.PathMgr')
 local L_Enum_Event = UGCGameSystem.UGCRequire('Script.Lin.L_Enum_Event')

local UGCGameState = {}; 


function UGCGameState:ReceiveBeginPlay()
if self:HasAuthority()==false then
    local MainUIPath = UGCMapInfoLib.GetRootLongPackagePath().. "Asset/Blueprint/UI/MainUI.MainUI_C";
    local MainUIClass=UE.LoadClass(MainUIPath)
    local PlayerController=GameplayStatics.GetPlayerController(UGCGameSystem.GameState,0)
    local MainUI=UserWidget.NewWidgetObjectBP(PlayerController,MainUIClass);
    if MainUI ~=nil then
        MainUI:AddToViewport();
end

end
end
return UGCGameState;
