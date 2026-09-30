local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

-- ---------------------------------------------------------------------------
-- Minimal PZ/server surface.  The module under test is server-only, so the
-- harness has to stand in for the runtime role gate, logging, the player
-- enumerator, the network transport, and the record registry.
-- ---------------------------------------------------------------------------

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.SocialFlavor = require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

local Flavor = PsychopatzCore.SocialFlavor
local Resolver = require "PNC/Core/Social/PNC_FlavorTextResolver"
local Const = PNC.FlavorTextConst

local now = 5000

PNC = PNC or {}
PNC.Const = { ZOMBIE_TARGET_RADIUS = 12 }
PNC.Core = {
    Now = function() return now end,
    DistanceSq = function(x1, y1, x2, y2)
        local dx, dy = x2 - x1, y2 - y1
        return dx * dx + dy * dy
    end,
}
PNC.Perception = {
    ResolveRecentAttacker = function(record)
        return record.runtime and record.runtime.recentThreat or nil
    end,
    CanSeeWorldObject = function() return true end,
}

local sent = {}
local function clearSent()
    local i
    for i = #sent, 1, -1 do sent[i] = nil end
end
PNC.Network = {
    SendConversationRelationshipForNPC = function(player, npcID, reason, ctx)
        sent[#sent + 1] = {
            player = player,
            npcID = npcID,
            reason = reason,
            context = ctx.ambientFlavor and ctx.ambientFlavor.context or {},
            packet = ctx.ambientFlavor,
        }
        return true
    end,
}

local players = {}
PNC.Core.ForEachPlayer = function(callback)
    local i
    for i = 1, #players do callback(players[i]) end
end
local function setPlayers(list)
    local i
    for i = #players, 1, -1 do players[i] = nil end
    for i = 1, #(list or {}) do players[i] = list[i] end
end

local registered = {}
PNC.Registry = {
    Get = function(id) return registered[tostring(id)] end,
}

PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}
PNC.SocialEventHooks.ResolvePlayerKey = function(player)
    return player and player.key or nil
end

-- Faction service used by the resolver inputs.
local wars = {}
local allies = {}
local factionOf = {}
local ownerOf = {}
PNC.Factions = {
    GetFactionID = function(record)
        if not record then return nil end
        return factionOf[record]
    end,
    AreAtWar = function(a, b) return wars[a .. "|" .. b] == true end,
    AreAllied = function(a, b) return allies[a .. "|" .. b] == true end,
}

-- Ownership service: the real mod exposes this through the command registry.
PNC.Commands = {
    IsOwnedByPlayer = function(record, player)
        return record ~= nil and ownerOf[record] == player
    end,
}

-- NPCWounds surface: drives the "what wound do they have" need selection.
local woundState = {}
PNC.NPCWounds = {
    BuildStatusSummary = function(record)
        local state = woundState[record] or {}
        return {
            bleeding = state.bleeding == true,
            bleedingRate = state.bleedingRate,
            openWoundCount = state.openWounds or 0,
        }
    end,
    GetTreatableWounds = function(record)
        local state = woundState[record] or {}
        local out = {}
        local i
        for i = 1, (state.treatable or 0) do
            out[i] = { partId = "part" .. tostring(i), wound = {} }
        end
        return out
    end,
    HasActiveInfection = function(record)
        local state = woundState[record] or {}
        return state.infected == true
    end,
}

-- Load the authored definitions and the module under test.
-- Load the split definitions through their real load-order barrel so the
-- require chain is exercised exactly as the game would resolve it.
local FUNCTION_DIR = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/"
local function loadDefinitions()
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua")
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Call.lua")
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Update.lua")
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Repeat.lua")
end
loadDefinitions()
local Hooks = dofile("Contents/mods/ProjectHoomans/42.20/media/lua/server/"
    .. "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DownedDistress.lua")

local function reset()
    clearSent()
    setPlayers({})
    now = 5000
    PNC.SocialEventHooksInternal.IncapacitatedFlavorDebugReset()
end

local function player(key, faction, x, y)
    local value = {
        key = key,
        getX = function() return x or 0 end,
        getY = function() return y or 0 end,
        getZ = function() return 0 end,
        getUsername = function() return key end,
    }
    factionOf[value] = faction
    return value
end

local function npc(id, faction, x, y)
    local record = {
        id = id,
        alive = true,
        x = x or 0,
        y = y or 0,
        z = 0,
        health = { state = "incapacitated", current = 3, max = 30 },
        runtime = {},
    }
    record.social = { relationships = {} }
    factionOf[record] = faction
    return record
end

local function deliveredTexts()
    local out = {}
    local i
    for i = 1, #sent do
        out[#out + 1] = sent[i]
    end
    return out
end

-- ---------------------------------------------------------------------------
-- 1. Own follower, bleeding, killed by a zombie -> ally asks for a bandage.
-- ---------------------------------------------------------------------------

reset()
local follower = npc("npc-1", "F1", 0, 0)
local owner = player("owner", "F2", 1, 1)
setPlayers({ owner })
ownerOf[follower] = owner
woundState[follower] = { bleeding = true, bleedingRate = 3, treatable = 2 }
follower.runtime.recentThreat = { kind = "zombie", id = "z1", expiresAt = now + 5000 }

local ok, status = Hooks.OnIncapacitated(follower, "damage")
T.truthy(ok, "the follower distress line is emitted")
T.equal(status, "emitted", "the emit reports a delivered audience")
T.equal(#sent, 1, "exactly one listener received the line")
T.equal(sent[1].context.downedAudience, Const.Audience.ALLY,
    "an owned follower is addressed as an ally")
T.equal(sent[1].context.downedNeed, Const.Need.BLEEDOUT,
    "active bleeding outranks the bandage request")
T.equal(sent[1].context.downedThreat, Const.Threat.ZOMBIE,
    "a zombie attacker is recorded")
T.equal(sent[1].packet.family, Const.FAMILY,
    "the line uses the shared distress family")
T.equal(sent[1].reason, Const.FLAVOR_CALL,
    "the initial line uses the call flavor id")

local allyText = Flavor.Resolve(
    Const.FLAVOR_CALL, "npc", sent[1].packet.eventID, sent[1].context
)
T.truthy(allyText and allyText ~= "",
    "the emitted ally context resolves to authored text")
-- Name tokens ({playerFirstName}, {attackerName}) are substituted by the
-- client presentation layer from identity data; only resolver-owned keys
-- must never survive into the text.
T.falsy(string.find(allyText, "{downed", 1, true),
    "the resolved ally line has no unresolved resolver key")

-- ---------------------------------------------------------------------------
-- 2. Debounce: a second transition inside the window must not re-emit.
-- ---------------------------------------------------------------------------

T.falsy(Hooks.OnIncapacitated(follower, "damage"),
    "an immediate second incapacitation call is debounced")
T.equal(#sent, 1, "the debounce prevented a duplicate line")

-- ---------------------------------------------------------------------------
-- 3. Hostile NPC attacker -> the downed NPC pleads for mercy.
-- ---------------------------------------------------------------------------

reset()
local banditNPC = npc("npc-2", "ENEMY", 0, 0)
local victimPlayer = player("victim", "PLAYERS", 1, 1)
setPlayers({ victimPlayer })
wars["ENEMY|PLAYERS"] = true
woundState[banditNPC] = { treatable = 1 }
banditNPC.social.relationships["victim"] = {
    state = "enemy", category = "enemy", approval = -40,
}
banditNPC.runtime.recentThreat = {
    kind = "npc", id = "npc-attacker", expiresAt = now + 5000,
}
registered["npc-attacker"] = { id = "npc-attacker", displayName = "Rook" }

Hooks.OnIncapacitated(banditNPC, "damage")
T.equal(#sent, 1, "the hostile NPC emits a plea to the nearby player")
T.equal(sent[1].context.downedAudience, Const.Audience.HOSTILE,
    "an at-war faction is hostile even without a relationship record")
T.equal(sent[1].context.downedNeed, Const.Need.MERCY,
    "a hostile downed by a survivor pleads for mercy")
T.equal(sent[1].context.downedThreat, Const.Threat.NPC,
    "an NPC attacker is attributed as an NPC")

local mercyText = Flavor.Resolve(
    Const.FLAVOR_CALL, "npc", sent[1].packet.eventID, sent[1].context
)
T.truthy(mercyText ~= nil, "the mercy context resolves to text")
T.falsy(string.find(mercyText, "{downed", 1, true),
    "the mercy line has no unresolved resolver key")

-- The named attacker must be substituted when the line references it.
local named = Flavor.ResolveDetailed(
    Const.FLAVOR_CALL, "npc", "attacker-seed", {
        downedAudience = Const.Audience.HOSTILE,
        downedNeed = Const.Need.MERCY,
        downedThreat = Const.Threat.NPC,
        attackerName = "Rook",
    }
)
T.truthy(named and named.text ~= "", "the named-attacker lane resolves")
T.falsy(string.find(named.text, "{attackerName}", 1, true),
    "the attacker name token is substituted, not left raw")

-- ---------------------------------------------------------------------------
-- 4. Neutral/stranger: a different, peaceful faction gets the faint request.
-- ---------------------------------------------------------------------------

reset()
local stranger = npc("npc-3", "FARM", 0, 0)
local other = player("other", "TRADERS", 1, 1)
setPlayers({ other })
woundState[stranger] = {}
stranger.runtime.recentThreat = { kind = "zombie", id = "z2", expiresAt = now + 5000 }

Hooks.OnIncapacitated(stranger, "damage")
T.equal(#sent, 1, "the stranger emits a request")
T.equal(sent[1].context.downedAudience, Const.Audience.STRANGER,
    "a different peaceful faction is a stranger, not an enemy")
T.falsy(sent[1].context.downedNeed == Const.Need.MERCY,
    "a stranger does not plead for mercy to a non-attacker")

local strangerText = Flavor.Resolve(
    Const.FLAVOR_CALL, "npc", sent[1].packet.eventID, sent[1].context
)
T.truthy(strangerText ~= nil, "the stranger lane resolves to text")
T.falsy(string.find(strangerText, "{downed", 1, true),
    "the stranger line has no unresolved resolver key")

-- ---------------------------------------------------------------------------
-- 5. Hostile downed by a zombie -> dying noise, never a plea to a survivor.
-- ---------------------------------------------------------------------------

reset()
local doomed = npc("npc-4", "RAIDERS", 0, 0)
local bystander = player("bystander", "RAIDERS", 1, 1)
setPlayers({ bystander })
doomed.social.relationships["bystander"] = {
    state = "neutral", category = "neutral", approval = 0,
}
doomed.runtime.recentThreat = { kind = "zombie", id = "z3", expiresAt = now + 5000 }

Hooks.OnIncapacitated(doomed, "damage")
T.equal(#sent, 1, "the same-faction bystander hears the line")
T.equal(sent[1].context.downedAudience, Const.Audience.ALLY,
    "a same-faction listener is an ally")
T.equal(sent[1].context.downedThreat, Const.Threat.ZOMBIE,
    "the zombie attribution survives to the client context")

-- ---------------------------------------------------------------------------
-- 6. No audience: nobody in range means no packet and no crash.
-- ---------------------------------------------------------------------------

reset()
local alone = npc("npc-5", "F1", 0, 0)
setPlayers({ player("far", "F1", 200, 200) })
alone.runtime.recentThreat = { kind = "zombie", id = "z4", expiresAt = now + 5000 }
local emitted, noAudience = Hooks.OnIncapacitated(alone, "damage")
T.falsy(emitted, "an out-of-range listener is not addressed")
T.equal(noAudience, "no_audience", "the reason reports the empty audience")
T.equal(#sent, 0, "no packet is sent without an audience")

-- ---------------------------------------------------------------------------
-- 7. Status update while down uses the update flavor and merges in place.
-- ---------------------------------------------------------------------------

reset()
local bleeding = npc("npc-6", "F1", 0, 0)
setPlayers({ player("ally-player", "F1", 1, 1) })
woundState[bleeding] = { treatable = 1 }
bleeding.runtime.recentThreat = { kind = "zombie", id = "z5", expiresAt = now + 5000 }
Hooks.OnIncapacitated(bleeding, "damage")
T.equal(#sent, 1, "the initial call is emitted")
local callMergeKey = sent[1].packet.mergeKey

now = now + 30000
woundState[bleeding] = { bleeding = true, bleedingRate = 4, treatable = 1 }
Hooks.OnIncapacitatedStatusChanged(bleeding, "wound_change")
T.equal(#sent, 2, "the status change emits an update line")
T.equal(sent[2].reason, Const.FLAVOR_UPDATE,
    "the follow-up uses the update flavor id")
T.equal(sent[2].packet.mergeKey, callMergeKey,
    "call and update share one merge key so the line updates in place")
T.equal(sent[2].context.downedNeed, Const.Need.BLEEDOUT,
    "the update reflects the worsened wound picture")

-- ---------------------------------------------------------------------------
-- 8. Guards: dead or genuinely invalid subjects never speak.
-- ---------------------------------------------------------------------------

reset()
setPlayers({ player("p", "F1", 0, 0) })
local corpse = npc("npc-7", "F1", 0, 0)
corpse.alive = false
local deadEmit, deadReason = Hooks.OnIncapacitated(corpse, "damage")
T.falsy(deadEmit, "a dead NPC does not emit distress")
T.equal(deadReason, "invalid_subject", "the reason names the invalid subject")
T.equal(#sent, 0, "nothing is sent for a dead NPC")

T.falsy(Hooks.OnIncapacitated(nil), "a nil subject is rejected safely")

local healthy = npc("npc-8", "F1", 0, 0)
healthy.health.state = "normal"
T.falsy(Hooks.OnIncapacitatedStatusChanged(healthy, "wound_change"),
    "a status update on a standing NPC is rejected")
T.equal(#sent, 0, "no packet for a non-downed NPC")

-- ---------------------------------------------------------------------------
-- 9. Degradation: no transport means a clean false, never an error.
-- ---------------------------------------------------------------------------

reset()
local savedNetwork = PNC.Network.SendConversationRelationshipForNPC
PNC.Network.SendConversationRelationshipForNPC = nil
local degraded = npc("npc-9", "F1", 0, 0)
setPlayers({ player("p2", "F1", 0, 0) })
local degradedEmit, degradedReason = Hooks.OnIncapacitated(degraded, "damage")
T.falsy(degradedEmit, "a missing transport degrades gracefully")
T.equal(degradedReason, "transport_unavailable",
    "the reason names the missing transport")
PNC.Network.SendConversationRelationshipForNPC = savedNetwork

-- A failing transport must not propagate out of the hook.
PNC.Network.SendConversationRelationshipForNPC = function()
    error("simulated transport failure")
end
reset()
PNC.SocialEventHooksInternal.IncapacitatedFlavorDebugReset()
local failing = npc("npc-10", "F1", 0, 0)
setPlayers({ player("p3", "F1", 0, 0) })
local survived = pcall(Hooks.OnIncapacitated, failing, "damage")
T.truthy(survived, "a transport error inside the listener is contained")
PNC.Network.SendConversationRelationshipForNPC = savedNetwork

-- ---------------------------------------------------------------------------
-- 10. Bounded work: listeners are only addressed while near the subject.
-- ---------------------------------------------------------------------------

reset()
PNC.SocialEventHooksInternal.IncapacitatedFlavorDebugReset()
local many = {}
local i
for i = 1, 12 do
    many[i] = player("p" .. tostring(i), "F1", i, 0)
end
players = many
local crowded = npc("npc-11", "F1", 0, 0)
crowded.runtime.recentThreat = { kind = "zombie", id = "z6", expiresAt = now + 5000 }
Hooks.OnIncapacitated(crowded, "damage")
T.truthy(#sent <= 12, "the listener fan-out stays bounded by the player list")
T.truthy(#sent >= 1, "at least the nearest listener hears the line")

-- ---------------------------------------------------------------------------
-- 11. Repeat cadence: a downed NPC keeps asking, but slowly.
-- ---------------------------------------------------------------------------

reset()
PNC.SocialEventHooksInternal.IncapacitatedFlavorDebugReset()
local persistent = npc("npc-repeat", "F1", 0, 0)
setPlayers({ player("ally-repeat", "F1", 1, 1) })
woundState[persistent] = { treatable = 1 }
persistent.runtime.recentThreat = {
    kind = "zombie", id = "z9", expiresAt = now + 600000,
}

Hooks.OnIncapacitated(persistent, "damage")
T.equal(#sent, 1, "the initial call is emitted")
T.equal(sent[1].reason, Const.FLAVOR_CALL, "the first line is the call")

-- Immediately after: still inside the repeat interval, so silence.
T.falsy(Hooks.TickIncapacitatedDistress(persistent),
    "no repeat before the interval elapses")
T.equal(#sent, 1, "the tick added nothing yet")

-- Halfway through the interval: still silent.
now = now + 20000
T.falsy(Hooks.TickIncapacitatedDistress(persistent),
    "no repeat halfway through the interval")
T.equal(#sent, 1, "half an interval is still silent")

-- Past the interval: asks again, with the repeat voice.
now = now + (Const.REPEAT_INTERVAL_MS or 45000) + 1000
T.truthy(Hooks.TickIncapacitatedDistress(persistent),
    "the repeat beat fires once the interval elapses")
T.equal(#sent, 2, "the repeat produced exactly one more line")
T.equal(sent[2].reason, Const.FLAVOR_REPEAT,
    "the repeat uses its own flavor id, not the call id")
-- Capture before the next reset clears the send log.
local repeatContext = sent[2].context

-- The repeat merges into the same visible line rather than stacking.
T.equal(sent[2].packet.mergeKey, sent[1].packet.mergeKey,
    "the repeat shares the episode merge key with the call")

-- Repeated ticks must not queue a line each frame.
now = now + 1000
T.falsy(Hooks.TickIncapacitatedDistress(persistent),
    "a tick right after a repeat stays silent")
T.equal(#sent, 2, "the repeat cannot fire twice in one interval")

-- A downed NPC with no prior call (loaded save) adopts on first tick rather
-- than waiting a full interval in silence.
reset()
PNC.SocialEventHooksInternal.IncapacitatedFlavorDebugReset()
local adopted = npc("npc-adopt", "F1", 0, 0)
setPlayers({ player("ally-adopt", "F1", 1, 1) })
woundState[adopted] = {}
adopted.runtime.recentThreat = {
    kind = "zombie", id = "z10", expiresAt = now + 600000,
}
T.truthy(Hooks.TickIncapacitatedDistress(adopted),
    "a downed NPC with no recorded call speaks on its first tick")
T.equal(sent[1].reason, Const.FLAVOR_CALL,
    "the adopted line is the call, not the repeat")

-- A standing NPC must never tick distress.
local standing = npc("npc-standing", "F1", 0, 0)
standing.health.state = "normal"
T.falsy(Hooks.TickIncapacitatedDistress(standing),
    "a standing NPC never emits distress on tick")
T.falsy(Hooks.TickIncapacitatedDistress(nil),
    "a nil record is safe on tick")

-- Repeat lines must be authored for the same lanes as the call.
local repeatDef = PsychopatzCore.SocialFlavor.Get("social.incapacitated_repeat")
T.truthy(repeatDef, "the repeat flavor is registered")
local repeatText = PsychopatzCore.SocialFlavor.Resolve(
    "social.incapacitated_repeat", "npc", "seed-r", repeatContext)
T.truthy(repeatText and repeatText ~= "",
    "the repeat context resolves to authored text")

return true