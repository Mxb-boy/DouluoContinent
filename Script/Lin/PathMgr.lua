 PathMgr = PathMgr or{};

--[[------------------------UI路径----------------------]]--

  PathMgr.MainUI = UGCMapInfoLib.GetRootLongPackagePath() .. 'Asset/Blueprint/UI/UI02.UI02_C'



--[[--------------------Actor路径--------------------------]]--

PathMgr.Actor_01 = UGCMapInfoLib.GetRootLongPackagePath() .. 'Asset/Blueprint/Prefabs/Monsters/Mos_Level_01.Mos_Level_01_C'
PathMgr.Monster_Level_01 = UGCMapInfoLib.GetRootLongPackagePath() .. 'Asset/Blueprint/Prefabs/Monsters/Mos_Level_01.Mos_Level_01_C'
PathMgr.MonsStartPoint_C = UGCMapInfoLib.GetRootLongPackagePath() .. 'Asset/Blueprint/Lin/Monster/Actor/MonsStartPoint.MonsStartPoint_C'



return PathMgr
