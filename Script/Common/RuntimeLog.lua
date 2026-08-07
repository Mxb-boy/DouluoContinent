local RuntimeLog = {}

RuntimeLog.MAX_ENTRIES = 5000
RuntimeLog.BATCH_SIZE = 25
RuntimeLog._entries = {}
RuntimeLog._sequence = 0
RuntimeLog._source = "CLIENT"
RuntimeLog._installed = false
RuntimeLog._capturing = false
RuntimeLog._serverCursor = 0
RuntimeLog._originalPrint = nil
RuntimeLog._originalUGCPrint = nil
RuntimeLog._originalError = nil
RuntimeLog._wrappedPrint = nil
RuntimeLog._wrappedUGCPrint = nil

local function NormalizeText(Value)
    local Text = tostring(Value or "")
    Text = string.gsub(Text, "[\r\n\t]+", " ")
    if #Text > 900 then
        Text = string.sub(Text, 1, 900) .. "..."
    end
    return Text
end

local function FormatTime()
    if os ~= nil and os.date ~= nil then
        local Success, Value = pcall(os.date, "%H:%M:%S")
        if Success and Value ~= nil then
            return tostring(Value)
        end
    end
    local Seconds = 0
    if UGCGameSystem ~= nil and UGCGameSystem.GetServerTimeSec ~= nil then
        local Success, Value = pcall(UGCGameSystem.GetServerTimeSec)
        if Success then
            Seconds = math.floor(tonumber(Value) or 0) % 86400
        end
    end
    return string.format("%02d:%02d:%02d", math.floor(Seconds / 3600),
        math.floor((Seconds % 3600) / 60), Seconds % 60)
end

local function NormalizeLevel(Level, Message)
    Level = string.upper(tostring(Level or "INFO"))
    if Level ~= "ERROR" and Level ~= "WARN" and Level ~= "INFO" then
        Level = "INFO"
    end
    if Level == "INFO" then
        local Text = string.lower(tostring(Message or ""))
        if string.find(Text, "%[error%]") or string.find(Text, " error") or
            string.find(Text, "failed") or string.find(Text, "失败") or string.find(Text, "异常") then
            Level = "ERROR"
        elseif string.find(Text, "%[warn%]") or string.find(Text, "warning") or
            string.find(Text, "警告") then
            Level = "WARN"
        end
    end
    return Level
end

local function AppendEntry(Source, Level, Message, TimeText, Sequence)
    Sequence = tonumber(Sequence)
    if Sequence == nil or Sequence <= 0 then
        RuntimeLog._sequence = RuntimeLog._sequence + 1
        Sequence = RuntimeLog._sequence
    else
        RuntimeLog._sequence = math.max(RuntimeLog._sequence, Sequence)
    end
    table.insert(RuntimeLog._entries, {
        Source = tostring(Source or RuntimeLog._source),
        Level = NormalizeLevel(Level, Message),
        Message = NormalizeText(Message),
        TimeText = tostring(TimeText or FormatTime()),
        Sequence = Sequence
    })
    while #RuntimeLog._entries > RuntimeLog.MAX_ENTRIES do
        table.remove(RuntimeLog._entries, 1)
    end
end

function RuntimeLog.Emit(Level, Message, bWriteOriginal)
    local Text = NormalizeText(Message)
    local NormalizedLevel = NormalizeLevel(Level, Text)
    AppendEntry(RuntimeLog._source, NormalizedLevel, Text, FormatTime())
    if bWriteOriginal ~= false then
        local Original = RuntimeLog._originalUGCPrint or RuntimeLog._originalPrint
        if Original ~= nil then
            pcall(Original, string.format("[RuntimeLog][%s] %s", NormalizedLevel, Text))
        end
    end
end

function RuntimeLog.Info(Message)
    RuntimeLog.Emit("INFO", Message, true)
end

function RuntimeLog.Warn(Message)
    RuntimeLog.Emit("WARN", Message, true)
end

function RuntimeLog.Error(Message)
    RuntimeLog.Emit("ERROR", Message, true)
end

local function JoinArguments(...)
    local Values = {}
    for Index = 1, select("#", ...) do
        Values[Index] = tostring(select(Index, ...))
    end
    return table.concat(Values, " ")
end

local function CaptureAndForward(Original, Level, ...)
    local Message = JoinArguments(...)
    if not RuntimeLog._capturing then
        RuntimeLog._capturing = true
        AppendEntry(RuntimeLog._source, Level, Message, FormatTime())
        RuntimeLog._capturing = false
    end
    if Original ~= nil then
        return pcall(Original, ...)
    end
    return true
end

function RuntimeLog.Install(Source)
    if RuntimeLog._installed then
        -- Some editor builds inject ugcprint after the first Lua module load.
        -- Rebind that late function while keeping the original print wrapper intact.
        local CurrentUGCPrint = rawget(_G, "ugcprint")
        if CurrentUGCPrint ~= nil and CurrentUGCPrint ~= RuntimeLog._wrappedUGCPrint and
            RuntimeLog._originalUGCPrint == RuntimeLog._originalPrint then
            RuntimeLog._originalUGCPrint = CurrentUGCPrint
            RuntimeLog._wrappedUGCPrint = function(...)
                return CaptureAndForward(RuntimeLog._originalUGCPrint, "INFO", ...)
            end
            _G.ugcprint = RuntimeLog._wrappedUGCPrint
        end
        return RuntimeLog
    end
    RuntimeLog._source = string.upper(tostring(Source or "CLIENT")) == "SERVER" and "SERVER" or "CLIENT"
    RuntimeLog._originalPrint = rawget(_G, "print")
    RuntimeLog._originalUGCPrint = rawget(_G, "ugcprint") or RuntimeLog._originalPrint
    RuntimeLog._originalError = rawget(_G, "error")

    if RuntimeLog._originalPrint ~= nil then
        RuntimeLog._wrappedPrint = function(...)
            return CaptureAndForward(RuntimeLog._originalPrint, "INFO", ...)
        end
        _G.print = RuntimeLog._wrappedPrint
    end
    if RuntimeLog._originalUGCPrint ~= nil then
        RuntimeLog._wrappedUGCPrint = function(...)
            return CaptureAndForward(RuntimeLog._originalUGCPrint, "INFO", ...)
        end
        _G.ugcprint = RuntimeLog._wrappedUGCPrint
    end
    if RuntimeLog._originalError ~= nil then
        _G.error = function(Message, Level)
            if not RuntimeLog._capturing then
                RuntimeLog._capturing = true
                AppendEntry(RuntimeLog._source, "ERROR", Message, FormatTime())
                RuntimeLog._capturing = false
            end
            return RuntimeLog._originalError(Message, Level)
        end
    end
    RuntimeLog._installed = true
    AppendEntry(RuntimeLog._source, "INFO", "[RuntimeLog] installed source=" .. RuntimeLog._source, FormatTime())
    return RuntimeLog
end

function RuntimeLog.GetEntries()
    return RuntimeLog._entries
end

function RuntimeLog.GetLatestServerSequence()
    local Latest = RuntimeLog._serverCursor
    for _, Entry in ipairs(RuntimeLog._entries) do
        if Entry.Source == "SERVER" then
            Latest = math.max(Latest, tonumber(Entry.Sequence) or 0)
        end
    end
    return Latest
end

function RuntimeLog.Clear()
    RuntimeLog._serverCursor = RuntimeLog.GetLatestServerSequence()
    RuntimeLog._entries = {}
end

function RuntimeLog.AppendRemote(Sequence, TimeText, Level, Message)
    Sequence = tonumber(Sequence) or 0
    if Sequence <= RuntimeLog._serverCursor then
        return
    end
    AppendEntry("SERVER", Level, Message, TimeText, Sequence)
    RuntimeLog._serverCursor = math.max(RuntimeLog._serverCursor, Sequence)
end

function RuntimeLog.AppendForwarded(Source, TimeText, Level, Message)
    AppendEntry(Source, Level, Message, TimeText)
end

function RuntimeLog.GetServerBatch(AfterSequence, BatchSize)
    AfterSequence = tonumber(AfterSequence) or 0
    BatchSize = math.min(tonumber(BatchSize) or RuntimeLog.BATCH_SIZE, RuntimeLog.BATCH_SIZE)
    local Lines, LastSequence, Count = {}, AfterSequence, 0
    for _, Entry in ipairs(RuntimeLog._entries) do
        if Entry.Source == "SERVER" and (tonumber(Entry.Sequence) or 0) > AfterSequence then
            Count = Count + 1
            LastSequence = tonumber(Entry.Sequence) or LastSequence
            table.insert(Lines, table.concat({LastSequence, Entry.TimeText, Entry.Level, Entry.Message}, "\t"))
            if Count >= BatchSize then
                break
            end
        end
    end
    local More = false
    for _, Entry in ipairs(RuntimeLog._entries) do
        if Entry.Source == "SERVER" and (tonumber(Entry.Sequence) or 0) > LastSequence then
            More = true
            break
        end
    end
    return table.concat(Lines, "\n"), LastSequence, More and 1 or 0
end

function RuntimeLog.SetServerCursor(Sequence)
    RuntimeLog._serverCursor = math.max(RuntimeLog._serverCursor, tonumber(Sequence) or 0)
end

return RuntimeLog
