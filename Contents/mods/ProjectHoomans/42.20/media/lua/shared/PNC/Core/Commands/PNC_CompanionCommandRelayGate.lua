--[[
    Radio relay decision for companion commands.

    The colonist window (client) and the command application (server) must reach
    the same verdict or the UI would offer an order the authority then refuses.
    Both sides therefore build the same plain fact table and ask this module:

        facts = {
            companion, owned, dead            -- relationship / life state
            reachableDirectly                 -- accepted by CanPlayerCommand
            relayAllowed                      -- command opts into radio relay
            playerRadio                       -- player has a live two-way set
            npcRadio                          -- colonist carries radio gear
        }

    Fact gathering stays with each side because the sources differ (a Java
    player on the server, a colonist snapshot on the client); the rules and the
    player-facing reasons live here only.
]]

PNC = PNC or {}
PNC.CommandRelayGate = PNC.CommandRelayGate or {}

local Gate = PNC.CommandRelayGate

Gate.DIRECT = "direct"
Gate.RELAY = "radio_relay"

-- Every rejection reason maps to one translatable line so a disabled button
-- can always state its cause instead of silently greying out.
local REASONS = {
    dead = {
        key = "UI_PNC_RadioRelay_ReasonDead",
        fallback = "This colonist is dead.",
    },
    not_companion = {
        key = "UI_PNC_RadioRelay_ReasonNotCompanion",
        fallback = "This colonist is not an active companion.",
    },
    not_owner = {
        key = "UI_PNC_RadioRelay_ReasonNotOwner",
        fallback = "You do not command this colonist.",
    },
    relay_not_allowed = {
        key = "UI_PNC_RadioRelay_ReasonUnsupported",
        fallback = "This order cannot be relayed by radio.",
    },
    player_radio_inactive = {
        key = "UI_PNC_RadioRelay_ReasonPlayerRadio",
        fallback = "Turn on your walkie-talkie: it must be powered, "
            .. "unmuted and turned up.",
    },
    npc_radio_missing = {
        key = "UI_PNC_RadioRelay_ReasonNpcRadio",
        fallback = "This colonist has no walkie-talkie equipped.",
    },
}

Gate.REASONS = REASONS

-- Returns allowed, reason where reason is Gate.DIRECT or Gate.RELAY when
-- allowed, and a rejection key from Gate.REASONS otherwise.
function Gate.Evaluate(facts)
    facts = type(facts) == "table" and facts or {}
    if facts.dead == true then return false, "dead" end
    if facts.companion ~= true then return false, "not_companion" end
    if facts.owned ~= true then return false, "not_owner" end
    if facts.reachableDirectly == true then return true, Gate.DIRECT end
    if facts.relayAllowed ~= true then return false, "relay_not_allowed" end
    if facts.playerRadio ~= true then return false, "player_radio_inactive" end
    if facts.npcRadio ~= true then return false, "npc_radio_missing" end
    return true, Gate.RELAY
end

function Gate.Reason(reason)
    return REASONS[tostring(reason or "")]
end

function Gate.ReasonKey(reason)
    local entry = Gate.Reason(reason)
    return entry and entry.key or nil
end

function Gate.ReasonFallback(reason)
    local entry = Gate.Reason(reason)
    return entry and entry.fallback or nil
end

return Gate
