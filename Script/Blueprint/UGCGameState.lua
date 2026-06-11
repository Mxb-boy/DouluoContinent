---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
local UGCGameState = {}; 

function UGCGameState:ReceiveBeginPlay()
if self:HasAuthority()==false then
    local MainUIClass=UE.LoadClass(UGCMapInfoLib.GetRootLongPackagePath().. "Asset/Blueprint/UI/MainUI.MainUI_C")
    local PlayerController=GameplayStatics.GetPlayerController(UGCGameSystem.GameState,0)
    local MainUI=UserWidget.NewWidgetObjectBP(PlayerController,MainUIClass);
    if MainUI ~=nil then
        MainUI:AddToViewport();
    end
end

 end
return UGCGameState;
