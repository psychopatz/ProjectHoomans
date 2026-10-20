local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

PsychopatzCore = {}
PNC = {
    Core = {
        IsAuthority = function() return true end,
        GenerateID = (function()
            local sequence = 0
            return function(prefix)
                sequence = sequence + 1
                return tostring(prefix) .. ":" .. tostring(sequence)
            end
        end)(),
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
}

ModData = {
    store = {},
    getOrCreate = function(key)
        ModData.store[key] = ModData.store[key] or {}
        return ModData.store[key]
    end,
}

T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Knowledge/PNC_KnowledgeRegistry.lua")
T.load(SHARED .. "Knowledge/PNC_KnowledgeBuiltins.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Memory/PNC_ConversationMemory.lua"
)

local Memory = PNC.Conversation.Memory
T.truthy(Memory.RegisterBackstory({
    id = "backstory.colonist.former_job.smoke_doctor",
    kind = "former_job", class = "colonist", value = "doctor", weight = 1,
}), "former-job fixture registration")
T.truthy(Memory.RegisterBackstory({
    id = "backstory.colonist.hometown.smoke_rosewood",
    kind = "hometown", class = "colonist", value = "Rosewood", weight = 1,
}), "hometown fixture registration")

local npc = {
    id = "npc:backstory:privacy",
    identitySeed = 77,
    identity = { seed = 77 },
    tacticalClass = "colonist",
}
local familiarityByCharacter = { char_a = 20, char_b = 80 }
PNC.Registry = {
    Get = function(id)
        return tostring(id) == npc.id and npc or nil
    end,
    MarkDirty = function() end,
}
PNC.PlayerCharacters = {
    GetRegistryRecord = function(characterUUID)
        return { accountKey = "test-account", characterUUID = characterUUID }
    end,
}
PNC.Relationships = {
    Get = function(_, key)
        local parsed = PNC.EntityRef.Parse(key)
        local characterUUID = parsed and parsed.characterUUID or ""
        return {
            familiarity = familiarityByCharacter[characterUUID] or 0,
            approval = 0,
        }
    end,
}

T.load(SERVER .. "Knowledge/PNC_NPCKnowledgeService.lua")
local Knowledge = PNC.NPCKnowledge

local preview = Knowledge.PreviewBackstory(
    "char_a", npc.id, "former_job"
)
T.equal(preview.allowed, false,
    "familiarity does not automatically authorize a private backstory fact")
T.equal(preview.reason, "insufficient_familiarity",
    "private backstory gate lost its familiarity reason")
T.equal(Knowledge.GetDescriptor(
    "char_a", npc.id, "history.backstory.former_job"
), nil, "familiarity did not auto-reveal former work")

familiarityByCharacter.char_a = 80
local disclosure = Knowledge.DiscloseBackstory(
    "char_a", npc.id, "job", { sourceEventID = "smoke:direct" }
)
T.truthy(disclosure, "authorized backstory disclosure failed")
T.equal(disclosure.discovered.status, "confirmed",
    "direct backstory disclosure did not confirm evidence")
T.equal(disclosure.discovered.value, "doctor",
    "backstory disclosure copied the wrong stable value")
T.equal(disclosure.evidence.sourceType, "direct_disclosure",
    "backstory disclosure bypassed the ordinary evidence source")

local snapshotA = Knowledge.BuildPlayerSnapshot("char_a", npc.id)
local snapshotB = Knowledge.BuildPlayerSnapshot("char_b", npc.id)
local foundFormerJob = false
local foundHometown = false
for _, category in ipairs(snapshotA.categories) do
    for _, descriptor in ipairs(category.descriptors) do
        T.equal(descriptor.identitySeed, nil,
            "dossier descriptor leaked identity seed")
        T.equal(descriptor.facts, nil,
            "dossier descriptor leaked generated biography")
        if descriptor.presentation.backstoryKind == "former_job" then
            foundFormerJob = descriptor.value == "doctor"
        end
    end
end
T.truthy(foundFormerJob, "confirmed former work missing from player A dossier")
T.equal(#snapshotB.categories, 0,
    "player B received player A's private backstory fact")

local Facts = T.load(
    "ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticDialogueFacts.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueBackstoryFactSource.lua"
)
local hidden = Facts.Resolve({
    subject = "NPC_BACKSTORY", slots = { kind = "hometown" },
}, nil, { npcRecord = npc, language = "EN" })
T.equal(hidden.status, "unknown",
    "raw NPC record exposed an undisclosed backstory fact")
T.equal(hidden.reason, "backstory_not_disclosed",
    "undisclosed backstory did not return an explicit uncertainty reason")

local known = Facts.Resolve({
    subject = "NPC_BACKSTORY", slots = { kind = "former_job" },
}, nil, { npcRecord = npc, npcKnowledge = snapshotA, language = "EN" })
T.equal(known.status, "known",
    "authorized player snapshot was not usable by semantic dialogue")
T.equal(known.content, "doctor",
    "semantic dialogue returned the wrong authorized backstory content")

local llmFacts = Memory.BuildAuthorizedBackstoryFacts(
    npc, snapshotA, 10, "EN"
)
T.equal(#llmFacts, 1,
    "PBrainZ did not receive the player's authorized backstory projection")
T.equal(llmFacts[1].content, "doctor",
    "PBrainZ received the wrong authorized backstory content")
T.equal(llmFacts[1].authorized, true,
    "PBrainZ backstory fact was not marked as authorized")
T.equal(Memory.BuildAuthorizedBackstoryFacts(npc, snapshotB, 10, "EN")[1], nil,
    "PBrainZ received undisclosed facts from the raw NPC record")

familiarityByCharacter.char_b = 80
local secondDisclosure = Knowledge.DiscloseBackstory(
    "char_b", npc.id, "hometown", { sourceEventID = "smoke:hometown" }
)
T.truthy(secondDisclosure, "player B could not disclose a separate fact")
snapshotB = Knowledge.BuildPlayerSnapshot("char_b", npc.id)
T.truthy(#snapshotB.categories > 0,
    "player B dossier did not receive its own disclosed fact")
T.equal(Knowledge.GetDescriptor(
    "char_a", npc.id, "history.backstory.hometown"
), nil, "player B disclosure contaminated player A knowledge")

local translation = {
    UI_PNC_KnowledgeFact_BackstoryFormerJob = "Former work",
    UI_PNC_KnowledgeFact_BackstoryHometown = "Dating trabaho",
}
getText = function(key)
    return translation[key] or key
end
T.load(
    "ProjectHoomans", "client", "PNC/UI/Knowledge/PNC_KnowledgePresentation.lua"
)
local Presentation = PNC.KnowledgePresentation
local rows = Presentation.BuildDossierRows(snapshotA)
local formerRow
for _, section in ipairs(rows) do
    for _, row in ipairs(section.rows) do
        if row.descriptorID == "history.backstory.former_job" then
            formerRow = row
        end
    end
end
T.truthy(formerRow, "confirmed backstory fact missing from dossier rows")
T.equal(formerRow.label, "Former work",
    "EN backstory dossier label was not translated")
T.equal(formerRow.value, "Doctor • Confirmed",
    "confirmed backstory dossier status was not rendered")

local suspectedSnapshot = {
    categories = {{
        id = "history",
        descriptors = {{
            descriptorID = "history.backstory.hometown",
            valueType = "text_enum",
            value = "Muldraugh",
            content = "Muldraugh",
            status = "suspected",
            confidence = .45,
            primarySource = "trusted_gossip",
            presentation = {
                backstoryKind = "hometown",
                labelKey = "UI_PNC_KnowledgeFact_BackstoryHometown",
            },
        }},
    }},
}
local suspectedFact = Facts.Resolve({
    subject = "NPC_BACKSTORY", slots = { kind = "hometown" },
}, nil, {
    npcRecord = npc,
    npcKnowledge = suspectedSnapshot,
    language = "EN",
})
T.equal(suspectedFact.status, "suspected",
    "suspected backstory evidence did not remain uncertain")
T.equal(suspectedFact.content, "Muldraugh",
    "suspected player observation was replaced by canonical private truth")
local suspectedRows = Presentation.BuildDossierRows(suspectedSnapshot)
T.equal(suspectedRows[1].rows[1].label, "Dating trabaho",
    "TL backstory dossier label was not translated")
T.equal(suspectedRows[1].rows[1].value, "Possibly Muldraugh",
    "suspected backstory dossier status was not rendered as uncertain")

T.finish("pnc_backstory_knowledge_disclosure_smoke")
