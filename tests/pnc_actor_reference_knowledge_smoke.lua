-- Smoke test for PNC.ActorReference knowledge-gated name & pronoun resolution
-- and anti-bleed integration with AudienceContext and BehaviorSuicide.

local T = require "tests/support/test"

T.addPackagePaths()

PNC = PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Semantics = PNC.Semantics or {}
PNC.Core = {
    Now = function() return 10000 end,
    IsAuthority = function() return true end,
}

T.load(T.path("ProjectHoomans", "shared", "PNC/Semantics/PNC_ActorReference.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticAudienceContext.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Suicide.lua"))

local Ref = PNC.ActorReference
local Audience = PNC.Semantics.AudienceContext
local Suicide = PNC.BehaviorSuicide

local colonist = {
    id = "npc_colonist",
    name = "Marcus Reed",
    isFemale = false,
    colonyOwned = true,
    recruited = true,
    factionID = "player_colony",
    groupId = "grp_colony",
}

local fellowColonist = {
    id = "npc_fellow",
    name = "Elena Vance",
    isFemale = true,
    colonyOwned = true,
    recruited = true,
    factionID = "player_colony",
    groupId = "grp_colony",
}

local stranger = {
    id = "npc_stranger",
    name = "Catalina Morales",
    isFemale = true,
    colonyOwned = false,
    recruited = false,
    factionID = "roaming_strangers",
}

local player = {
    id = "player",
    isPlayer = true,
    name = "Jordan",
    key = "player:jordan",
    characterUUID = "uuid_jordan",
}

-- 1. Colonist <-> Stranger: NO name bleed in either direction, accurate pronouns
T.equal(Ref.KnowsName(colonist, stranger), false, "colonist must not know stranger's name")
T.equal(Ref.KnowsName(stranger, colonist), false, "stranger must not know colonist's name")
T.equal(Ref.NameFor(colonist, stranger, { role = "reference" }), "stranger",
    "colonist referring to unknown stranger must use 'stranger'")
T.equal(Ref.NameFor(stranger, colonist, { role = "vocative", unknownAddress = "friend" }), "friend",
    "stranger addressing unknown colonist must use fallback")

local strangerTokens = Ref.BuildTokens(colonist, stranger, "victim", { role = "reference" })
T.equal(strangerTokens["victim.name"], "stranger", "victim.name must not leak 'Catalina'")
T.equal(strangerTokens["victim.known"], "false", "victim.known must be false")
T.equal(strangerTokens["victim.subj"], "she", "pronouns must remain visually accurate")
T.equal(strangerTokens["victim.poss"], "her", "possessive pronoun must remain visually accurate")

-- 2. Colonist <-> Fellow Colonist: knows proper first name
T.equal(Ref.KnowsName(colonist, fellowColonist), true, "colonists in same colony must know each other")
T.equal(Ref.NameFor(colonist, fellowColonist, { role = "reference" }), "Elena",
    "colonist must use fellow colonist's first name")

-- 3. Relationship familiarity unlocks name knowledge
PNC.Relationships = {
    GetPair = function(a, b)
        if (a == "npc:npc_colonist" and b == "npc:npc_stranger")
            or (a == "npc:npc_stranger" and b == "npc:npc_colonist")
        then
            return { familiarity = 8 }
        end
        return nil
    end,
}
T.equal(Ref.KnowsName(colonist, stranger), true, "familiarity >= 5 must unlock name knowledge")
T.equal(Ref.NameFor(colonist, stranger, { role = "reference" }), "Catalina",
    "familiar NPC must use known first name")
PNC.Relationships = nil

-- 4. AudienceContext prevents NPC -> Player & NPC -> Stranger name bleed
local strangerToPlayer = Audience.Resolve(stranger, { player }, { includeNearbyPlayer = false })
T.equal(strangerToPlayer.label, "friend", "unfamiliar stranger must not know player's name")

local colonistToPlayer = Audience.Resolve(colonist, { player }, { includeNearbyPlayer = false })
T.equal(colonistToPlayer.label, "Jordan", "recruited colonist must know player's name")

local colonistToStranger = Audience.Resolve(colonist, { stranger }, { includeNearbyPlayer = false })
T.equal(colonistToStranger.label, "stranger", "colonist must address unfamiliar stranger as 'stranger'")

-- 5. BehaviorSuicide end-to-end: Colonist witness does NOT leak Stranger's name
local delivered = {}
stranger.alive = true
stranger.presenceState = "live"
stranger.x, stranger.y, stranger.z = 10, 10, 0
stranger.equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 3 } }
stranger.health = { state = "normal", body = { infection = { active = true, progress = 0.95 } } }

colonist.alive = true
colonist.presenceState = "live"
colonist.x, colonist.y, colonist.z = 12, 10, 0

PNC.Registry = {
    ForEach = function(fn) fn(stranger); fn(colonist) end,
    Get = function(id)
        if id == stranger.id then return stranger end
        if id == colonist.id then return colonist end
        return nil
    end,
}
PNC.Semantics.SpeechTransport = {
    ResolveLine = function(_, req)
        local t = req.tokens or {}
        if req.role == "suicide_resolve" then
            return "Goodbye, " .. tostring(t["addressee.name"]), { poolID = req.poolID }
        elseif req.role == "suicide_intervene" then
            return "Stop, " .. tostring(t["victim.name"]) .. "!", { poolID = req.poolID }
        elseif req.role == "suicide_mourn" then
            return "Rest in peace, " .. tostring(t["victim.name"]) .. "... " .. tostring(t["victim.subj"]) .. " went out human.", { poolID = req.poolID }
        end
        return "ok", { poolID = req.poolID }
    end,
    Deliver = function(speaker, _, payload)
        delivered[#delivered + 1] = { speaker = speaker.id, role = payload.context.beatRole, text = payload.text }
        return 1
    end,
}
PNC.Health = {
    Kill = function(rec) rec.alive = false; return true end,
}

T.truthy(Suicide.TryTrigger(stranger, nil, "knox_critical", { now = 10000, force = true }),
    "stranger suicide must trigger")
T.equal(delivered[1].text, "Goodbye, friend", "stranger must not know colonist's name 'Marcus'")

Suicide.Tick(stranger, nil, 12300) -- intervene
T.equal(delivered[2].text, "Stop, stranger!", "colonist must not know stranger's name 'Catalina'")

Suicide.Tick(stranger, nil, 14600) -- insist
Suicide.Tick(stranger, nil, 16700) -- comply
Suicide.Tick(stranger, nil, 18600) -- execute
Suicide.Tick(stranger, nil, 19500) -- shot_kill
Suicide.Tick(colonist, nil, 21400) -- witness mourn
local mournLine = delivered[#delivered].text
T.equal(mournLine, "Rest in peace, stranger... she went out human.",
    "colonist mourning stranger must use 'stranger' + proper pronoun 'she', got: " .. tostring(mournLine))

-- 6. Autonomous NPC-to-NPC cross-faction introduction via unified GroupBanter + ConversationDirector
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local diag = ConvoDSL.Reload("EN")
T.equal(#(diag.errors or {}), 0,
    "EN ConvoBlocks (including social_identity_exchange.convo) must load cleanly: "
        .. table.concat(diag.errors or {}, "; "))
local introPool = Catalog.Get("semantic.social.identity.ask_name_proactive")
T.truthy(introPool and type(introPool.variants) == "table" and #introPool.variants >= 10,
    "semantic.social.identity.ask_name_proactive must contain stranger meeting variants")

PNC.Semantics.DialogueBeats = PNC.Semantics.DialogueBeats or {}
local Beats = PNC.Semantics.DialogueBeats
local emittedIntro = {}
Beats.RegisterHook = function() end
Beats.Emit = function(eventName, payload)
    emittedIntro[#emittedIntro + 1] = { eventName = eventName, payload = payload }
    return true, "thread_intro_1"
end
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/Beats/PNC_SemanticBeats_GroupBanter.lua"))

local pairFamiliarity = {}
local function famKey(a, b) return tostring(a) .. "->" .. tostring(b) end
PNC.Relationships = {
    GetFamiliarity = function(obsId, targetKey)
        return pairFamiliarity[famKey(obsId, targetKey)] or 0
    end,
    ApplyConversationEffect = function(obsId, targetKey, spec)
        local k = famKey(obsId, targetKey)
        pairFamiliarity[k] = (pairFamiliarity[k] or 0) + (tonumber(spec.familiarityDelta) or 0)
        return true
    end,
}

local npcA = { id = "npc_alpha", name = "Lucas Grant", factionID = "colony_a", x = 20, y = 20, z = 0 }
local npcB = { id = "npc_beta",  name = "Nora Hayes",  factionID = "faction_b", x = 23, y = 20, z = 0 }
T.equal(Ref.KnowsName(npcA, npcB), false, "different-faction NPCs must start as strangers")

-- Case A: REFUSE keeps them as strangers (familiarity < 5)
PNC.Semantics.ConversationDirector = {
    EvaluateCandidate = function() return true end,
    SelectSuggestionForNPC = function() return { speechAct = "REFUSE" } end,
    MarkSpoken = function() end,
    GetDensityProfile = function() return { cooldownScale = 1.0 } end,
}
Beats.ResetGroupBanterRuntime()
local okRefuse = Beats.CheckGroupBanter(50000, {
    getGroups = function()
        return {
            { teamKey = "colony_a", members = { npcA } },
            { teamKey = "faction_b", members = { npcB } },
        }
    end,
})
T.truthy(okRefuse and #emittedIntro == 1, "cross-faction introduction must emit")
T.equal(emittedIntro[1].payload.replyRole, "answer_meet_refuse", "REFUSE stance must use answer_meet_refuse")
T.equal(Ref.KnowsName(npcA, npcB), false, "REFUSE must keep both NPCs as strangers")

-- Case B: ACCEPT exchanges names and unlocks KnowsName in BOTH directions
PNC.Semantics.ConversationDirector.SelectSuggestionForNPC = function()
    return { speechAct = "ACCEPT" }
end
Beats.ResetGroupBanterRuntime()
local okAccept = Beats.CheckGroupBanter(300000, {
    getGroups = function()
        return {
            { teamKey = "colony_a", members = { npcA } },
            { teamKey = "faction_b", members = { npcB } },
        }
    end,
})
T.truthy(okAccept and #emittedIntro == 2, "second introduction after cooldown must emit")
T.equal(emittedIntro[2].payload.replyRole, "answer_meet_real_name", "ACCEPT stance must use answer_meet_real_name")
T.equal(Ref.KnowsName(npcA, npcB), true, "ACCEPT must unlock A -> B name knowledge")
T.equal(Ref.KnowsName(npcB, npcA), true, "ACCEPT must unlock B -> A name knowledge")
T.equal(Ref.NameFor(npcA, npcB, { role = "reference" }), "Nora", "A must now know B's first name")
T.equal(Ref.NameFor(npcB, npcA, { role = "reference" }), "Lucas", "B must now know A's first name")

T.finish("pnc_actor_reference_knowledge_smoke")
