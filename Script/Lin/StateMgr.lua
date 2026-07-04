local StateMgr = {
    BaseMaxHp = 0,
    BaseAttack = 0,
    DaoJuAdd = 0,
    PaiHangAdd = 0,
    ChiBang = 0,
    WuQi = 0,
    ChengHao = 0,
    JingJieName = "",
    JingJieAddMaxHp = 0,
    JingJieAddAtk = 0,
    BeiLv = 100
}

local FinalAttack = 0
local FinalMaxHp = 0
local DaoJuAddNum_Atk = 0
local DaoJuAddNum_Hp = 0
local DefaultBaseAttack = 40
local DefaultBaseMaxHp = 100

local L_Com = UGCGameSystem.UGCRequire('Script.Lin.L_Com')

function StateMgr:SetUI(ui)
    self.UI = ui
    self:Init()
end

function StateMgr:SyncFromPlayerState()
    local playerState = UGCGameSystem.GetLocalPlayerState()
    if playerState == nil then
        return false
    end
    self.BaseAttack = playerState:GetBaseAttack()
    self.BaseMaxHp = playerState:GetBaseMaxHp()
    if playerState.GetProbability_Bonus ~= nil then
        self.BeiLv = playerState:GetProbability_Bonus()
    else
        self.BeiLv = tonumber(playerState.Probability_Bonus) or self.BeiLv
    end
    return true
end

function StateMgr:RefreshFromPlayerState(pawn, baseAttack, baseMaxHp, hp, maxHp, bFillHealth)
    self:SyncFromPlayerState()
    self.BaseAttack = tonumber(baseAttack) or self.BaseAttack
    self.BaseMaxHp = tonumber(baseMaxHp) or self.BaseMaxHp
    self:CountAll(pawn, hp, maxHp, bFillHealth)
end

function StateMgr:Init()
    self:SyncFromPlayerState()
    self:PaiHangTextShow(0, true)
    self:ChiBangTextShow(0, true)
    self:WuQiTextShow(0, true)
    self:ChengHaoTextShow(0, true)
    self:JingJieTextShow(1, true)
    self:BeiLvTextShow(self.BeiLv, true)
    self:CountAll()
end

function StateMgr:PaiHangTextShow(Num, SkipCount)
    self.PaiHangAdd = Num
    self.UI.TextBlock_109:SetText("排行加成:" .. self.PaiHangAdd .. "%")
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:ChiBangTextShow(Num, SkipCount)
    self.ChiBang = Num
    self.UI.TextBlock_110:SetText("翅膀加成:" .. self.ChiBang .. "%")
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:WuQiTextShow(Num, SkipCount)
    self.WuQi = Num
    self.UI.TextBlock_112:SetText("武器加成:" .. self.WuQi .. "%")
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:ChengHaoTextShow(Num, SkipCount)
    self.ChengHao = Num
    self.UI.TextBlock_114:SetText("称号加成:" .. self.ChengHao .. "%")
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:JingJieTextShow(Num, SkipCount)
    self.JingJieName = L_Com:GetJingJieName(Num)
    self.JingJieAddMaxHp = L_Com:GetJingJieAddMaxHp(Num)
    self.JingJieAddAtk = L_Com:GetJingJieAddAtk(Num)

    self.UI.TextBlock_49:SetText("境界:" .. self.JingJieName)
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:BeiLvTextShow(Num, SkipCount)
    self.BeiLv = tonumber(Num) or 100
    local playerState = UGCGameSystem.GetLocalPlayerState()
    if playerState ~= nil and playerState.SetProbability_Bonus ~= nil then
        playerState:SetProbability_Bonus(self.BeiLv)
    end
    self.UI.TextBlock_50:SetText("倍率加成:" .. self.BeiLv .. "%")
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:CountAll(pawn, hp, maxHp, bFillHealth)
    self:CountFinalAttack(pawn)
    self:CountFinalMaxHp(pawn, hp, maxHp, bFillHealth)
    self:DaoJuAddTextShow(true)
    self:CountFinalZhanLi()
end

function StateMgr:CountFinalAttack(pawn)
    local baseAttack = self.BaseAttack
    local AttackAddForce = self.PaiHangAdd + self.ChiBang + self.WuQi + self.ChengHao + self.JingJieAddAtk
    FinalAttack = baseAttack * (1 + AttackAddForce / 100)
    pawn = pawn or UGCGameSystem.GetLocalPlayerPawn()
    if pawn == nil then
        return
    end
    if pawn.HasAuthority ~= nil and pawn:HasAuthority() then
        UGCAttributeSystem.SetGameAttributeValue(pawn, "AttackPower", FinalAttack)
    else
        local pc = GameplayStatics.GetPlayerController(self.UI, 0)
        UnrealNetwork.CallUnrealRPC(pc, pc, "Server_SetFinalAttack", FinalAttack)
    end
    if self.UI ~= nil and self.UI.gjl ~= nil then
        self.UI.gjl:SetText("攻击力:" .. math.floor(FinalAttack))
    end
    DaoJuAddNum_Atk = FinalAttack - self.BaseAttack
end

function StateMgr:RefreshHpText(pawn, showMaxHp, showHp)
    pawn = pawn or UGCGameSystem.GetLocalPlayerPawn()
    if pawn == nil then
        return
    end

    local hp = tonumber(showHp) or UGCPawnAttrSystem.GetHealth(pawn) or 0
    local maxHp = tonumber(showMaxHp) or UGCPawnAttrSystem.GetHealthMax(pawn) or 0
    if self.UI ~= nil and self.UI.hp ~= nil then
        self.UI.hp:SetText("生命值:" .. math.floor(hp) .. "/" .. math.floor(maxHp))
    end
end

function StateMgr:CountFinalMaxHp(pawn, showHp, showMaxHp, bFillHealth)
    local baseMaxHp = self.BaseMaxHp
    local MaxHpAddForce = self.PaiHangAdd + self.ChiBang + self.ChengHao + self.JingJieAddMaxHp
    FinalMaxHp = baseMaxHp * (1 + MaxHpAddForce / 100)
    pawn = pawn or UGCGameSystem.GetLocalPlayerPawn()
    if pawn == nil then
        return
    end
    if pawn.HasAuthority ~= nil and pawn:HasAuthority() then
        UGCPawnAttrSystem.SetHealthMax(pawn, FinalMaxHp)
        if bFillHealth then
            UGCPawnAttrSystem.SetHealth(pawn, FinalMaxHp)
        end
    else
        local pc = GameplayStatics.GetPlayerController(self.UI, 0)
        UnrealNetwork.CallUnrealRPC(pc, pc, "Server_SetFinalMaxHp", FinalMaxHp, bFillHealth == true)
    end
    DaoJuAddNum_Hp = FinalMaxHp - self.BaseMaxHp
    self:RefreshHpText(pawn, showMaxHp or FinalMaxHp, bFillHealth and FinalMaxHp or showHp)
end

function StateMgr:DaoJuAddTextShow(SkipCount)
    self.UI.TextBlock_0:SetText("HP" .. math.floor(DaoJuAddNum_Hp) .. "/ATK" .. math.floor(DaoJuAddNum_Atk))
    if not SkipCount then
        self:CountAll()
    end
end

function StateMgr:CountFinalZhanLi()
    local FinalZhanLi = FinalAttack + FinalMaxHp
    self.FinalZhanLi = FinalZhanLi
    self.UI.TextBlock_303:SetText("战力" .. FinalZhanLi)
end

function StateMgr:GetFinalZhanLi()
    return self.FinalZhanLi
end

function StateMgr:GetFinalMaxHp()
    return FinalMaxHp
end

return StateMgr
