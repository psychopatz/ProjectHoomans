if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal

local function lineSpeaker(context, line)
    local role = type(line) == "table" and line.speakerRole or nil
    role = tostring(role or "primary")
    if role == "secondary" then
        return role, context and context.secondarySpeakerNPCID or nil
    end
    return "primary", context and context.speakerNPCID or nil
end

local function chancePasses(chance, hookName)
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    local roll
    local hook = Discovery[hookName]
    if type(hook) == "function" then
        roll = hook()
    elseif ZombRand then
        roll = ZombRand(100)
    else
        roll = math.random(0, 99)
    end
    return (tonumber(roll) or 99) < chance
end

local function signalRollPasses()
    return chancePasses(Discovery.RadioSignalChance(), "RadioSignalRoll")
end

local function markRadioAttempt(record, at)
    record.lastRadioScanAt = at
    record.radioScanCount = (tonumber(record.radioScanCount) or 0) + 1
    Discovery.Dirty = true
end

local function compactRadioBroadcast(message, context)
    if type(message) ~= "table" or type(message.lines) ~= "table" then
        return nil
    end
    local output = {
        packID = tostring(message.packID or ""),
        eventType = context and context.eventType or "discovery",
        -- This is an internal voice-continuity identity, not a player-facing
        -- disclosure. identityIntroduced only gates the flavor introduction;
        -- it does not mean that identity.name knowledge was granted.
        speakerNPCID = context and context.speakerNPCID or nil,
        secondarySpeakerNPCID = context and context.secondarySpeakerNPCID or nil,
        speech = {
            effect_profile = "radio",
            environment = "normal",
            intensity = 0.85,
        },
        lines = {},
    }
    for _, line in ipairs(message.lines) do
        local value = type(line) == "table" and line.text or line
        local speakerRole, speakerID = lineSpeaker(context, line)
        value = tostring(value or "")
        value = string.gsub(value, "<[^>]+>", "")
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")
        if value ~= "" then
            output.lines[#output.lines + 1] = {
                text = string.sub(value, 1, 600),
                speakerRole = speakerRole,
                speakerNPCID = speakerID,
            }
        end
    end
    return #output.lines > 0 and output or nil
end


Internal.LineSpeaker = lineSpeaker
Internal.ChancePasses = chancePasses
Internal.SignalRollPasses = signalRollPasses
Internal.MarkRadioAttempt = markRadioAttempt
Internal.CompactRadioBroadcast = compactRadioBroadcast
