-- Local, client-only JSON reports for semantic clarification outcomes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Telemetry = PNC.Semantics.SemanticTelemetryStorage or {}
PNC.Semantics.SemanticTelemetryStorage = Telemetry

local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
local ROOT = "Hoomans/Telemetry"
local INDEX_PATH = "Hoomans/TelemetryIndex.txt"
local LIMITS = { maxString = 8192, maxDepth = 8, maxCollection = 32 }
local MAX_TRIGGER_LENGTH = 4096
local MAX_DETAILS_LENGTH = 2048
local MAX_SEMANTIC_LENGTH = 128

local function text(value, maximum)
    if value == nil then return "" end
    local output = tostring(value)
    if maximum and #output > maximum then
        output = string.sub(output, 1, maximum)
    end
    return output
end

local function optionalText(value, maximum)
    if value == nil then return nil end
    local output = text(value, maximum)
    return output ~= "" and output or nil
end

local function filenamePart(value)
    local output = string.lower(text(value, MAX_TRIGGER_LENGTH))
    output = string.gsub(output, "[^%w]+", "_")
    output = string.gsub(output, "^_+", "")
    output = string.gsub(output, "_+$", "")
    output = string.sub(output, 1, 56)
    output = string.gsub(output, "_+$", "")
    return output ~= "" and output or "sentence"
end

local function pathFor(fileName)
    return ROOT .. "/" .. fileName
end

local function fileExists(path)
    if type(getFileReader) ~= "function" then
        return nil, "file_reader_unavailable"
    end
    local reader = getFileReader(path, false)
    if not reader then return false end
    reader:close()
    return true
end

local function readNextIndex()
    if type(getFileReader) ~= "function" then
        return nil, "file_reader_unavailable"
    end
    local reader = getFileReader(INDEX_PATH, false)
    if not reader then return 1 end
    local index = tonumber(reader:readLine())
    reader:close()
    if not index or index < 1 then return 1 end
    if index > 2147483647 then
        return nil, "telemetry_index_invalid"
    end
    return math.floor(index)
end

local function writeNextIndex(index)
    if type(getFileWriter) ~= "function" then
        return false, "file_writer_unavailable"
    end
    local writer = getFileWriter(INDEX_PATH, true, false)
    if not writer then return false, "index_file_unavailable" end
    writer:write(tostring(index))
    writer:close()
    return true
end

local function nextFileName(triggerText)
    local triggerPart = filenamePart(triggerText)
    local index, reason = readNextIndex()
    if not index then return nil, reason end
    while true do
        if index > 2147483647 then
            return nil, "telemetry_index_exhausted"
        end
        local fileName = "Telemetry_" .. tostring(index)
            .. "_" .. triggerPart .. ".json"
        local exists, reason = fileExists(pathFor(fileName))
        if exists == nil then return nil, reason end
        if not exists then return fileName, index end
        index = index + 1
    end
end

local function cleanDecision(input)
    local decision = type(input.outcome) == "table" and input.outcome or {}
    return {
        source = optionalText(input.source, 32),
        route = optionalText(decision.route, 80),
        branch = optionalText(decision.branch, 80),
        reason = optionalText(decision.reason, 160),
        confidence = tonumber(decision.confidence),
        intent = optionalText(decision.intent, 96),
        speechAct = optionalText(decision.speechAct, 80),
        recognizedAction = optionalText(decision.action, 80),
        parser = optionalText(decision.parser, 80),
        pattern = optionalText(decision.pattern, 160),
        provider = optionalText(decision.provider, 80),
    }
end

function Telemetry.Save(input)
    input = type(input) == "table" and input or {}
    local triggerText = text(input.rawText, MAX_TRIGGER_LENGTH)
    if triggerText == "" then return false, "trigger_text_missing" end

    local selectedSemantic = text(input.selectedSemantic, MAX_SEMANTIC_LENGTH)
    if selectedSemantic == "" then
        return false, "selected_semantic_missing"
    end

    local playerReport = {
        selectedSemantic = selectedSemantic,
        requestedNewSemantic = input.requestedNewSemantic == true,
        proposedSemantic = optionalText(
            input.proposedSemantic, MAX_SEMANTIC_LENGTH),
        details = text(input.details, MAX_DETAILS_LENGTH),
    }
    local payload = {
        schemaVersion = 1,
        kind = "ProjectHoomans.SemanticTelemetry",
        createdAtMs = type(getTimeInMillis) == "function"
            and getTimeInMillis() or nil,
        trigger = {
            rawText = triggerText,
            normalizedText = text(input.normalizedText, MAX_TRIGGER_LENGTH),
        },
        semanticResult = cleanDecision(input),
        playerReport = playerReport,
    }
    local encoded = Json.Encode(payload, LIMITS)
    if type(encoded) ~= "string" or encoded == "" then
        return false, "json_encode_failed"
    end

    local fileName, index, nameReason = nextFileName(triggerText)
    if not fileName then return false, nameReason end
    if type(getFileWriter) ~= "function" then
        return false, "file_writer_unavailable"
    end
    -- Reserve the global index before writing the report. A failed report
    -- write can leave a gap, but it can never cause an earlier number to be
    -- reused for a different trigger sentence.
    local reserved, indexReason = writeNextIndex(index + 1)
    if not reserved then return false, indexReason end

    local path = pathFor(fileName)
    local writer = getFileWriter(path, true, false)
    if not writer then return false, "file_unavailable" end
    writer:write(encoded)
    writer:close()
    return true, fileName, path
end

Telemetry.ROOT = ROOT

return Telemetry
