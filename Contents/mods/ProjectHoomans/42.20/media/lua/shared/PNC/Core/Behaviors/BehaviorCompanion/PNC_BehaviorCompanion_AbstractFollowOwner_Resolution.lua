-- Durable owner recovery and unresolved-owner retry for abstract followers.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.AbstractFollowOwnerResolution
if type(H) ~= "table" then return Companion end

local Const = H.Const
local Common = H.Common
local Diagnostics = H.Diagnostics

local function followerPresenceAuditEnabled()
    return Diagnostics
        and Diagnostics.IsFollowerPresenceAuditEnabled
        and Diagnostics.IsFollowerPresenceAuditEnabled() == true
end

function H.Resolve(record, runtime, now)
    local owner = Common.GetOwner(record)
    local orderSpec = record.orderSpec
    local state
    local previousAttempts = tonumber(runtime.followOwnerResolveAttempts) or 0
    local auditEnabled = followerPresenceAuditEnabled()
    -- The durable follow order carries the owner identity even when record
    -- fields are missing after a rehydrated save or an abstract radio order.
    if not owner and orderSpec
        and tostring(orderSpec.kind or "")
            == tostring(Const.ORDER_FOLLOW or "follow")
    then
        if record.ownerUsername == nil and orderSpec.ownerUsername ~= nil then
            record.ownerUsername = orderSpec.ownerUsername
        end
        if record.ownerOnlineID == nil and orderSpec.ownerOnlineID ~= nil then
            record.ownerOnlineID = orderSpec.ownerOnlineID
        end
        if record.ownerUsername ~= nil or record.ownerOnlineID ~= nil then
            owner = Common.GetOwner(record)
        end
    end
    state = Internal.GetFollowState(record)
    if not owner then
        -- Do not silently walk a bodyless follower to its anchor. For a colonist
        -- that anchor is often the base it already occupies, so the failure looks
        -- like "following" while nothing can move. Retry on the normal abstract
        -- follow cadence instead of forcing a 50 ms presence wake on every miss.
        -- The order remains authoritative until it is explicitly cancelled.
        local attempts = math.min(previousAttempts + 1, 2147483647)
        runtime.followOwnerResolveAttempts = attempts
        record.activeBehavior = "FollowOwner:owner_unresolved"
        state.mode = "owner_unresolved"
        if attempts == 1 and auditEnabled
            and Diagnostics and Diagnostics.LogFollowerPresence
        then
            Diagnostics.LogFollowerPresence(
                "abstract_follow_owner_unresolved", {
                    "npc=" .. tostring(record.id),
                    "orderKind=" .. tostring(
                        orderSpec and orderSpec.kind or "nil"),
                    "orderOwner=" .. tostring(
                        orderSpec and orderSpec.ownerUsername or "nil"),
                    "orderOnlineID=" .. tostring(
                        orderSpec and orderSpec.ownerOnlineID or "nil"),
                    "recordOwner=" .. tostring(
                        record.ownerUsername or "nil"),
                    "recordOnlineID=" .. tostring(
                        record.ownerOnlineID or "nil"),
                    "attempt=" .. tostring(attempts),
                    "retryCadenceMs=" .. tostring(
                        Const.TICK_ABSTRACT_MS or 3000),
                    "now=" .. tostring(now or "nil"),
                })
        end
        return nil, state, true
    elseif runtime.followOwnerResolveAttempts ~= nil then
        if previousAttempts > 0 and auditEnabled
            and Diagnostics and Diagnostics.LogFollowerPresence
        then
            Diagnostics.LogFollowerPresence(
                "abstract_follow_owner_resolved", {
                    "npc=" .. tostring(record.id),
                    "attempts=" .. tostring(previousAttempts),
                    "now=" .. tostring(now or "nil"),
                })
        end
        runtime.followOwnerResolveAttempts = nil
    end
    return owner, state, false
end

return Companion
