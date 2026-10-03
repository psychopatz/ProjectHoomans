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

function H.Resolve(record, runtime)
    local owner = Common.GetOwner(record)
    local orderSpec = record.orderSpec
    local state
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
        -- like "following" while nothing can move. Retry resolution, wake the
        -- presence pass, and report once before falling back to the anchor.
        local attempts = (tonumber(runtime.followOwnerResolveAttempts) or 0) + 1
        local maxAttempts = tonumber(
            Const.FOLLOW_OWNER_RESOLVE_MAX_ATTEMPTS) or 5
        runtime.followOwnerResolveAttempts = attempts
        runtime.forcePresenceCheck = true
        if attempts <= maxAttempts then
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
                        "maxAttempts=" .. tostring(maxAttempts),
                    })
            end
            return nil, state, true
        end
    elseif runtime.followOwnerResolveAttempts ~= nil then
        runtime.followOwnerResolveAttempts = nil
    end
    return owner, state, false
end

return Companion
