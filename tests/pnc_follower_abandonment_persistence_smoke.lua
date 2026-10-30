local T = require "tests/support/test"
T.addPackagePaths()

PNC = {
    Core = {},
}

local Repository = require "PNC/Core/Commands/PNC_CompanionRecordRepository"
local sanitize = Repository.NormalizeAbandonment
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
