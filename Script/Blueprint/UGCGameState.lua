---@class UGCGameState_C:BP_UGCGameState_C
--Edit Below--
UGCGameSystem.UGCRequire('Script.Common.ue_enum_custom')
local UGCGameState = {}; 

local function GameStateTrace(Message)
    print(string.format("[Douluo.UGCGameState] %s", tostring(Message)));
end

function UGCGameState:ReceiveBeginPlay()
GameStateTrace(string.format("ReceiveBeginPlay begin, self=%s, HasAuthority=%s", tostring(self), tostring(self:HasAuthority())));
if self:HasAuthority()==false then
    local MainUIPath = UGCMapInfoLib.GetRootLongPackagePath().. "Asset/Blueprint/UI/MainUI.MainUI_C";
    GameStateTrace(string.format("Load UI class begin, path=%s", tostring(MainUIPath)));
    local MainUIClass=UE.LoadClass(MainUIPath)
    GameStateTrace(string.format("Load UI class end, MainUIClass=%s", tostring(MainUIClass)));
    local PlayerController=GameplayStatics.GetPlayerController(UGCGameSystem.GameState,0)
    GameStateTrace(string.format("GetPlayerController end, PlayerController=%s", tostring(PlayerController)));
    local MainUI=UserWidget.NewWidgetObjectBP(PlayerController,MainUIClass);
    GameStateTrace(string.format("NewWidgetObjectBP end, MainUI=%s", tostring(MainUI)));
    if MainUI ~=nil then
        MainUI:AddToViewport();
        GameStateTrace("AddToViewport success");
    else
        GameStateTrace("AddToViewport skipped, MainUI is nil");
    end
else
    GameStateTrace("skip create UI on authority");
end
GameStateTrace("ReceiveBeginPlay end");

 end
return UGCGameState;
