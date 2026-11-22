local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local records = {}
PNC = {
    Semantics = {},
    Registry = {
        Get = function(id) return records[tostring(id or "")] end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
}

-- Stub minimal provider dependencies for GeneratedAffordanceProvider
package.loaded["PNC/ConvoEngine/UtterancePlan"] = {
    New = function(spec) return spec end,
    Realize = function(plan)
        return { text = tostring(plan.strategy or plan.dialogueAct or "ok") }
    end,
}
package.loaded["PNC/ConvoEngine/Interaction/Providers"] = {
    EvidenceQueryForStimulus = function() return nil end,
    QueryEvidence = function()
        return { rows = { { relation = "test", confidence = 1 } } }
    end,
}
package.loaded["PNC/Semantics/PNC_SemanticPragmaticResolver"] = {
    ResolveEvidence = function()
        return { status = "resolved", confidence = 1 }
    end,
}
package.loaded["PNC/ConvoEngine/Interaction/Stimulus"] = {
    FromIR = function(ir)
        local output = {}
        for key, value in pairs(ir or {}) do output[key] = value end
        output.type = output.type or "DIALOGUE"
        return output
    end,
}
package.loaded["PNC/ConvoEngine/Interaction/Relations"] = {
    ContextualActs = function() return {} end,
    GetAct = function() return nil end,
}

local Projection = T.load(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/DispositionProjection.lua"
)
local Adapter = T.load(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/Interaction/ActorAdapter_ProjectHoomans.lua"
)
local ChoicePolicy = T.load(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/Social/ChoicePolicy.lua"
)
local AffordanceResponder = T.load(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/Suggestions/AffordanceResponder.lua"
)
local AffordanceProvider = T.load(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/Suggestions/GeneratedAffordanceProvider.lua"
)

-- 1. Same trait set + different identity seeds -> different resolved tendencies
local seedA = Projection.Resolve({
    id = "stub-seed-a",
    identitySeed = 104729,
    traits = { Brave = true },
})
local seedB = Projection.Resolve({
    id = "stub-seed-b",
    identitySeed = 891347,
    traits = { Brave = true },
})
local differs = seedA.baseDisposition.bravery ~= seedB.baseDisposition.bravery
    or seedA.baseDisposition.aggression ~= seedB.baseDisposition.aggression
    or seedA.baseDisposition.compassion ~= seedB.baseDisposition.compassion
    or seedA.baseDisposition.sociability ~= seedB.baseDisposition.sociability
T.truthy(differs,
    "same trait set with different identity seeds yields distinct tendencies")

-- 2. High numeric bravery/confidence WITHOUT literal Brave trait scores courageous
--    choices and unlocks CALL_BLUFF
local numericBraveActor = {
    id = "npc-numeric-brave",
    capabilities = { speech = true },
    personality = {
        bravery = 0.85,
        confidence = 0.85,
        aggression = 0.60,
        compassion = 0.45,
        sociability = 0.50,
        forgiveness = 0.40,
        materialism = 0.50,
        loyalty = 0.60,
    },
    traits = {},
}
local numericBraveResolved = Projection.Resolve(numericBraveActor)
T.equal(numericBraveResolved.styleProfile, "brave",
    "high numeric bravery/confidence resolves brave style without Brave trait")

local frontier = {
    { id = "generated.call_bluff", strategy = "CALL_BLUFF", stance = "NEGATIVE",
      eligibility = { allowed = true, status = "allowed" } },
    { id = "generated.apologize", strategy = "APOLOGIZE", stance = "POSITIVE",
      eligibility = { allowed = true, status = "allowed" } },
}
local numericBraveChoice = ChoicePolicy.Select(frontier, {
    motive = "DISPUTE",
    relevance = 0.9,
    responderProjection = {
        actor = numericBraveActor,
        relationship = { approval = -0.3, respect = -0.2 },
    },
})
T.equal(numericBraveChoice.selected.strategy, "CALL_BLUFF",
    "high numeric bravery/confidence selects courageous choice without Brave trait")

local hostileContext = {
    affordanceRecipientRef = "npc-target",
    dialogueIR = {
        intent = "THREATEN",
        speechAct = "THREATEN",
        subject = "RECIPIENT",
        extensions = { socialFeatures = { hostility = 0.9 } },
    },
}
local numericBraveRows = AffordanceProvider.collectForResponder(hostileContext, {
    actorID = "npc-numeric-brave",
    turnSpeaker = "npc-numeric-brave",
    name = "Numeric Brave",
    personality = numericBraveActor.personality,
    traits = {},
    visibility = "semantic",
})
local byStrategy = {}
for _, row in ipairs(numericBraveRows) do byStrategy[row.strategy] = row end
T.truthy(byStrategy.CALL_BLUFF,
    "high numeric bravery/confidence unlocks CALL_BLUFF without Brave trait")
T.equal(byStrategy.CALL_BLUFF.contextReason, "responder_disposition:courage",
    "numeric disposition unlock reports disposition provenance")

-- High numeric compassion without Kind/Empathetic trait unlocks COMFORT
local numericKindRows = AffordanceProvider.collectForResponder(hostileContext, {
    actorID = "npc-numeric-kind",
    turnSpeaker = "npc-numeric-kind",
    name = "Numeric Kind",
    personality = { compassion = 0.80, sociability = 0.65, bravery = 0.45 },
    traits = {},
    visibility = "semantic",
})
local kindByStrategy = {}
for _, row in ipairs(numericKindRows) do kindByStrategy[row.strategy] = row end
T.truthy(kindByStrategy.COMFORT,
    "high numeric compassion unlocks COMFORT without Kind/Empathetic trait")
T.equal(kindByStrategy.COMFORT.contextReason, "responder_disposition:compassion",
    "numeric compassion unlock reports disposition provenance")

-- 3. Literal Brave trait does NOT force brave behavior when profile/context disagrees
local braveTraitLowProfile = {
    id = "npc-brave-low-profile",
    capabilities = { speech = true },
    social = {
        personality = {
            bravery = 0.30,
            confidence = 0.28,
            aggression = 0.25,
            compassion = 0.55,
            sociability = 0.45,
            forgiveness = 0.60,
        },
    },
    traits = { Brave = true, Desensitized = true },
}
local lowProfileResolved = Projection.Resolve(braveTraitLowProfile)
T.equal(lowProfileResolved.styleProfile, "shaken",
    "literal Brave trait cannot override low resolved numeric profile")
local lowProfileRows = AffordanceProvider.collectForResponder(hostileContext, {
    actorID = "npc-brave-low-profile",
    turnSpeaker = "npc-brave-low-profile",
    name = "Shaken Veteran",
    social = braveTraitLowProfile.social,
    traits = braveTraitLowProfile.traits,
    visibility = "semantic",
})
local lowProfileByStrategy = {}
for _, row in ipairs(lowProfileRows) do lowProfileByStrategy[row.strategy] = row end
T.equal(lowProfileByStrategy.CALL_BLUFF, nil,
    "Brave trait does not unlock CALL_BLUFF when resolved profile is low")

-- High panic + griefStress overrides bare Brave trait too
local panickedBraveRows = AffordanceProvider.collectForResponder(hostileContext, {
    actorID = "npc-brave-panicked",
    turnSpeaker = "npc-brave-panicked",
    name = "Panicked Brave",
    traits = { Brave = true },
    condition = { panic = 85 },
    temporaryDemeanor = { griefStress = 35, confidencePressure = 25 },
    visibility = "semantic",
})
local panickedByStrategy = {}
for _, row in ipairs(panickedBraveRows) do panickedByStrategy[row.strategy] = row end
T.equal(panickedByStrategy.CALL_BLUFF, nil,
    "Brave trait does not unlock CALL_BLUFF under high panic and grief")
local panickedDisp = AffordanceResponder.EffectiveDisposition({
    affordanceResponder = {
        actorID = "npc-brave-panicked",
        traits = { Brave = true },
        condition = { panic = 85 },
        temporaryDemeanor = { griefStress = 35, confidencePressure = 25 },
    },
})
T.equal(
    Projection.ResolveStyle(panickedDisp, { panic = 85 }),
    "shaken",
    "panicked and grieving Brave actor resolves shaken style"
)

-- 4. No trait double-counting when numeric personality already exists
local baseProfile = {
    bravery = 0.60,
    confidence = 0.60,
    aggression = 0.55,
    compassion = 0.50,
    sociability = 0.50,
    forgiveness = 0.50,
    materialism = 0.50,
    loyalty = 0.50,
}
local withoutTraits = {
    id = "npc-no-traits",
    capabilities = { speech = true },
    social = { personality = baseProfile },
    traits = {},
}
local withTraits = {
    id = "npc-with-traits",
    capabilities = { speech = true },
    social = { personality = baseProfile },
    traits = { Brave = true, Desensitized = true, Kind = true, Empathetic = true },
}
local rWithout = Projection.Resolve(withoutTraits)
local rWith = Projection.Resolve(withTraits)
T.equal(rWith.baseDisposition.bravery, rWithout.baseDisposition.bravery,
    "Brave trait is not double-counted onto existing numeric bravery")
T.equal(rWith.baseDisposition.compassion, rWithout.baseDisposition.compassion,
    "Kind/Empathetic traits are not double-counted onto existing numeric compassion")
local cWithout = ChoicePolicy.Select(frontier, {
    motive = "REACT",
    relevance = 0.8,
    responderProjection = { actor = withoutTraits, relationship = {} },
})
local cWith = ChoicePolicy.Select(frontier, {
    motive = "REACT",
    relevance = 0.8,
    responderProjection = { actor = withTraits, relationship = {} },
})
T.equal(cWith.selectedScore, cWithout.selectedScore,
    "ChoicePolicy produces identical scores without trait double-counting")

-- 5. Temporary demeanor modulates effectiveDisposition without mutating
--    baseDisposition or stored social.personality, and integrates in ActorAdapter
local npcRecord = {
    id = "npc-demeanor-test",
    alive = true,
    social = {
        personality = {
            bravery = 0.78,
            aggression = 0.35,
            compassion = 0.70,
            sociability = 0.60,
            forgiveness = 0.65,
            materialism = 0.40,
            loyalty = 0.80,
        },
    },
    npcTraits = { pnc_veteran = true },
    conditionStats = { panic = 10, stress = 0.1 },
    needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
    runtime = {
        temporaryDemeanor = {
            vigilanceFear = 40,
            griefStress = 30,
            confidencePressure = 30,
            scarcityAnxiety = 20,
        },
    },
}
records["npc-demeanor-test"] = npcRecord

local adapted = Adapter.ProjectActor(npcRecord)
T.truthy(adapted ~= nil, "ActorAdapter projects managed NPC record")
T.truthy(type(adapted.baseDisposition) == "table",
    "ActorAdapter attaches baseDisposition")
T.truthy(type(adapted.temporaryDemeanor) == "table",
    "ActorAdapter attaches temporaryDemeanor")
T.truthy(type(adapted.effectiveDisposition) == "table",
    "ActorAdapter attaches effectiveDisposition")
T.equal(adapted.baseDisposition.bravery, 78,
    "baseDisposition retains canonical 0..100 personality without trait double-count")
T.truthy(adapted.effectiveDisposition.bravery < adapted.baseDisposition.bravery,
    "temporaryDemeanor reduces effective bravery")
T.truthy(adapted.effectiveDisposition.confidence < adapted.baseDisposition.confidence,
    "temporaryDemeanor reduces effective confidence")
T.truthy(adapted.effectiveDisposition.materialism > adapted.baseDisposition.materialism,
    "scarcityAnxiety raises effective materialism")
T.equal(adapted.dispositionStyle, "shaken",
    "ActorAdapter exposes unified dispositionStyle")
T.equal(npcRecord.social.personality.bravery, 0.78,
    "stored social.personality.bravery remains unmutated")
T.equal(npcRecord.social.personality.materialism, 0.40,
    "stored social.personality.materialism remains unmutated")
T.equal(npcRecord.social.personality.confidence, nil,
    "stored social.personality receives no injected fields")

-- 6. Kahlua2 safety check on DispositionProjection.lua
local dispSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/ConvoEngine/DispositionProjection.lua"
)
T.falsy(string.find(dispSource, "pcall(", 1, true),
    "DispositionProjection uses zero pcall")
T.falsy(string.find(dispSource, "Events.OnTick", 1, true),
    "DispositionProjection uses zero OnTick hooks")
T.falsy(string.find(dispSource, "ModData", 1, true),
    "DispositionProjection performs zero ModData persistence")
T.falsy(string.find(dispSource, "next(", 1, true),
    "DispositionProjection avoids Kahlua2-unsafe next()")

T.finish("pnc_unified_disposition_projection_smoke")
