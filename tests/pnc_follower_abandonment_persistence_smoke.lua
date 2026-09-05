local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")

PNC = {
    Persistence = { Internal = {} },
    Core = {},
}

T.load(SHARED .. "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Primitives.lua")
T.load(SHARED .. "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_RecordState.lua")

local sanitize = PNC.Persistence.Internal.sanitizeFollowerAbandonment
local marker = sanitize({
    eventID = "social:follow_abandonment:npc-1:2:3000",
    ownerKey = "player:account:character-1",
    ownerUsername = "Mara",
    ownerOnlineID = 4,
    hostileKind = "zombie",
    hostileID = 88,
    capturedAt = 3,
    relationshipApplied = true,
    ignored = "not persisted",
})

T.truthy(marker, "valid pending marker survives normalization")
T.equal(marker.eventID, "social:follow_abandonment:npc-1:2:3000",
    "pending marker preserves its id")
T.equal(marker.hostileKind, "zombie",
    "pending marker preserves hostile classification")
T.equal(marker.relationshipApplied, true,
    "pending marker preserves relationship application state")
T.equal(marker.ignored, nil,
    "pending marker remains a compact whitelisted shape")
T.equal(sanitize({ eventID = "bad", hostileKind = "player" }), nil,
    "invalid hostile classifications are discarded")

return T.finish("pnc_follower_abandonment_persistence_smoke")
