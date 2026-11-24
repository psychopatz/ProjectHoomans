local T = require "tests/support/test"
T.addPackagePaths()

T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_EntityRef.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileConstants.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileTypes.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileMath.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipTypes.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipProposalPolicy.lua"))

local records = {}
local startedThreads = {}
local hearsayCalls = 0
local hearsayShouldPropagate = false

PNC.Core = {
    Now = function() return 0 end,
    ForEachPlayer = function(fn)
        fn({
            isDead = function() return false end,
            getX = function() return 10 end,
            getY = function() return 10 end,
        })
    end,
}

PNC.Registry = {
    GetRecord = function(id) return records[tostring(id)] end,
}

PNC.SpatialIndex = {
    QueryNPCs = function()
        local out = {}
        for _, rec in pairs(records) do out[#out + 1] = rec end
        table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
        return out
    end,
}

PNC.SemanticDialogueBeats = {
    StartThread = function(plan)
        startedThreads[#startedThreads + 1] = plan
        return plan.threadID
    end,
}

PNC.SocialWitness = {
    PropagateHearsay = function()
        hearsayCalls = hearsayCalls + 1
        return { ok = true, propagated = hearsayShouldPropagate }
    end,
}

PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}
PNC.Relationships.Internal.isAuthority = function() return true end
PNC.Relationships.Internal.resolveObserver = function(id) return records[tostring(id)] end
PNC.Relationships.Internal.getRelationship = function(rec, key)
    return rec and rec.social and rec.social.relationships and rec.social.relationships[key] or nil
end
PNC.Relationships.Internal.commit = function(rec, social)
    rec.social = social
    return true
end
PNC.Relationships.Internal.hasRecentEvent = function() return false end
PNC.Relationships.Internal.appendRecentEvent = function() end

T.load(T.path("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_Bond.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_NPCSocial.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Social/PNC_NPCSocialExchangeService.lua"))

local Service = PNC.NPCSocialExchange
local Policy = PNC.RelationshipProposalPolicy

local function makeNPC(id, name, isFemale, kinsey, factionID, tacticalClass)
    local prof = PNC.SocialProfileGenerator.Generate(200 + #id, "General", {
        kinsey = kinsey,
        socialStyle = "friendly",
        romanceStyle = "flirty",
        jealousyStyle = "normal",
    })
    local rec = {
        id = id,
        name = name,
        alive = true,
        isFemale = isFemale,
        tacticalClass = tacticalClass or "neutral",
        x = 11, y = 11, z = 0,
        identitySeed = 500,
        archetypeID = "General",
        affiliation = factionID and { factionID = factionID } or nil,
        social = {
            personality = prof,
            relationships = {},
        },
        runtime = {},
    }
    records[id] = rec
    return rec
end

-- Colonist + Neutral stranger nearby a player
local colonist = makeNPC("npc_a", "Carmela Jane", true, 3, "colony_1", "friendly")
local neutral = makeNPC("npc_b", "Marcus Cole", false, 0, nil, "neutral")

-- Stage 1: Visible name introduction via Service.Update
local ok1, stage1 = Service.Update(20000, 10)
T.truthy(ok1, "colonist and neutral stranger initiate an exchange")
T.equal(stage1, "intro", "first exchange between strangers is an introduction")
T.equal(#startedThreads, 1, "introduction emits an overhead dialogue beat")
T.equal(startedThreads[1].opening.poolID, "semantic.social.npc_exchange.intro",
    "opening beat uses compiled ConvoDSL intro pool")
T.equal(startedThreads[1].opening.role, "open",
    "opening beat selects open role")
T.equal(startedThreads[1].opening.tokens["speaker.name"], "Carmela Jane",
    "opening beat passes speaker A's name token")
T.equal(startedThreads[1].replies[1].poolID, "semantic.social.npc_exchange.intro",
    "reply beat uses compiled ConvoDSL intro pool")
T.equal(startedThreads[1].replies[1].role, "reply",
    "reply beat selects reply role")
T.equal(startedThreads[1].replies[1].tokens["speaker.name"], "Marcus Cole",
    "reply beat passes speaker B's name token")
T.equal(colonist.social.relationships["npc:npc_b"].knowsName, true,
    "colonist now knows neutral NPC's name")
T.equal(neutral.social.relationships["npc:npc_a"].knowsName, true,
    "neutral NPC now knows colonist's name")

-- Anti-spam: immediate retry blocked by global cooldown, then pair cooldown
local okGlobal, reasonGlobal = Service.TryExchange(colonist, neutral, { nowMs = 25000, worldAgeHours = 10.5 })
T.falsy(okGlobal, "global cooldown prevents back-to-back ambient spam")
T.equal(reasonGlobal, "global_cooldown", "reports global_cooldown")

local okPair, reasonPair = Service.TryExchange(colonist, neutral, { nowMs = 60000, worldAgeHours = 11.0 })
T.falsy(okPair, "pair cooldown prevents same pair spamming")
T.equal(reasonPair, "pair_cooldown", "reports pair_cooldown")

-- Stage 2a: Gossip exchange when hearsay propagates
hearsayShouldPropagate = true
local ok2, stage2, info2 = Service.TryExchange(colonist, neutral, { nowMs = 60000, worldAgeHours = 13.0 })
T.truthy(ok2, "pair can exchange again after pair cooldown")
T.equal(stage2, "gossip", "exchange reports gossip when hearsay propagates")
T.truthy(info2.hearsayPropagated, "hearsay propagation flag recorded")
T.truthy(hearsayCalls >= 1, "SocialWitness.PropagateHearsay was invoked")

-- Stage 2b: Friend promotion when thresholds are reached
hearsayShouldPropagate = false
colonist.social.relationships["npc:npc_b"].approval = 80
colonist.social.relationships["npc:npc_b"].respect = 80
colonist.social.relationships["npc:npc_b"].familiarity = 80
neutral.social.relationships["npc:npc_a"].approval = 80
neutral.social.relationships["npc:npc_a"].respect = 80
neutral.social.relationships["npc:npc_a"].familiarity = 80
local ok3, stage3 = Service.TryExchange(colonist, neutral, { nowMs = 100000, worldAgeHours = 16.0 })
T.truthy(ok3, "acquaintances can promote to friends")
T.equal(stage3, "friend", "friend promotion triggers friend milestone beat")
T.equal(colonist.social.relationships["npc:npc_b"].bond.class, "friend", "colonist->neutral bond is friend")
T.equal(neutral.social.relationships["npc:npc_a"].bond.class, "friend", "neutral->colonist bond is friend")

-- Stage 3: Organic Kinsey-compatible Lover promotion after minimum age (24h+)
colonist.social.relationships["npc:npc_b"].approval = 90
colonist.social.relationships["npc:npc_b"].respect = 90
colonist.social.relationships["npc:npc_b"].familiarity = 90
neutral.social.relationships["npc:npc_a"].approval = 90
neutral.social.relationships["npc:npc_a"].respect = 90
neutral.social.relationships["npc:npc_a"].familiarity = 90
local origRoll = Policy.Roll
Policy.Roll = function() return 0.01 end
local ok4, stage4 = Service.TryExchange(colonist, neutral, { nowMs = 150000, worldAgeHours = 45.0 })
Policy.Roll = origRoll
T.truthy(ok4, "mature compatible friends can organically promote to lovers")
T.equal(stage4, "lover", "lover promotion triggers romance milestone beat")
T.equal(colonist.social.relationships["npc:npc_b"].bond.class, "lover", "colonist->neutral bond is lover")
T.equal(neutral.social.relationships["npc:npc_a"].bond.class, "lover", "neutral->colonist bond is lover")

-- Ineligible participants: hostile / in-combat / in-conversation are skipped
local raider = makeNPC("npc_c", "Bad Guy", false, 0, nil, "hostile")
T.falsy(Service.IsEligibleParticipant(raider), "hostile NPC is ineligible for social exchange")
colonist.runtime.inCombat = true
T.falsy(Service.IsEligibleParticipant(colonist), "NPC in combat is ineligible for social exchange")
colonist.runtime.inCombat = false
colonist.runtime.conversationActive = true
T.falsy(Service.IsEligibleParticipant(colonist), "NPC in player conversation is ineligible")

T.finish("pnc_npc_social_exchange_smoke")
