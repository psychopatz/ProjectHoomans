local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

-- ---------------------------------------------------------------------------
-- Runtime surface for the server-only leader-loss module.
-- ---------------------------------------------------------------------------

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.SocialFlavor = require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

local Flavor = PsychopatzCore.SocialFlavor
local Resolver = require "PNC/Core/Social/PNC_FlavorTextResolver"
local Const = PNC.FlavorTextConst

local now = 9000

PNC = PNC or {}
PNC.Const = { ZOMBIE_TARGET_RADIUS = 12 }
PNC.Core = {
    Now = function() return now end,
}
PNC.Perception = { CanSeeWorldObject = function() return true end }

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
local function setPlayers(list)
    local i
    for i = #players, 1, -1 do players[i] = nil end
    for i = 1, #(list or {}) do players[i] = list[i] end
end
PNC.Core.ForEachPlayer = function(callback)
    local i
    for i = 1, #players do callback(players[i]) end
end

local records = {}
PNC.Registry = {
    Get = function(id) return records[tostring(id)] end,
}

PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}
PNC.SocialEventHooks.ResolvePlayerKey = function(player)
    return player and player.key or nil
end

-- Visibility gate: mirrors the real signature so the emitter's reuse path is
-- exercised rather than the raw-distance fallback.
local hidden = {}
PNC.SocialMeeting = {
    CanPlayerMeetNPC = function(player, record)
        return hidden[record] ~= true, "visible"
    end,
}

-- Load the authored definitions and the module under test.
local DIR = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/"
dofile(DIR .. "PNC_SocialFlavorDefinitions_LeaderDeath_Close.lua")
dofile(DIR .. "PNC_SocialFlavorDefinitions_LeaderDeath_Wider.lua")
dofile(DIR .. "PNC_SocialFlavorDefinitions_LeaderDeath.lua")

local Hooks = dofile("Contents/mods/ProjectHoomans/42.20/media/lua/server/"
    .. "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_LeaderLoss.lua")

local function reset()
    clearSent()
    setPlayers({})
    records = {}
    hidden = {}
    now = 9000
    PNC.SocialEventHooksInternal.LeaderLossDebugReset()
end

local function player(key, x, y)
    return {
        key = key,
        getX = function() return x or 0 end,
        getY = function() return y or 0 end,
        getZ = function() return 0 end,
        getUsername = function() return key end,
    }
end

local function npc(id, x, y, relationship)
    local record = {
        id = id,
        alive = true,
        x = x or 0,
        y = y or 0,
        z = 0,
        social = { relationships = relationship or {} },
    }
    records[id] = record
    return record
end

-- A faction double shaped like the real one.
local function faction(id, memberIDs, name, leaderNPCID)
    return {
        id = id,
        name = name or "the group",
        memberIDs = memberIDs or {},
        leaderNPCID = leaderNPCID,
    }
end

-- ---------------------------------------------------------------------------
-- 1. Devoted follower, an NPC is promoted to lead the mobile group.
-- ---------------------------------------------------------------------------

reset()
local leaderKey = "player-owner"
records[leaderKey] = { id = leaderKey, displayName = "Mara" }
local mate = npc("npc-mate", 1, 1, {
    [leaderKey] = { state = "lover", category = "lover", approval = 60 },
})
local other = npc("npc-other", 2, 2, {
    [leaderKey] = { state = "neutral", category = "neutral", approval = 2 },
})
setPlayers({ player("listener", 1, 1) })
local f1 = faction("F1", {
    ["npc-mate"] = true, ["npc-other"] = true,
}, "Mara's people", "npc-mate")

local ok, reason = Hooks.OnLeaderLost(
    f1, leaderKey, Const.Succession.PROMOTED, "npc-mate")
T.truthy(ok, "the leader loss emits for the survivors")
T.equal(reason, "emitted", "the emit reports delivery")
T.truthy(#sent >= 1 and #sent <= 3, "a bounded number of mourners speaks")
T.equal(sent[1].npcID, "npc-mate",
    "the most affected NPC speaks first")
T.equal(sent[1].context.leaderGrief, Const.Grief.DEVOTED,
    "a lover's death is classed as devoted grief")
T.equal(sent[1].context.leaderSuccession, Const.Succession.PROMOTED,
    "the promoted succession is carried into the context")
T.equal(sent[1].context.leaderName, "Mara",
    "the dead leader's name is resolved for the line")
T.equal(sent[1].context.successorName, "npc-mate",
    "the successor's name is resolved for the line")
T.equal(sent[1].packet.family, Const.LEADER_DEATH_FAMILY,
    "the line uses the leader-loss family")
T.equal(sent[1].packet.flavorID, Const.FLAVOR_LEADER_DEATH,
    "the line uses the leader-death flavor id")

-- The several mourners share one flavor family, so the family cooldown must
-- be open or the client queue would admit only the first voice.
T.equal(sent[1].packet.cooldowns.familyMs, 0,
    "the leader-loss family cooldown is open so every mourner can be admitted")
T.equal(sent[1].packet.cooldowns.ambientMs, 0,
    "the ambient cadence is open so sibling mourners are not discarded")
T.truthy((sent[1].packet.cooldowns.speakerMs or 0) > 0,
    "a per-speaker cooldown still stops one NPC repeating")

local text = Flavor.Resolve(
    Const.FLAVOR_LEADER_DEATH, "npc", "s1", sent[1].context)
T.truthy(text and text ~= "", "the devoted lane resolves to authored text")
T.falsy(string.find(text, "{leaderName}", 1, true),
    "the leader name token is substituted")
T.falsy(string.find(text, "{successorName}", 1, true),
    "the successor name token is substituted")

-- ---------------------------------------------------------------------------
-- 2. Bounded speakers: many survivors, only a few voices.
-- ---------------------------------------------------------------------------

reset()
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
local ids = {}
local i
for i = 1, 10 do
    local id = "npc-" .. tostring(i)
    ids[id] = true
    npc(id, i, 0, {
        ["player-owner"] = { state = "neutral", category = "neutral", approval = 1 },
    })
end
setPlayers({ player("listener", 0, 0) })
Hooks.OnLeaderLost(
    faction("F2", ids), "player-owner", Const.Succession.PROMOTED, "npc-1")
T.truthy(#sent <= 3,
    "at most three mourners speak, got " .. tostring(#sent))
T.truthy(#sent >= 1, "at least one mourner speaks")

-- ---------------------------------------------------------------------------
-- 3. Debounce: the same faction cannot replay the death scene.
-- ---------------------------------------------------------------------------

local before = #sent
local okRepeat = Hooks.OnLeaderLost(
    faction("F2", ids), "player-owner", Const.Succession.PROMOTED, "npc-1")
T.falsy(okRepeat, "a second leader loss for the same faction is suppressed")
T.equal(#sent, before, "the debounce prevented duplicate lines")

-- ---------------------------------------------------------------------------
-- 4. A rival does not mourn; a colonist sounds functional.
-- ---------------------------------------------------------------------------

reset()
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
local rival = npc("npc-rival", 1, 1, {
    ["player-owner"] = { state = "enemy", category = "enemy", approval = -50 },
})
setPlayers({ player("listener", 1, 1) })
Hooks.OnLeaderLost(
    faction("F3", { ["npc-rival"] = true }),
    "player-owner", Const.Succession.PLAYER, nil)
T.equal(#sent, 1, "the rival still speaks")
T.equal(sent[1].context.leaderGrief, Const.Grief.DISSENT,
    "an enemy is classed as dissent, not mourning")
local rivalText = Flavor.Resolve(
    Const.FLAVOR_LEADER_DEATH, "npc", "s2", sent[1].context)
T.truthy(rivalText ~= nil, "the dissent lane resolves to text")

reset()
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
npc("npc-colonist", 1, 1, {
    ["player-owner"] = { state = "neutral", category = "neutral", approval = 1 },
})
setPlayers({ player("listener", 1, 1) })
Hooks.OnLeaderLost(
    faction("F4", { ["npc-colonist"] = true }),
    "player-owner", Const.Succession.PLAYER, nil)
T.equal(sent[1].context.leaderGrief, Const.Grief.COLONIST,
    "a plain faction member is classed as colonist grief")
T.equal(sent[1].context.leaderSuccession, Const.Succession.PLAYER,
    "the surviving-player succession is carried into the context")

-- ---------------------------------------------------------------------------
-- 5. Guards and degradation.
-- ---------------------------------------------------------------------------

reset()
T.falsy(Hooks.OnLeaderLost(nil, "p", "player"), "a nil faction is rejected")
T.falsy(Hooks.OnLeaderLost(faction("F5", {}), nil, "player"),
    "a nil leader is rejected")
T.equal(#sent, 0, "nothing is sent for invalid input")

reset()
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
npc("npc-alone", 1, 1, {})
T.falsy(Hooks.OnLeaderLost(
    faction("F6", { ["npc-alone"] = true }), "player-owner", "player"),
    "an out-of-range listener hears nothing")
T.equal(#sent, 0, "no packet without an audience")

reset()
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
for i = 1, 3 do npc("npc-x" .. tostring(i), i, 0, {}) end
setPlayers({ player("listener", 0, 0) })
local savedNetwork = PNC.Network.SendConversationRelationshipForNPC
PNC.Network.SendConversationRelationshipForNPC = nil
local degraded, degradedReason = Hooks.OnLeaderLost(
    faction("F7", { ["npc-x1"] = true, ["npc-x2"] = true, ["npc-x3"] = true }),
    "player-owner", "player")
T.falsy(degraded, "a missing transport degrades gracefully")
T.equal(degradedReason, "transport_unavailable",
    "the reason names the missing transport")
PNC.Network.SendConversationRelationshipForNPC = savedNetwork

-- ---------------------------------------------------------------------------
-- 6. Every grief x succession lane resolves to authored text.
-- ---------------------------------------------------------------------------

local griefs = Const.AllGrief
local successions = {
    Const.Succession.PROMOTED,
    Const.Succession.PLAYER,
    Const.Succession.NONE,
}
local gaps = {}
local g
local s
local checked = 0
for g = 1, #griefs do
    for s = 1, #successions do
        local context = Resolver.BuildLeaderDeathContext({
            relationshipState = "neutral",
            sameFaction = true,
            succession = successions[s],
            successorName = "Rook",
        })
        -- Force the grief axis under test.
        context.leaderGrief = griefs[g]
        context.leaderName = "Mara"
        context.successorName = "Rook"
        local result = Flavor.ResolveDetailed(
            Const.FLAVOR_LEADER_DEATH, "npc", "matrix", context)
        checked = checked + 1
        if not result or not result.text or result.text == "" then
            gaps[#gaps + 1] = griefs[g] .. "/" .. successions[s]
        else
            T.falsy(string.find(result.text, "{leader", 1, true),
                "no unresolved leader token in " .. griefs[g] .. "/"
                    .. successions[s])
        end
    end
end
T.equal(#gaps, 0, "every grief/succession lane resolves: "
    .. table.concat(gaps, ", "))
T.equal(checked, #griefs * #successions,
    "the whole grief/succession matrix was exercised")

-- ---------------------------------------------------------------------------
-- 7. Grief classification matrix.
-- ---------------------------------------------------------------------------

T.equal(Resolver.ClassifyGrief({ relationshipState = "lover" }),
    Const.Grief.DEVOTED, "a lover is devoted")
T.equal(Resolver.ClassifyGrief({ relationshipKind = "family" }),
    Const.Grief.DEVOTED, "family is devoted")
T.equal(Resolver.ClassifyGrief({ relationshipState = "enemy" }),
    Const.Grief.DISSENT, "an enemy is dissent")
T.equal(Resolver.ClassifyGrief({ relationshipTier = "warm" }),
    Const.Grief.CLOSE, "a warm relationship is close")
T.equal(Resolver.ClassifyGrief({ sameFaction = true }),
    Const.Grief.COLONIST, "a faction member with no bond is colonist")
T.equal(Resolver.ClassifyGrief({}),
    Const.Grief.DISTANT, "an unknown relationship is distant")

-- ---------------------------------------------------------------------------
-- 8. Load-order independence.
--
-- Both server modules must be loadable before the shared composition has
-- populated PNC.FlavorText / PNC.FlavorTextConst.  Reading those at module
-- load time was a real bug: it broke any consumer that required the social
-- hooks barrel earlier than the flavor resolver.
-- ---------------------------------------------------------------------------

local savedResolver = PNC.FlavorText
local savedConstants = PNC.FlavorTextConst
PNC.FlavorText = nil
PNC.FlavorTextConst = nil

local loadedEarly = pcall(dofile,
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Social/"
        .. "SocialEventHooks/PNC_SocialEventHooks_LeaderLoss.lua")
T.truthy(loadedEarly, "the leader-loss module loads without the flavor layer")

local loadedDownedEarly = pcall(dofile,
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Social/"
        .. "SocialEventHooks/PNC_SocialEventHooks_DownedDistress.lua")
T.truthy(loadedDownedEarly, "the downed module loads without the flavor layer")

-- With the flavor layer absent, the hooks must degrade, not error.
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
npc("npc-early", 1, 1, {})
setPlayers({ player("listener", 1, 1) })
ok, reason = Hooks.OnLeaderLost(
    faction("F8", { ["npc-early"] = true }), "player-owner", "player")
T.falsy(ok, "the leader-loss hook degrades without the flavor layer")
T.equal(reason, "resolver_unavailable",
    "the degraded reason names the missing resolver")

local earlyDowned = Hooks.OnIncapacitated(
    (function()
        local r = npc("npc-early-downed", 1, 1, {})
        r.health = { state = "incapacitated", current = 3, max = 30 }
        return r
    end)(), "damage")
T.falsy(earlyDowned, "the downed hook degrades without the flavor layer")

-- Restore so nothing else in the process sees a mutilated PNC.
PNC.FlavorText = savedResolver
PNC.FlavorTextConst = savedConstants
PNC.SocialEventHooksInternal.LeaderLossDebugReset()
PNC.SocialEventHooksInternal.IncapacitatedFlavorDebugReset()

-- And the hooks work again once the layer is present.
records["player-owner"] = { id = "player-owner", displayName = "Mara" }
npc("npc-restored", 1, 1, {})
setPlayers({ player("listener", 1, 1) })
local restored, restoredReason = Hooks.OnLeaderLost(
    faction("F9", { ["npc-restored"] = true }), "player-owner", "player")
T.truthy(restored, "the leader-loss hook recovers when the layer returns")
T.equal(restoredReason, "emitted", "the recovered hook emits normally")

return true