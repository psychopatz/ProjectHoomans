--[[
    Client companion authority.

    `PNC.CompanionCommands.IsOwnedByPlayer` resolves ownership through the
    server's faction registry and player-character identity service. On a pure
    multiplayer client neither of those modules is loaded - both live under
    `server/` and return early through the RuntimeRole guard - so ownership
    always resolves to `factions_unavailable` and every client-side gate that
    asks "is this NPC mine?" silently answers no. That is why the companion
    command and inventory context options exist in single player and disappear
    in multiplayer.

    The server already resolves the same question for this player and
    replicates the answer:

      * the colony snapshot names the local player's faction (`snapshot.faction.id`),
        resolved per requesting player, and
      * every roster snapshot carries the NPC's own `factionID`.

    Comparing those two is the client-side equivalent of the faction membership
    test the server performs.

    This is an affordance gate only. It decides whether an option is offered.
    The server still re-validates ownership, liveness, distance, and authority
    on every command request, so a permissive client cannot grant itself
    anything.
]]

PNC = PNC or {}
PNC.ClientCompanionAuthority = PNC.ClientCompanionAuthority or {}

local Authority = PNC.ClientCompanionAuthority
local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Core = PNC.Core

local function clientState()
    return PNC.Network and PNC.Network.ClientState or nil
end

--[[
    The requesting player's faction id, as resolved and replicated by the
    server. `faction` is included in every colony snapshot and in the base
    bootstrap, so this is available as soon as the client has synced once.
]]
function Authority.LocalFactionID()
    local state = clientState()
    if not state then return nil end
    local snapshot = state.colonyManagement or state.colonyBase
    local faction = type(snapshot) == "table" and snapshot.faction or nil
    local id = type(faction) == "table" and faction.id or nil
    if id == nil or tostring(id) == "" then return nil end
    return tostring(id)
end

function Authority.HasReplicatedFaction(record)
    local factionID = type(record) == "table" and record.factionID or nil
    return factionID ~= nil and tostring(factionID) ~= ""
end

--[[
    Replicated ownership: the NPC belongs to the same faction the server
    reported for this player.
]]
function Authority.IsOwnedByReplication(record, player)
    if type(record) ~= "table" or not player then return false end
    local factionID = record.factionID
    local localFactionID = Authority.LocalFactionID()
    if factionID == nil or localFactionID == nil then return false end
    return tostring(factionID) == tostring(localFactionID)
end

--[[
    Ownership with a client-side fallback. The authoritative check is always
    attempted first so single player and a hosted authority keep using their own
    services rather than the replicated projection.
]]
function Authority.IsOwnedByPlayer(record, player)
    if Commands and type(Commands.IsOwnedByPlayer) == "function"
        and Commands.IsOwnedByPlayer(record, player) == true
    then
        return true
    end
    return Authority.IsOwnedByReplication(record, player)
end

function Authority.IsCompanion(record)
    if Commands and type(Commands.IsCompanion) == "function" then
        return Commands.IsCompanion(record) == true
    end
    return type(record) == "table" and record.alive ~= false
        and record.recruited == true
end

local function playerRadioActive(player)
    local deviceState = PsychopatzCore and PsychopatzCore.RadioDeviceState
        or nil
    local ok
    local device
    if not deviceState
        or type(deviceState.FindActivePlayerDevice) ~= "function"
        or not player
    then
        return false
    end
    ok, device = pcall(deviceState.FindActivePlayerDevice, player)
    return ok and device ~= nil
end

local function npcRadioActive(record)
    local radioGear = record and record.radioGear
    local equipment = PNC.Equipment
    local gear = equipment and equipment.RadioGear or nil
    if radioGear and radioGear.equipped == true then return true end
    return gear and type(gear.HasEquipped) == "function"
        and gear.HasEquipped(record) == true or false
end

local function livePosition(record)
    local registry = PNC.Registry
    local zombie = registry and type(registry.GetLiveZombie) == "function"
        and record and record.id and registry.GetLiveZombie(record.id) or nil
    if zombie and (not zombie.isDead or not zombie:isDead()) then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    return tonumber(record and record.x),
        tonumber(record and record.y),
        tonumber(record and record.z)
end

--[[
    Commandability. Tries the authoritative check first, then reproduces the
    same rules from replicated state: recruited, owned, live, same floor, within
    the command radius. Abstract records require the separate radio relay gate.
]]
function Authority.CanPlayerCommand(record, player, radius)
    if type(record) ~= "table" or not player then
        return false, "invalid_player"
    end
    if Commands and type(Commands.CanPlayerCommand) == "function"
        and Commands.CanPlayerCommand(
            record, player, radius) == true
    then
        return true, "commandable"
    end
    if not Authority.IsCompanion(record) then
        return false, "not_companion"
    end
    if not Authority.IsOwnedByPlayer(record, player) then
        return false, "not_owner"
    end
    local live = Const and Const.PRESENCE_LIVE or "live"
    if tostring(record.presenceState or live) ~= tostring(live) then
        return false, "not_live"
    end
    local x, y, z = livePosition(record)
    if x == nil or y == nil or z == nil then
        return false, "position_missing"
    end
    local playerZ = player.getZ and tonumber(player:getZ()) or nil
    if playerZ == nil
        or math.floor(playerZ) ~= math.floor(tonumber(z) or 0)
    then
        return false, "different_floor"
    end
    local defaultRadius = tonumber(Const and Const.COMPANION_COMMAND_RADIUS) or 20
    radius = math.max(1, math.min(defaultRadius,
        tonumber(radius) or defaultRadius))
    if not Core or type(Core.DistanceSq) ~= "function" then
        return false, "distance_unavailable"
    end
    local playerX = player.getX and tonumber(player:getX()) or nil
    local playerY = player.getY and tonumber(player:getY()) or nil
    if playerX == nil or playerY == nil then
        return false, "position_missing"
    end
    if Core.DistanceSq(playerX, playerY, tonumber(x), tonumber(y))
        > radius * radius
    then
        return false, "too_far"
    end
    return true, "commandable"
end

-- Client affordance for an abstract Follow Me command. Abstract records are
-- never directly commandable; Follow Me becomes available only when the same
-- two-way radio relay gate used by the server can be satisfied.
function Authority.CanRelayCommand(record, player, commandID)
    local gate = PNC.CommandRelayGate
    local definition = Commands and Commands.Get
        and Commands.Get(commandID) or nil
    if type(record) ~= "table" or not player then
        return false, "invalid_player"
    end
    if not gate or type(gate.Evaluate) ~= "function" then
        return false, "relay_unavailable"
    end
    if not definition or definition.radioRelay ~= true then
        return false, "relay_not_allowed"
    end
    return gate.Evaluate({
        companion = Authority.IsCompanion(record) == true,
        owned = Authority.IsOwnedByPlayer(record, player) == true,
        dead = record.alive == false,
        reachableDirectly = false,
        relayAllowed = true,
        playerRadio = playerRadioActive(player),
        npcRadio = npcRadioActive(record),
    })
end

return Authority
