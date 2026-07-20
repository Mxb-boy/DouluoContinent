local TeamConfig = {}

-- 每次生成新的真机包时更新，用日志确认客户端与服务器运行的是同一版本。
TeamConfig.BUILD_ID = "TEAM_DOULUO_UPDATE_20260720_01"

TeamConfig.MAX_SERVER_PLAYERS = 12
TeamConfig.MAX_PLAYERS_PER_TEAM = 4
TeamConfig.MAX_ACTIVE_TEAMS = 3
TeamConfig.MAX_MATCH_PLAYERS = TeamConfig.MAX_SERVER_PLAYERS
TeamConfig.UI_Z_ORDER = 10000
TeamConfig.LOBBY_QUIT_DELAY = 1.0
TeamConfig.CAMP_RELATION = {
    Same = 0,
    Neutral = 1,
    Enemy = 2
}
TeamConfig.INVITE_TYPE = "Invite"

return TeamConfig
