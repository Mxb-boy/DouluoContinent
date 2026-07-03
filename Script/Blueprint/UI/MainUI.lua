---@class MainUI_C:UUserWidget
---@field Button_0 UButton
---@field TextBlock_1 UTextBlock
-- Edit Below--
local MainUI = {
    bInitDoOnce = false
}
function MainUI:Construct()
    self:LuaInit();
end

function MainUI:LuaInit()
    if self.bInitDoOnce then
        return;
    end
    self.bInitDoOnce = true;
    self.Button_0.OnClicked:Add(self.Button_0_OnClicked, self);
    local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
end

function MainUI:Button_0_OnClicked()
    local pc = GameplayStatics.GetPlayerController(self, 0)
    if pc then
        UnrealNetwork.CallUnrealRPC(pc, pc, "Server_TeleportToSpawn", 1)
    end
end

function MainUI:OnhandleTest(UID, level)

    self.TextBlock_1:SetText(tostring(UID) .. "开启关卡" .. tostring(level))
end

-- [Editor Generated Lua] function define End;

return MainUI
