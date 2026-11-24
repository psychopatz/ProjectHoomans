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
PNC.Registry = {
    GetRecord = function(id) return records[tostring(id)] end,
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

T.load(T.path("ProjectHoomans", "server", "PNC/Social/RelationshipService/PNC_RelationshipService_NPCSocial.lua"))

local Relationships = PNC.Relationships
local Policy = PNC.RelationshipProposalPolicy

local function makeNPC(id, isFemale, kinsey, overrides)
    local prof = PNC.SocialProfileGenerator.Generate(100 + #id, "General", {
        kinsey = kinsey,
        jealousyStyle = overrides and overrides.jealousyStyle or "normal",
        romanceStyle = overrides and overrides.romanceStyle or "flirty",
    })
    local rec = {
        id = id,
        name = "NPC " .. id,
        alive = true,
        isFemale = isFemale,
        identitySeed = 1000,
        archetypeID = "General",
        social = {
            personality = prof,
            relationships = {},
        },
    }
    records[id] = rec
    return rec
end

-- 1. MarkKnownName sets knowsName + firstMetAt and preserves through normalization.
local alice = makeNPC("alice", true, 3)
local bob = makeNPC("bob", false, 0)
local okMark, markReason, relAB = Relationships.MarkKnownName("alice", "npc:bob", 10)
T.truthy(okMark, "MarkKnownName succeeds")
T.equal(markReason, "name_marked", "first MarkKnownName reports name_marked")
T.equal(relAB.knowsName, true, "knowsName persisted on edge")
T.equal(relAB.firstMetAt, 10, "firstMetAt recorded on edge")
local okRepeat, repeatReason = Relationships.MarkKnownName("alice", "npc:bob", 12)
T.truthy(okRepeat, "repeat MarkKnownName succeeds")
T.equal(repeatReason, "already_known", "repeat MarkKnownName is idempotent")

-- 2. PruneNPCRelationships evicts stalest/lowest-familiarity neutral edges only.
local social = { relationships = {} }
social.relationships["player:acc:p1"] = { state = "neutral", familiarity = 0, lastInteractionAt = 1 }
social.relationships["npc:bestie"] = {
    state = "friend", familiarity = 5, lastInteractionAt = 1, bond = { class = "friend" },
}
social.relationships["npc:enemy1"] = { state = "enemy", familiarity = 0, lastInteractionAt = 1 }
for i = 1, 18 do
    social.relationships["npc:stranger_" .. i] = {
        state = "neutral",
        familiarity = i,
        lastInteractionAt = i,
    }
end
local removed = Relationships.PruneNPCRelationships(social, "npc:stranger_1", 16)
T.equal(removed, 4, "prunes excess npc edges down to cap")
T.truthy(social.relationships["player:acc:p1"], "player edge is never evicted")
T.truthy(social.relationships["npc:bestie"], "friend bond edge is never evicted")
T.truthy(social.relationships["npc:enemy1"], "enemy edge is never evicted")
T.truthy(social.relationships["npc:stranger_1"], "protected key is never evicted")
T.falsy(social.relationships["npc:stranger_2"], "lowest familiarity neutral edge is evicted")
T.truthy(social.relationships["npc:stranger_18"], "highest familiarity neutral edge is retained")

-- 3. EvaluateNPCRomancePromotion enforces age, Kinsey compatibility, exclusivity, and promotes both edges.
local function setFriendEdge(fromRec, toKey, firstMetAt)
    fromRec.social.relationships[toKey] = {
        state = "friend",
        approval = 90,
        respect = 90,
        familiarity = 90,
        knowsName = true,
        firstMetAt = firstMetAt,
        bond = { class = "friend" },
        memories = {},
        cooldowns = {},
    }
end

setFriendEdge(alice, "npc:bob", 10)
setFriendEdge(bob, "npc:alice", 10)

local okTooNew, reasonTooNew = Relationships.EvaluateNPCRomancePromotion("alice", "bob", 20)
T.falsy(okTooNew, "romance blocked before minimum relationship age")
T.equal(reasonTooNew, "relationship_too_new", "reports relationship_too_new")

-- Incompatible Kinsey (Kinsey 0 female + Kinsey 0 female).
local cara = makeNPC("cara", true, 0)
local dana = makeNPC("dana", true, 0)
setFriendEdge(cara, "npc:dana", 0)
setFriendEdge(dana, "npc:cara", 0)
local okIncompat, reasonIncompat = Relationships.EvaluateNPCRomancePromotion("cara", "dana", 50)
T.falsy(okIncompat, "Kinsey 0 same-gender pair is incompatible")
T.equal(reasonIncompat, "orientation_incompatible", "reports orientation_incompatible")

-- Deterministic roll forced to accept for alice + bob after age threshold.
local origRoll = Policy.Roll
Policy.Roll = function() return 0.01 end
local okPromo, reasonPromo = Relationships.EvaluateNPCRomancePromotion("alice", "bob", 50)
T.truthy(okPromo, "compatible mature friends promote to lovers")
T.equal(reasonPromo, "lover_promoted", "reports lover_promoted")
T.equal(alice.social.relationships["npc:bob"].bond.class, "lover", "alice->bob bond is lover")
T.equal(bob.social.relationships["npc:alice"].bond.class, "lover", "bob->alice bond is lover")

-- Exclusivity: alice (normal jealousyStyle) already has living lover bob.
local evan = makeNPC("evan", false, 3)
setFriendEdge(alice, "npc:evan", 0)
setFriendEdge(evan, "npc:alice", 0)
local okSecond, reasonSecond = Relationships.EvaluateNPCRomancePromotion("alice", "evan", 80)
T.falsy(okSecond, "monogamous NPC with living lover cannot promote a second lover")
T.equal(reasonSecond, "already_has_lover", "reports already_has_lover")

Policy.Roll = origRoll
T.finish("pnc_npc_social_relationships_smoke")
