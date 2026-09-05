local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")

local player = {
    getUsername = function() return "Mara" end,
    getOnlineID = function() return 4 end,
}
local body = {
    isDead = function() return false end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local relationship = {
    approval = 20,
    respect = 10,
    familiarity = 4,
    state = "familiar",
}
local emitted = {}
local sent = {}
local dirty = {}

PNC = {
    Core = {
        IsAuthority = function() return true end,
        ResolvePlayerByOnlineID = function() return nil end,
        ResolvePlayerByUsername = function() return player end,
    },
    Const = { ORDER_FOLLOW = "follow" },
    BehaviorCommon = {
        GetOwner = function() return player end,
        IsActiveFollowCombatTarget = function(record)
            local target = record.runtime and record.runtime.target
            local state = record.runtime and record.runtime.followState
            if record.orderSpec.kind ~= "follow"
                or not target
                or (target.kind ~= "zombie" and target.kind ~= "npc")
                or not state
                or state.mode ~= "combat"
            then
                return nil
            end
            return target, target.kind, "follow_combat_mode"
        end,
    },
    Registry = {
        MarkDirty = function(record, domain)
            dirty[#dirty + 1] = { id = record.id, domain = domain }
            return true
        end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    PlayerCharacters = {
        GetEntityKey = function() return "player:account:character-1" end,
    },
    SocialEvents = {
        Emit = function(event)
            emitted[#emitted + 1] = event
            return { ok = true, eventID = event.id }
        end,
    },
    Relationships = {
        Get = function() return relationship end,
    },
    VanillaEmoteInteractions = {
        ResolveNPCType = function() return "colonist" end,
        ResolveRelationshipTier = function() return "familiar" end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(
            _, npcID, reason, context
        )
            sent[#sent + 1] = {
                npcID = npcID,
                reason = reason,
                context = context,
            }
            return true
        end,
    },
    SocialGreeting = {
        GREETING_RADIUS = 10,
        CanPlayerMeetNPC = function() return true, "visible", 0 end,
    },
    PerformanceScalingDiagnostics = {
        IsFollowerAbandonmentAuditEnabled = function() return false end,
        LogFollowerAbandonment = function() end,
    },
}

T.load(SHARED .. "PNC/Core/Relationships/PNC_EntityRef.lua")
T.load(SERVER .. "PNC/Social/PNC_FollowerAbandonmentService.lua")

local Service = PNC.FollowerAbandonment
local record = {
    id = "npc-follower",
    alive = true,
    ownerUsername = "Mara",
    ownerOnlineID = 4,
    presenceRevision = 7,
    orderSpec = { kind = "follow" },
    runtime = {
        target = { kind = "zombie", zombieId = 812 },
        followState = { mode = "combat" },
    },
}

local captured, marker = Service.CaptureAtRangeExit(record, body, 25)
T.equal(captured, true,
    "follow combat departure captures an abandonment: "
        .. tostring(marker and marker.eventID or marker))
T.equal(marker.hostileKind, "zombie", "capture records zombie hostility")
T.equal(marker.relationshipApplied, true,
    "capture applies the relationship event immediately")
T.equal(#emitted, 1, "capture emits one canonical social event")
T.equal(emitted[1].type, "abandoned_in_combat",
    "capture reuses the existing abandonment relationship definition")
T.equal(emitted[1].context.detection, "follow_range_exit",
    "capture records the lightweight follow-range detection source")

local delivered, deliveryReason = Service.TryDeliver(
    player,
    record,
    body,
    26,
    { meetingEligible = true }
)
T.equal(delivered, true, "return meeting delivers the pending commentary")
T.equal(deliveryReason, "delivered", "delivery reports its terminal result")
T.equal(#sent, 1, "return meeting sends one relationship presentation")
T.equal(
    sent[1].context.ambientFlavor.flavorID,
    "social.follower_abandoned_zombie",
    "zombie departure selects zombie return flavor"
)
T.equal(record.followerAbandonment, nil,
    "delivered marker is cleared and cannot repeat")
T.equal(Service.HasPending(record), false,
    "one-shot return commentary no longer remains pending")

record.runtime.target = { kind = "npc", id = "hostile-2" }
record.runtime.followState.mode = "combat"
record.presenceRevision = 8
local capturedNPC, markerNPC = Service.CaptureAtRangeExit(record, body, 30)
T.equal(capturedNPC, true, "hostile NPC departure is also captured")
T.equal(markerNPC.hostileKind, "npc",
    "capture distinguishes hostile NPC targets from zombies")
local deliveredNPC = Service.TryDeliver(
    player,
    record,
    body,
    31,
    { meetingEligible = true }
)
T.equal(deliveredNPC, true, "hostile NPC return commentary is delivered")
T.equal(
    sent[2].context.ambientFlavor.flavorID,
    "social.follower_abandoned_hostile_npc",
    "hostile NPC departure selects hostile NPC return flavor"
)

record.runtime.target = { kind = "player", id = "other-player" }
record.runtime.followState.mode = "combat"
record.presenceRevision = 9
local ignored = Service.CaptureAtRangeExit(record, body, 40)
T.equal(ignored, false, "player targets do not count as hostile abandonment")
T.equal(Service.HasPending(record), false,
    "ignored non-hostile target leaves no pending marker")

return T.finish("pnc_follower_abandonment_smoke")
