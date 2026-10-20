local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local Adapter = PNC.Persistence.CorePresentation
local registry = Core.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:p6:hoomans-bridge",
    identitySeed = "p6-hoomans-bridge",
    world = { position = { x = 4, y = 8, z = 0 } },
})
T.truthy(actor, actorReason)
T.truthy(Adapter, "Core presentation adapter missing")

local portrait, portraitReason = Adapter.BuildPortrait(actor, PsychopatzCore)
T.truthy(portrait, portraitReason)
T.equal(portrait.actorID, actor.actorId, "portrait actor identity")
T.equal(portrait.face.hairModel, actor.appearance.resolved.hairModel,
    "portrait appearance bridge")

local entry, entryReason = Adapter.BuildMapEntry(actor, PsychopatzCore, {
    visibility = "public",
    knownTo = { "player:bridge" },
})
T.truthy(entry, entryReason)
T.equal(entry.position.x, 4, "map position bridge")

local request, requestReason = Adapter.BuildNearbyConversation(entry,
    PsychopatzCore, "player:bridge", 1)
T.truthy(request, requestReason)
T.equal(request.actorID, actor.actorId, "conversation actor bridge")

local queue = Core.Notifications.NewQueue()
local notice, noticeReason = Adapter.PublishNotification(queue,
    PsychopatzCore, {
        notificationID = "notice:p6:bridge",
        kind = "conversation_available",
        actorID = actor.actorId,
    })
T.truthy(notice, noticeReason)
T.equal(queue:List()[1].kind, "conversation_available",
    "notification bridge")

T.finish("pnc_npc_foundation_core_presentation_smoke")
