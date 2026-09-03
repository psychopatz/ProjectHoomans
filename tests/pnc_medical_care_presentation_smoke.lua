local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

PNC = {
    ClientPresenceSync = { Internal = {} },
    Animation = {
        PlayBump = function() end,
        MaintainBump = function() end,
        FinishBump = function() end,
    },
}

T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Treatment.lua")

local internal = PNC.ClientPresenceSync.Internal
local presentation = internal.GetTreatmentPresentation({
    medicalCareState = {
        phase = "treating",
        taskId = "medical:1",
        patientId = "patient",
        partId = "Head",
        bump = "LootHigh",
        lootPosition = "High",
        startedAt = 100,
        finishAt = 200,
    },
})
T.truthy(presentation, "medical care has a client presentation")
T.equal(presentation.source, "medical", "medical care is not self-treatment")
T.equal(presentation.anim, "LootHigh",
    "medical care uses the player-to-NPC bedside bump")
T.equal(presentation.lootPosition, "High",
    "medical care preserves the patient body-part pose")

T.finish("pnc_medical_care_presentation_smoke")
