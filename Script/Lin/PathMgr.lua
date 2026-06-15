 PathMgr = PathMgr or{};

--[[------------------------UI路径----------------------]]--

  PathMgr.MainUI=UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/UI/MainUI.MainUI_C')



--[[--------------------Actor路径--------------------------]]--

PathMgr.Actor_01=UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Prefabs/Monsters/Mos_Level_01.Mos_Level_01_C')
PathMgr.Monster_Level_01 = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Prefabs/Monsters/Mos_Level_01.Mos_Level_01_C')
PathMgr.MonsStartPoint_C = UGCGameSystem.GetUGCResourcesFullPath('Asset/Blueprint/Lin/Monster/Actor/MonsStartPoint.MonsStartPoint_C')



return PathMgr