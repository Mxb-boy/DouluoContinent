---@class Tower_MonsMgr_C:BP_UGCMobSpawnerManager_C
local Tower_MonsMgr = {}  -- 塔怪刷怪管理器逻辑

--[[----------------------全部怪物死亡十秒后重新刷怪------------------------]]
function Tower_MonsMgr:OnAllMobDie()
    UGCTimerUtility.CreateLuaTimer(10,
        --[[----------------------重新启动刷怪管理器------------------------]]
        function()
            self:ResetSpawnerManager(false)
            self:StartSpawnerManager()
        end,
        false
    )
end

return Tower_MonsMgr
