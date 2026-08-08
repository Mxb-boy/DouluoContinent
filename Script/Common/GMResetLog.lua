local GMResetLog = {}
local RuntimeLog = UGCGameSystem.UGCRequire("Script.Common.RuntimeLog")

local MAX_MESSAGE_LENGTH = 600
local SequenceByPlayer = {}

local function NormalizeLevel(Level)
    Level = string.upper(tostring(Level or "INFO"))
    if Level ~= "ERROR" and Level ~= "WARN" then
        return "INFO"
    end
    return Level
end

local function NormalizeText(Value, MaxLength)
    local Text = tostring(Value or "")
    Text = string.gsub(Text, "[\r\n\t]+", " ")
    if #Text > MaxLength then
        Text = string.sub(Text, 1, MaxLength) .. "..."
    end
    return Text
end

local function FormatServerTime()
    local Seconds = 0
    if UGCGameSystem ~= nil and UGCGameSystem.GetServerTimeSec ~= nil then
        local Success, Value = pcall(UGCGameSystem.GetServerTimeSec)
        if Success then
            Seconds = math.floor(tonumber(Value) or 0)
        end
    end
    Seconds = Seconds % 86400
    return string.format("%02d:%02d:%02d", math.floor(Seconds / 3600),
        math.floor((Seconds % 3600) / 60), Seconds % 60)
end

function GMResetLog.Emit(PlayerController, Level, Stage, Message)
    Level = NormalizeLevel(Level)
    Stage = NormalizeText(Stage, 80)
    Message = NormalizeText(Message, MAX_MESSAGE_LENGTH)
    local PlayerKey = tostring(PlayerController and PlayerController.PlayerKey or "unknown")
    local Sequence = (SequenceByPlayer[PlayerKey] or 0) + 1
    SequenceByPlayer[PlayerKey] = Sequence
    local TimeText = FormatServerTime()
    local Text = "[TagLog] [GMReset] [GM_RESET][SERVER][" .. Level .. "][" .. Stage .. "] player=" .. PlayerKey ..
                     " seq=" .. tostring(Sequence) .. " " .. Message

    RuntimeLog.Emit(Level, Text, true)

    -- General server-log sync may be processing a large backlog. Push reset
    -- diagnostics directly to the player who initiated the GM operation.
    if PlayerController ~= nil and UnrealNetwork ~= nil and UnrealNetwork.CallUnrealRPC ~= nil and
        (UE.IsValid == nil or UE.IsValid(PlayerController)) then
        pcall(UnrealNetwork.CallUnrealRPC, PlayerController, PlayerController, "Client_GMResetLogEntry",
            Level, Stage, Message, TimeText, Sequence)
    end
end

return GMResetLog
