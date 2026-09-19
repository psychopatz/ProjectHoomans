local T = require "tests/support/test"

T.addPackagePaths()

local now = 1000
local auditLines = {}
PNC = {
    Const = {
        PLAYER_HIT_REPORT_COOLDOWN_MS = 80,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsRecordDebugEnabled = function(record)
            return record and record.runtime
                and record.runtime.debug == true or false
        end,
        LogRecordDebug = function(_, message)
            auditLines[#auditLines + 1] = message
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_PlayerDamage.lua")

local PlayerDamage = PNC.PlayerDamage
local report, reason = PlayerDamage.Report.Create({
    id = "npc-1",
    attackerOnlineID = 12,
    bodyOnlineID = 77,
    bodyInstanceID = 991,
    bodyLease = "lease-1",
    weaponFullType = "Base.Axe",
    damage = 1.5,
    liveObject = {},
})
T.equal(reason, nil, "new report contract creation")
T.equal(report.schemaVersion, 1, "new report is versioned")
T.equal(report.id, "npc-1", "report target is a stable string ID")
T.equal(report.attackerOnlineID, 12, "report player ID is numeric")
T.equal(report.bodyInstanceID, "991", "body instance is a scalar ID")
T.equal(report.damage, 1.5, "reported damage is normalized")
T.equal(report.liveObject, nil, "report drops unknown runtime objects")

local legacy = PlayerDamage.Report.Normalize({
    id = "legacy-npc",
    damage = "2.5",
    weaponFullType = "Base.Knife",
})
T.equal(legacy.schemaVersion, 1, "legacy reports normalize to v1")
T.equal(legacy.damage, 2.5, "legacy numeric damage remains compatible")
local rejected, rejectionReason = PlayerDamage.Report.Normalize({
    schemaVersion = 2,
    id = "npc-2",
})
T.equal(rejected, nil, "unsupported report version rejected")
T.equal(rejectionReason, "unsupported_report_version",
    "unsupported version reason")
rejected, rejectionReason = PlayerDamage.Report.Normalize({
    id = "npc-3",
    attackerOnlineID = "not-a-number",
})
T.equal(rejected, nil, "malformed authority identifier rejected")
T.equal(rejectionReason, "invalid_report", "malformed field reason")

local debugRecord = {
    id = string.rep("npc", 40),
    runtime = { debug = false },
}
T.equal(PlayerDamage.Internal.Audit(
    debugRecord, "client_request", "sent", "report_sent", 12,
    "Base.Axe", 1.5), false, "diagnostics are disabled by default")
T.equal(#auditLines, 0, "disabled diagnostic does not log")
debugRecord.runtime.debug = true
T.equal(PlayerDamage.Internal.Audit(
    debugRecord, "client\n" .. string.rep("x", 100), "sent",
    "report_sent", 12, "Base.Axe", 1.5), true,
    "record debug enables the bounded diagnostic")
T.contains(auditLines[1], "health.player_hit event=client",
    "diagnostic has a stable event signature")
T.falsy(auditLines[1]:find("\n", 1, true),
    "diagnostic strips control characters")
T.truthy(#auditLines[1] <= 600, "diagnostic fields are bounded")

local admit = PlayerDamage.Internal.AdmitReportKey
local playerLimit = PlayerDamage.Internal.ReportsPerPlayerLimit
local trackingLimit = PlayerDamage.Internal.ReportTrackingLimit
local index
local admitted
local capacityReason
for index = 1, playerLimit do
    admitted = admit("player-1", "player-1:npc-" .. tostring(index), now)
    T.equal(admitted, true, "player report slot accepted " .. tostring(index))
end
admitted, capacityReason = admit("player-1", "player-1:npc-overflow", now)
T.equal(admitted, false, "per-player report tracking is bounded")
T.equal(capacityReason, "tracking_capacity", "per-player capacity reason")
local duplicate, duplicateReason = admit(
    "player-1", "player-1:npc-1", now)
T.equal(duplicate, false, "duplicate target remains rate limited")
T.equal(duplicateReason, "rate_limited", "duplicate cooldown reason")
admitted = admit("player-2", "player-2:npc-1", now)
T.equal(admitted, true, "one player's ceiling does not block another")

for index = 2, trackingLimit / playerLimit do
    local firstTarget = index == 2 and 2 or 1
    local targetIndex
    for targetIndex = firstTarget, playerLimit do
        local playerKey = "player-" .. tostring(index)
        admitted = admit(
            playerKey,
            playerKey .. ":npc-" .. tostring(targetIndex),
            now
        )
        T.equal(admitted, true, "bounded report slot accepted")
    end
end
T.equal(PlayerDamage.Internal.ReportTracker.Count, trackingLimit,
    "global report queue has a fixed capacity")
local count = 0
local key
for key in pairs(PlayerDamage.LastReportAt) do
    count = count + 1
end
T.equal(count, trackingLimit, "cooldown map is bounded by live queue slots")
admitted, capacityReason = admit("player-overflow",
    "player-overflow:npc-1", now)
T.equal(admitted, false, "global report capacity fails closed")
T.equal(capacityReason, "tracking_capacity", "global capacity reason")

now = now + 81
admitted = admit("player-overflow", "player-overflow:npc-1", now)
T.equal(admitted, true, "expired report slots are reclaimed")
T.truthy(PlayerDamage.Internal.ReportTracker.Count < trackingLimit,
    "expired reports release bounded queue capacity")
T.equal(PlayerDamage.LastReportAt["player-1:npc-1"], nil,
    "expired cooldown keys are removed")

T.finish("pnc_player_damage_report_contract_smoke")
