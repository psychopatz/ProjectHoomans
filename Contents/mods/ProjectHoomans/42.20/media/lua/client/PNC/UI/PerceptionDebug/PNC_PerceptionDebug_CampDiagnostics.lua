-- Event-driven camp command diagnostics for the perception preview.
--
-- This is deliberately not a scanner and does not install an update hook. It
-- records only the small primitive boundary needed to compare the client's
-- local hint with the later authoritative result in the next explicit scan.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Diagnostics = PNC.PerceptionDebug.CampDiagnostics or {}
PNC.PerceptionDebug.CampDiagnostics = Diagnostics

Diagnostics.VERSION = 1
Diagnostics.revision = tonumber(Diagnostics.revision) or 0
Diagnostics.client = Diagnostics.client
Diagnostics.server = Diagnostics.server
Diagnostics.last = Diagnostics.last

local function text(value, maximum)
    if value == nil then return nil end
    local result = tostring(value)
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function now()
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        local ok, value = pcall(core.Now)
        if ok and number(value) then return value end
    end
    return 0
end

local function hintCopy(hint)
    if type(hint) ~= "table" then return nil end
    return {
        source = text(hint.source, 64),
        kind = text(hint.kind, 32),
        scope = text(hint.scope or hint.siteScope, 32),
        siteID = text(hint.siteID, 128),
        roomID = text(hint.roomID, 128),
        buildingID = text(hint.buildingID, 128),
        roomType = text(hint.roomType, 48),
        roomName = text(hint.roomName, 64),
        campfireID = text(hint.campfireID, 128),
        label = text(hint.label, 64),
        x = number(hint.x),
        y = number(hint.y),
        z = number(hint.z),
        radius = number(hint.radius),
        score = number(hint.score),
    }
end

local function copyRecord(record)
    if type(record) ~= "table" then return nil end
    return {
        stage = text(record.stage, 16),
        status = text(record.status, 16),
        commandID = text(record.commandID, 32),
        npcID = text(record.npcID, 128),
        scope = text(record.scope, 32),
        reason = text(record.reason, 128),
        requestID = text(record.requestID, 128),
        commandSource = text(record.commandSource, 32),
        at = number(record.at),
        hint = hintCopy(record.hint),
    }
end

local function record(stage, status, reason, context, hint)
    context = type(context) == "table" and context or {}
    local value = {
        stage = text(stage, 16),
        status = text(status, 16),
        commandID = text(context.commandID or "camp", 32),
        npcID = text(context.npcID or context.id, 128),
        scope = text(context.scope, 32),
        reason = text(reason, 128),
        requestID = text(context.requestID, 128),
        commandSource = text(context.commandSource or context.origin, 32),
        at = now(),
        hint = hintCopy(hint),
    }
    Diagnostics.revision = Diagnostics.revision + 1
    Diagnostics[stage] = value
    Diagnostics.last = value
    return copyRecord(value)
end

function Diagnostics.RecordClient(status, reason, context, hint)
    return record("client", status, reason, context, hint)
end

function Diagnostics.RecordServer(args)
    local hint
    args = type(args) == "table" and args or {}
    hint = args.campSiteHint
    if type(hint) ~= "table"
        and (args.siteLabel or args.siteScope or args.siteID
            or args.siteRoomType)
    then
        hint = {
            source = "server_authoritative_site",
            scope = args.siteScope,
            siteID = args.siteID,
            roomType = args.siteRoomType,
            label = args.siteLabel,
        }
    end
    return record("server", args.accepted == true and "ACCEPTED"
        or "REJECTED", args.reason, {
            commandID = args.commandID,
            npcID = args.npcID or args.id,
            scope = args.scope,
            requestID = args.requestID,
            commandSource = args.commandSource,
        }, hint)
end

function Diagnostics.Get()
    return {
        version = Diagnostics.VERSION,
        revision = Diagnostics.revision,
        last = copyRecord(Diagnostics.last),
        client = copyRecord(Diagnostics.client),
        server = copyRecord(Diagnostics.server),
    }
end

function Diagnostics.Clear()
    Diagnostics.revision = Diagnostics.revision + 1
    Diagnostics.client = nil
    Diagnostics.server = nil
    Diagnostics.last = nil
end

return Diagnostics
