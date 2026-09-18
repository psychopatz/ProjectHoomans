-- Runtime and presentation-boundary primitives shared by PBrainZ flows.
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_State"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ProviderAvailability"

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Internal = PNC.PBrainZ.Internal
local Runtime = Internal.Runtime or {}
Internal.Runtime = Runtime
local State = Internal.State
local Availability = Internal.ProviderAvailability

local Trace = PsychopatzCore and PsychopatzCore.DebugTrace

function Runtime.Trim(value, limit)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if limit and #value > limit then
        value = string.sub(value, 1, limit)
    end
    return value
end

function Runtime.TraceEnabled()
    return Trace and Trace.IsEnabled and Trace.IsEnabled() == true
end

function Runtime.IsBridgeEnabled()
    local bootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
    return bootstrap and bootstrap.IsEnabled
        and bootstrap:IsEnabled() == true
end

PNC.PBrainZ.IsBridgeEnabled = PNC.PBrainZ.IsBridgeEnabled
    or Runtime.IsBridgeEnabled

function Runtime.GetProviderStatus()
    if not Runtime.IsBridgeEnabled() then
        return {
            source = "bridge",
            available = false,
            ready = false,
            status = "disabled",
            reason = "bridge_disabled",
        }
    end
    -- The test harness and tools that load Lua outside Project Zomboid do not
    -- expose getFileReader.  Preserve their bridge-only behavior; the game
    -- itself always has getFileReader, so production remains fail-closed when
    -- the pbrainz heartbeat is missing or stale.
    if type(getFileReader) ~= "function" then
        return {
            source = "bridge_legacy",
            available = true,
            ready = true,
            status = "legacy_bridge",
        }
    end
    return Availability.Read()
end

function Runtime.IsProviderAvailable()
    return Runtime.GetProviderStatus().ready == true
end

PNC.PBrainZ.GetProviderStatus = PNC.PBrainZ.GetProviderStatus
    or Runtime.GetProviderStatus
PNC.PBrainZ.IsProviderAvailable = PNC.PBrainZ.IsProviderAvailable
    or Runtime.IsProviderAvailable

function Runtime.Now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs()
        or 0
end

function Runtime.CurrentView()
    return PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
end

function Runtime.LogText(value)
    value = Runtime.Trim(value)
    value = string.gsub(value, "[\r\n]+", " ")
    if #value > State.MAX_LOG_TEXT then
        value = string.sub(value, 1, State.MAX_LOG_TEXT - 1) .. "…"
    end
    return value ~= "" and value or "<empty>"
end

function Runtime.Log(event, details)
    if print then
        print("[PNC][LLM] " .. tostring(event) .. " " .. tostring(details or ""))
    end
end

function Runtime.CleanResponseText(value)
    value = Runtime.Trim(value)
    -- Text-only providers such as Horde may stop inside the optional action
    -- envelope. It is a protocol fragment, never NPC dialogue. Complete
    -- envelopes should already have been extracted by PBrainZ; this is a
    -- defensive presentation boundary for older or partial bridge replies.
    value = string.gsub(
        value,
        "<projecthoomans%-action>[%s%S]-</projecthoomans%-action>",
        ""
    )
    value = string.gsub(
        value,
        "<projecthoomans%-action[^>]*>[%s%S]*$",
        ""
    )
    value = string.gsub(value, "</projecthoomans%-action%s*>", "")
    local lowered = string.lower(value)
    local scaffoldStart = string.find(lowered, "^%s*instruction%s*:")
        or string.find(lowered, "\n%s*instruction%s*:")
        or string.find(lowered, "^%s*response%s*$")
        or string.find(lowered, "\n%s*response%s*$")
        or string.find(lowered, "^%s*answer%s*:")
        or string.find(lowered, "\n%s*answer%s*:")
        or string.find(lowered, "^%s*analysis%s*:")
        or string.find(lowered, "\n%s*analysis%s*:")
        or string.find(lowered, "^%s*self[- ]correction%s*:")
        or string.find(lowered, "\n%s*self[- ]correction%s*:")
        or string.find(lowered, "^%s*final%s+check%s*:")
        or string.find(lowered, "\n%s*final%s+check%s*:")
        or string.find(lowered, "^%s*new%s+attempt%s*:")
        or string.find(lowered, "\n%s*new%s+attempt%s*:")
    if scaffoldStart then
        value = Runtime.Trim(string.sub(value, 1, scaffoldStart - 1))
        if value == "" then return "" end
        return value
    end
    local providerMeta = string.find(lowered, "self[- ]correction%s+check")
        or string.find(lowered, "last turn['’]s instructions")
        or string.find(lowered, "prompt for the final response")
        or string.find(lowered, "player['’]s last message%s*:")
        or string.find(lowered, "required action%s*:")
    if providerMeta then return "" end
    return Runtime.Trim(value)
end

function Runtime.ConversationTokenOf(packet)
    local context = packet and packet.conversation_context or nil
    local token = context and context.conversation_token or nil
    if token == nil or Runtime.Trim(token) == "" then return nil end
    return tostring(token)
end

local function replaceAmbientIdentity(text, fullName, firstName, surname)
    local names = { fullName, surname }
    local replacement = tostring(firstName or "")
    if replacement == "" then return text end
    for _, name in ipairs(names) do
        name = Runtime.Trim(name)
        if name ~= "" and name ~= replacement then
            -- Escape Lua pattern punctuation so names such as "O'Neil" and
            -- hyphenated surnames are treated as literal text.
            local pattern = string.gsub(name, "([^%w])", "%%%1")
            text = string.gsub(text, pattern, replacement)
        end
    end
    return text
end

function Runtime.EnforceAmbientNamePolicy(text, packet)
    local context = packet and packet.conversation_context or {}
    text = replaceAmbientIdentity(
        text,
        context.player_full_name,
        context.player_first_name,
        context.player_surname
    )
    return replaceAmbientIdentity(
        text,
        context.victim_full_name,
        context.victim_first_name,
        context.victim_surname
    )
end

function Runtime.DeclinedPortraitAnimation(results)
    for _, result in ipairs(type(results) == "table" and results or {}) do
        local replyContext = type(result.replyContext) == "table"
            and result.replyContext or nil
        local authoritativeDecline = result.accepted ~= true
            and replyContext
            and replyContext.outcome == "rejected"
            and (result.authoritative == true
                or replyContext.authoritative == true)
        if authoritativeDecline then
            return "reaction.thumbsdown"
        end
    end
    return nil
end

return Runtime
