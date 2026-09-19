--[[
    PNC Native Passage: select and start window obstruction responses.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared
local Window = Passage.WindowInternal

local TraversalQuery = PNC.TraversalQuery
local PathInternal = PNC.PathService
    and PNC.PathService.Internal or nil

local clearOwnedPath = Controller.ClearOwnedPath
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local WINDOW_COOLDOWN_MS = Window.CooldownMs
local WINDOW_LANDING_BACKOFF_MS = Window.LandingBackoffMs
local logPassageEvent = Shared.LogPassageEvent
local objectBool = Shared.ObjectBool

local function tryWindow(snapshot, body, state, passage, object, now)
    if not TraversalQuery.IsWindow
        or not TraversalQuery.IsWindow(object)
    then
        return false, nil
    end
    local open = objectBool(object, "IsOpen")
        or objectBool(object, "isOpen")
    local smashed = objectBool(object, "isSmashed")
        or objectBool(object, "IsSmashed")
    if not open and not smashed then
        if PathInternal.openWindowForNPC(body, object) then
            clearOwnedPath(body, state)
            state.failed = true
            state.retryAt = now + 250
            logPassageEvent(
                snapshot,
                body,
                state,
                { kind = "window_open", object = object },
                "window_open",
                "opened"
            )
            logState(snapshot, "native_window_open", describeBody(body))
            return true, "native_window_open"
        end
        return Window.StartSmash(
            snapshot,
            body,
            state,
            object,
            now
        )
    end
    local canClimb = false
    if TraversalQuery.CanUseWindow then
        canClimb = TraversalQuery.CanUseWindow(object, body) == true
    elseif object.canClimbThrough then
        canClimb = object:canClimbThrough(body) == true
    end
    if canClimb then
        local destination = Window.ResolveDestination(body, object, passage)
        if destination
            and TraversalQuery.CanTraverseAt
            and not TraversalQuery.CanTraverseAt(
                destination:getX() + 0.5,
                destination:getY() + 0.5,
                destination:getZ()
            )
        then
            -- Do not enter a window animation when the opposite square is
            -- already occupied. The old flow started the climb, discovered
            -- the blocked landing only at completion, and immediately
            -- selected the same window again on the next retry.
            clearOwnedPath(body, state)
            state.failed = true
            state.retryAt = now + WINDOW_LANDING_BACKOFF_MS
            state.windowRetryObject = object
            state.windowRetryAt = state.retryAt
            logPassageEvent(
                snapshot,
                body,
                state,
                { kind = "window_climb", object = object,
                    toSquare = destination },
                "landing_blocked",
                "preflight"
            )
            logState(
                snapshot,
                "native_window_landing_wait",
                "backoff=" .. tostring(WINDOW_LANDING_BACKOFF_MS)
                    .. " " .. describeBody(body)
            )
            return true, "native_window_landing_wait"
        end
        -- Never hand an equipped managed IsoZombie to vanilla window state.
        -- The native state assumes player BodyDamage and was the source of
        -- the transient zombie animation/freeze and ClimbThroughWindowState
        -- failures seen during multiplayer traversal.
        return Window.StartClimb(
            snapshot,
            body,
            state,
            object,
            passage,
            now
        )
    end
    return false, nil
end

Passage.TryWindow = tryWindow
