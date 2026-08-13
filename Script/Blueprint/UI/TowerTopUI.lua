---@class TowerTopUI_C:UUserWidget
---@field Button_107 UButton
---@field Button_109 UButton
---@field Image_0 UImage
---@field Image_32 UImage
---@field Image_36 UImage
--Edit Below--
---@class TowerTopUI_C:UUserWidget
---@field Button_107 UButton
---@field Button_109 UButton
---@field Image_0 UImage
---@field Image_31 UImage
---@field Image_32 UImage
---@field Image_34 UImage
---@field Image_35 UImage
---@field Image_36 UImage
-- Edit Below--
---@class TowerTopUI_C:UUserWidget
---@field Button_107 UButton
---@field Button_109 UButton
---@field Image_31 UImage
---@field Image_32 UImage
---@field Image_34 UImage
---@field Image_35 UImage
---@field Image_36 UImage
-- Edit Below--
local TowerTopUI = {
    bInitDoOnce = false
}
local TaskMgr = UGCGameSystem.UGCRequire("Script.Lin.TaskMgr")
local L_Enum = UGCGameSystem.UGCRequire("Script.Lin.L_Enum")
local RankMgr = UGCGameSystem.UGCRequire("Script.Xiao.RankMgr")

function TowerTopUI:Construct()
    self:LuaInit()
end

function TowerTopUI:LuaInit()
    if self.bInitDoOnce then
        return
    end
    self.bInitDoOnce = true

    self.Button_109.OnClicked:Add(self.Button_109_OnClicked, self)
    self.Button_107.OnClicked:Add(self.Button_107_OnClicked, self)
end

function TowerTopUI:Button_109_OnClicked()
    local pc = UGCGameSystem.GetLocalPlayerController() or GameplayStatics.GetPlayerController(self, 0)
    if pc then
        --[[------------------通知获得物品----------------------------]] --
        UnrealNetwork.CallUnrealRPC(pc, pc, "Server_ClaimTowerTopReward")
        TaskMgr:RequestAddTaskProgress(L_Enum.AllTask.TowerPass, 1)
        RankMgr:NotifyTowerTop()
        pc.TowerTopUIInstance = nil
    end

    self:RemoveFromParent()
end

function TowerTopUI:Button_107_OnClicked()
    local pc = UGCGameSystem.GetLocalPlayerController() or GameplayStatics.GetPlayerController(self, 0)
    if pc then
        pc.TowerTopUIInstance = nil
    end

    self:RemoveFromParent()
end

-- function TowerTopUI:Tick(MyGeometry, InDeltaTime)

-- end

-- function TowerTopUI:Destruct()

-- end

return TowerTopUI
