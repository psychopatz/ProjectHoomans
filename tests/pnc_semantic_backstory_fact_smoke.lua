local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

getModFileReader = function(modID, path)
    local file = io.open(T.path(tostring(modID), "common_mod", path), "r")
    if not file then return nil end
    return {
        readLine = function() return file:read("*l") end,
        close = function() file:close() end,
    }
end

T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Core.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Constants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Memory/PNC_ConversationMemory.lua"
)
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions.lua"
)
local Facts = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueFacts.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueBackstoryFactSource.lua"
)

local record = {
    id = "npc:semantic:backstory",
    identitySeed = 44,
    tacticalClass = "colonist",
    identity = {
        seed = 44,
        backstory = {
            schemaVersion = 1,
            catalogVersion = 1,
            selectionClass = "colonist",
            overrides = {
                former_job = "backstory.colonist.former_job.doctor",
                hometown = "backstory.shared.hometown.rosewood",
            },
        },
    },
}

T.truthy(Facts.GetProvider("npc_backstory"),
    "offline NPC backstory provider was not registered")

local english = Facts.Resolve({
    subject = "NPC_BACKSTORY",
    slots = { kind = "former_job" },
}, nil, {
    npcRecord = record,
    language = "EN",
    authoritativeBackstoryAccess = true,
})
T.equal(english.status, "known", "English backstory fact is not known")
T.equal(english.factID, "backstory.colonist.former_job.doctor",
    "stable former-job fact ID changed")
T.equal(english.content, "doctor", "English backstory label changed")
T.equal(english.immutable, true, "backstory fact lost immutable marker")
T.equal(english.provenance,
    "PNC.Conversation.Memory.BackstoryDefinitions",
    "backstory fact provenance changed")

local tagalog = Facts.Resolve({
    subject = "NPC_BACKSTORY",
    slots = { topic = "job" },
}, nil, {
    npcRecord = record,
    language = "TL",
    authoritativeBackstoryAccess = true,
})
T.equal(tagalog.status, "known", "TL backstory fact is not known")
T.equal(tagalog.factID, english.factID,
    "language changed the stable former-job fact ID")
T.equal(tagalog.content, "doktor", "TL backstory label was not resolved")

local hometown = Facts.Resolve({
    subject = "NPC_BACKSTORY",
    slots = { kind = "hometown" },
}, nil, {
    npcRecord = record,
    language = "EN",
    authoritativeBackstoryAccess = true,
})
T.equal(hometown.status, "known", "hometown backstory fact is not known")
T.equal(hometown.content, "Rosewood", "hometown label changed")

local ambiguous = Facts.Resolve({
    subject = "NPC_BACKSTORY",
}, nil, { npcRecord = record, language = "EN" })
T.equal(ambiguous.status, "ambiguous",
    "missing backstory kind did not remain ambiguous")

local missing = Facts.Resolve({
    subject = "NPC_BACKSTORY",
    slots = { kind = "hobby" },
}, nil, { language = "EN" })
T.equal(missing.status, "unknown",
    "backstory provider exposed facts without an authoritative record")
T.equal(missing.reason, "backstory_not_disclosed",
    "missing unauthorized record reason changed")

local unsupported = Facts.Resolve({
    subject = "NPC_BACKSTORY",
    slots = { kind = "current_residence" },
}, nil, { npcRecord = record, language = "EN",
    authoritativeBackstoryAccess = true })
T.equal(unsupported.status, "unknown",
    "mutable residence was treated as immutable backstory")

T.finish("pnc_semantic_backstory_fact_smoke")
