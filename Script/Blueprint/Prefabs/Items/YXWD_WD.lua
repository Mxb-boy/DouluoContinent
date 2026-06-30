---@class YXWD_WD_C:Template_Consumable_Drink_C
--Edit Below--
local YXWD_WD = {}
local DEFAULT_BUFF_DURATION_SECONDS = -2

local function SetYXWDInvincibleBuffActive(PlayerState, DurationSeconds)
    if PlayerState == nil then
        return
    end

    local Duration = tonumber(DurationSeconds)
    if Duration == nil then
        Duration = DEFAULT_BUFF_DURATION_SECONDS
    end

    if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
        PlayerState:SetYXWD_InvincibleBuffActive(true)
    else
        PlayerState.YXWD_InvincibleBuffActive = true
    end
    PlayerState.YXWD_InvincibleBuffToken = (tonumber(PlayerState.YXWD_InvincibleBuffToken) or 0) + 1
    local BuffToken = PlayerState.YXWD_InvincibleBuffToken

    if PlayerState.SetYXWD_InvincibleBuff ~= nil then
        PlayerState:SetYXWD_InvincibleBuff(Duration == -2)
    else
        PlayerState.YXWD_InvincibleBuff = Duration == -2 and 1 or 0
        if PlayerState.SaveToArchive ~= nil then
            PlayerState:SaveToArchive()
        end
    end

    if Duration == -2 then
        return
    end

    if Duration <= 0 then
        if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
            PlayerState:SetYXWD_InvincibleBuffActive(false)
        else
            PlayerState.YXWD_InvincibleBuffActive = false
        end
        return
    end

    if UGCTimerUtility ~= nil and UGCTimerUtility.CreateLuaTimer ~= nil then
        pcall(UGCTimerUtility.CreateLuaTimer, Duration, function()
            if PlayerState ~= nil and PlayerState.YXWD_InvincibleBuffToken == BuffToken then
                if PlayerState.SetYXWD_InvincibleBuffActive ~= nil then
                    PlayerState:SetYXWD_InvincibleBuffActive(false)
                else
                    PlayerState.YXWD_InvincibleBuffActive = false
                end
            end
        end, false)
    end
end

local function SafeGetField(Object, FieldName)
    if Object == nil then
        return nil
    end

    local Success, Result = pcall(function()
        return Object[FieldName]
    end)

    if Success then
        return Result
    end

    return nil
end

local function SafeGetIndex(Object, Index)
    if Object == nil then
        return nil
    end

    local Success, Result = pcall(function()
        return Object[Index]
    end)

    if Success then
        return Result
    end

    return nil
end

local function ReadNumber(value)
    local NumberValue = tonumber(value)
    if NumberValue ~= nil then
        return NumberValue
    end
    return nil
end

local function ReadBuffDurationFromStruct(BuffConfig)
    if BuffConfig == nil then
        return nil
    end

    local Duration = ReadNumber(SafeGetField(BuffConfig, "OverrideTime"))
        or ReadNumber(SafeGetField(BuffConfig, "Duration"))
        or ReadNumber(SafeGetField(BuffConfig, "BuffDuration"))
        or ReadNumber(SafeGetField(BuffConfig, "LastTime"))
        or ReadNumber(SafeGetField(BuffConfig, "Time"))

    return Duration
end

local function GetYXWDBuffDurationSeconds(ItemHandle)
    if ItemHandle == nil then
        return DEFAULT_BUFF_DURATION_SECONDS
    end

    local Duration = ReadNumber(SafeGetField(ItemHandle, "OverrideTime"))
        or ReadNumber(SafeGetField(ItemHandle, "Duration"))
        or ReadNumber(SafeGetField(ItemHandle, "BuffDuration"))

    if Duration ~= nil then
        return Duration
    end

    local PostBuffList = SafeGetField(ItemHandle, "PostBuffList")
    if PostBuffList ~= nil then
        Duration = ReadBuffDurationFromStruct(SafeGetIndex(PostBuffList, 1))
            or ReadBuffDurationFromStruct(SafeGetIndex(PostBuffList, 0))
        if Duration ~= nil then
            return Duration
        end
    end

    return DEFAULT_BUFF_DURATION_SECONDS
end

local function SendYXWDBuffIconRefresh(PlayerController, DurationSeconds)
    if PlayerController == nil then
        return
    end

    if UnrealNetwork == nil or UnrealNetwork.CallUnrealRPC == nil then
        return
    end

    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_YXWDInvincibleBuffChanged", 1, DurationSeconds)
end

function YXWD_WD:CanUseV2()
    if YXWD_WD.SuperClass ~= nil and YXWD_WD.SuperClass.CanUseV2 ~= nil then
        return YXWD_WD.SuperClass.CanUseV2(self)
    end
    return true
end

function YXWD_WD:OnUseV2()
    if YXWD_WD.SuperClass ~= nil and YXWD_WD.SuperClass.OnUseV2 ~= nil then
        YXWD_WD.SuperClass.OnUseV2(self)
    end

    local OwnBackpackComponent = UGCItemSystemV2.GetOwnBackpackComponent(self)
    if OwnBackpackComponent == nil then
        return
    end

    local PlayerController = OwnBackpackComponent:GetOwner()
    if PlayerController == nil then
        return
    end

    local PlayerState = PlayerController.PlayerState
    if PlayerState == nil then
        local PlayerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(PlayerController)
        if PlayerPawn ~= nil then
            PlayerState = PlayerPawn.PlayerState
        end
    end

    if PlayerState == nil then
        return
    end

    local BuffDurationSeconds = GetYXWDBuffDurationSeconds(self)
    SetYXWDInvincibleBuffActive(PlayerState, BuffDurationSeconds)

    self.YXWD_PendingBuffIconNotify = true
    self.YXWD_PendingBuffIconPlayerController = PlayerController
    self.YXWD_PendingBuffDurationSeconds = BuffDurationSeconds
end

function YXWD_WD:UGC_OnStopUse(Reason)
    if YXWD_WD.SuperClass ~= nil and YXWD_WD.SuperClass.UGC_OnStopUse ~= nil then
        YXWD_WD.SuperClass.UGC_OnStopUse(self, Reason)
    end

    if self.YXWD_PendingBuffIconNotify ~= true then
        return
    end

    self.YXWD_PendingBuffIconNotify = false

    local PlayerController = self.YXWD_PendingBuffIconPlayerController
    local BuffDurationSeconds = self.YXWD_PendingBuffDurationSeconds
    self.YXWD_PendingBuffIconPlayerController = nil
    self.YXWD_PendingBuffDurationSeconds = nil

    SendYXWDBuffIconRefresh(PlayerController, BuffDurationSeconds)
end

return YXWD_WD
