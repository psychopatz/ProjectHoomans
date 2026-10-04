local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local ActorControl = PNC.ActorControl
local NATIVE_PASSAGE_STATES = Internal.NATIVE_PASSAGE_STATES
function LiveBodyControl.GetActionContextStateName(zombie)
    local value
    if not zombie then
        return ""
    end
    if zombie.getCurrentActionContextStateName then
        value = zombie:getCurrentActionContextStateName()
    elseif zombie.getActionStateName then
        value = zombie:getActionStateName()
    end
    return string.lower(tostring(value or ""))
end

function LiveBodyControl.IsNativePassageState(actionState)
    return NATIVE_PASSAGE_STATES[
        string.lower(tostring(actionState or ""))
    ] == true
end

function LiveBodyControl.IsTraversalBumpType(bumpType)
    local value = string.lower(tostring(bumpType or ""))
    return string.find(value, "climbwindow", 1, true) ~= nil
        or string.find(value, "climbfence", 1, true) ~= nil
        or string.find(value, "climbwall", 1, true) ~= nil
end

local function passageObjectAtFeeler(zombie)
    local current
    local feeler
    if not zombie then return nil end
    current = zombie.getCurrentSquare and zombie:getCurrentSquare()
        or zombie.getSquare and zombie:getSquare() or nil
    feeler = zombie.getFeelerTile and zombie.getFeelersize
        and zombie:getFeelerTile(zombie:getFeelersize()) or nil
    if not current or not feeler
        or not current.testCollideSpecialObjects
    then
        return nil, current, feeler
    end
    return current:testCollideSpecialObjects(feeler), current, feeler
end

-- IsoZombie.tryThump() runs after OnZombieUpdate and independently scans the
-- feeler tile. Managed IsoZombie carriers cannot safely enter that window
-- state because the Java path drops player-only BodyDamage fields. Detect the
-- same special object before the engine reaches tryThump and hand the frame
-- back to PNC's path/traversal retry lane.
function LiveBodyControl.GetVanillaPassageAhead(zombie)
    local object
    local current
    local feeler
    local kind
    local query
    local fence
    local fenceTall
    object, current, feeler = passageObjectAtFeeler(zombie)
    if object and instanceof then
        if instanceof(object, "IsoWindow") then
            kind = "window"
        elseif instanceof(object, "IsoWindowFrame") then
            kind = "window_frame"
        elseif instanceof(object, "IsoThumpable") then
            kind = "thumpable"
        elseif instanceof(object, "IsoDoor") then
            kind = "door"
        end
        if kind then return object, kind end
    end
    -- Fences are not consistently returned by
    -- IsoGridSquare:testCollideSpecialObjects. Use the same edge query as
    -- the movement traversal planner so a managed carrier cannot fall
    -- through IsoZombie.tryThump into the player-only vault state.
    query = PNC.TraversalQuery
    if query and query.GetFenceBetween and current and feeler then
        local ok
        ok, fence, fenceTall = pcall(
            query.GetFenceBetween,
            current,
            feeler
        )
        if ok and fence then
            return fence, "fence", fenceTall == true
        end
    end
    return nil, nil
end

local function passageMovementState(actionState)
    return actionState == "pathfind"
        or actionState == "walktoward"
        or actionState == "walktowardnetwork"
        or actionState == "lunge"
        or actionState == "lungenetwork"
end

-- Managed bodies must open the door the engine reports at the feeler tile
-- themselves: the engine's door toggle is player-driven in Build 42, so a body
-- that only cancels its vanilla movement re-requests the same blocked path
-- forever (NPCs stalled at closed doors). Attempts are rate limited per body so
-- a door that refuses to open (locked, barricaded) cannot spam the engine.
local PASSAGE_DOOR_ATTEMPT_AT = setmetatable({}, { __mode = "k" })
local PASSAGE_DOOR_OPEN_LOGGED = setmetatable({}, { __mode = "k" })
local PASSAGE_DOOR_ATTEMPT_MS = 250

local function passageObjectBool(object, name)
    local method = object and object[name] or nil
    local ok
    local value
    if type(method) ~= "function" then return false end
    ok, value = pcall(method, object)
    return ok and value == true
end

--[[
    A hoppable, not-tall door or fence is vaulted by vanilla through
    IsoZombie.tryThump() -> IsoGameCharacter.climbOverFence() ->
    ClimbOverFenceState, whose shouldFallAfterVaultOver() dereferences
    BodyDamage that an IsoZombie does not have. Entering that player-only state
    throws a NullPointerException on every vault attempt, on client and server
    alike. PNC refuses the state for managed carriers, so the vanilla vault has
    to be prevented before tryThump() runs.
]]
function LiveBodyControl.IsHoppableLowDoor(object)
    local ok
    local hoppable
    local tall
    if not object or not object.isHoppable then
        return false
    end
    ok, hoppable = pcall(object.isHoppable, object)
    if not ok or hoppable ~= true then
        return false
    end
    if object.isTallHoppable then
        ok, tall = pcall(object.isTallHoppable, object)
        if ok and tall == true then
            return false
        end
    end
    return true
end

local function isClosedPassageDoor(object)
    if not object or not instanceof then return false end
    if instanceof(object, "IsoDoor") then
        return not passageObjectBool(object, "IsOpen")
            and not passageObjectBool(object, "isOpen")
    end
    if instanceof(object, "IsoThumpable")
        and object.isDoor
        and object:isDoor() == true
    then
        return not passageObjectBool(object, "IsOpen")
    end
    return false
end

local function describePassageSquare(object)
    local square = object and object.getSquare and object:getSquare() or nil
    if not square then return "unknown" end
    return tostring(square:getX()) .. "," .. tostring(square:getY())
        .. "," .. tostring(square:getZ())
end

local function openPassageDoorAhead(zombie, object, now)
    local pathService = PNC.PathService and PNC.PathService.Internal or nil
    local openDoorForNPC = pathService and pathService.openDoorForNPC or nil
    local last
    local square
    if type(openDoorForNPC) ~= "function" then return false end
    if not isClosedPassageDoor(object) then return false end
    now = tonumber(now) or 0
    last = tonumber(PASSAGE_DOOR_ATTEMPT_AT[zombie])
    if last and now > 0 and now - last < PASSAGE_DOOR_ATTEMPT_MS then
        return false
    end
    PASSAGE_DOOR_ATTEMPT_AT[zombie] = now
    if openDoorForNPC(zombie, object) ~= true then return false end
    PASSAGE_DOOR_ATTEMPT_AT[zombie] = nil
    square = object.getSquare and object:getSquare() or nil
    if square and not PASSAGE_DOOR_OPEN_LOGGED[square]
        and PNC.Core and PNC.Core.LogWarn
    then
        PASSAGE_DOOR_OPEN_LOGGED[square] = true
        PNC.Core.LogWarn(
            "[PNC][PATH] vanilla_passage_door_opened square="
                .. describePassageSquare(object)
        )
    end
    return true
end

--[[
    Heavy hand items on a climbing zombie.

    Vanilla IsoGameCharacter.climbThroughWindow() calls dropHeavyItems(), and in
    Build 42 that multiplayer branch sends PlayerDropHeldItems plus Equip, whose
    setData casts the character to IsoPlayer. Any IsoZombie that vanilla makes
    climb a window - open windows are climbable for zombies - therefore throws a
    ClassCastException, logs "Packet send failed" and leaves the shell's hand
    slot desynchronized from the server.

    Ordinary zombies are already cleared by the client aggro controller
    (PNC_ClientZombieAggroController_BodyEffects.ClearHeldItems). Managed NPC
    shells re-acquire equipment whenever they are (re)materialized, so the same
    clearance has to run for them right before the vanilla update reaches
    IsoZombie.tryThump(). Only heavy items move: weapons stay in hand so NPC
    visuals and animations are unaffected, and an item that cannot be stored is
    left where it is rather than dropped or lost.
]]

Internal.passageMovementState = passageMovementState
Internal.isClosedPassageDoor = isClosedPassageDoor
Internal.openPassageDoorAhead = openPassageDoorAhead
