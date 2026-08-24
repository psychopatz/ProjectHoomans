if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerCharacters = PNC.PlayerCharacters or {}
PNC.PlayerContext = PNC.PlayerContext or {}
PNC.PlayerCharacters.Internal = PNC.PlayerCharacters.Internal or {}

local PlayerCharacters = PNC.PlayerCharacters
local Internal = PlayerCharacters.Internal
local Constants = PNC.PlayerCharacterConstants
local Types = PNC.PlayerCharacterTypes
local EntityRef = PNC.EntityRef
local Core = PNC.Core


PlayerCharacters.Registry = PlayerCharacters.Registry
    or Types.NewRegistry()
PlayerCharacters.Loaded = PlayerCharacters.Loaded == true
PlayerCharacters.Dirty = PlayerCharacters.Dirty == true
PlayerCharacters.RuntimeByPlayer = PlayerCharacters.RuntimeByPlayer
    or setmetatable({}, { __mode = "k" })
PlayerCharacters.RuntimeByUUID =
    PlayerCharacters.RuntimeByUUID or {}
PlayerCharacters.RuntimeContexts = PlayerCharacters.RuntimeContexts
    or setmetatable({}, { __mode = "k" })
PlayerCharacters.UUIDGenerator =
    PlayerCharacters.UUIDGenerator or function()
        return Core.GenerateID(Constants.UUID_PREFIX)
    end

local function worldAgeHours(value)
    value = tonumber(value)
    if value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
    then
        return math.max(0, value)
    end
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function call(player, methodName)
    local method = player and player[methodName] or nil
    local ok
    local value
    if not method then
        return nil
    end
    ok, value = pcall(method, player)
    if not ok then
        return nil
    end
    return value
end

local function deepEqual(left, right, seen)
    local key
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    if seen[left] == right then
        return true
    end
    seen[left] = right
    for key, _ in pairs(left) do
        if not deepEqual(left[key], right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function copy(value)
    if Core and Core.DeepCopy then
        return Core.DeepCopy(value)
    end
    local output = {}
    local key
    local item
    for key, item in pairs(value or {}) do
        output[key] = type(item) == "table"
            and copy(item) or item
    end
    return output
end

local function assignTable(target, source)
    local key
    for key, _ in pairs(target) do
        target[key] = nil
    end
    for key, value in pairs(source) do
        target[key] = type(value) == "table"
            and copy(value) or value
    end
end

local function logIdentity(fields)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogIdentity
    then
        PNC.PlayerCharacterDebug.LogIdentity(fields)
    end
end

local function presentationIdentityFor(player)
    return Types.NormalizeAccountIdentity(call(player, "getUsername"))
end

local function isSinglePlayerAuthority()
    local server = isServer and isServer() == true
    local client = isClient and isClient() == true
    return not server and not client
end

local function accountKeyFor(player)
    local existing = PlayerCharacters.RuntimeContexts[player]
    if existing and existing.accountKey then return existing.accountKey end
    if isSinglePlayerAuthority() then
        local slot = tonumber(call(player, "getPlayerNum"))
        if slot == nil then slot = tonumber(call(player, "getPlayerIndex")) end
        if slot ~= nil then
            return "sp_slot_" .. tostring(math.max(0, math.floor(slot)))
        end
        -- Compatibility for non-engine test doubles. Real IsoPlayer objects
        -- always expose their local player slot.
    end
    return presentationIdentityFor(player)
end

local function onlineIDFor(player)
    return call(player, "getOnlineID")
end

local function playerModData(player)
    local data = call(player, "getModData")
    return type(data) == "table" and data or data
end

local function informationalFields(player)
    local descriptor = call(player, "getDescriptor")
    local output = {
        displayName = call(player, "getDisplayName"),
        lastKnownX = call(player, "getX"),
        lastKnownY = call(player, "getY"),
        lastKnownZ = call(player, "getZ"),
    }
    if descriptor then
        output.forename = call(descriptor, "getForename")
        output.surname = call(descriptor, "getSurname")
    end
    return Types.NewCharacterRecord({
        uuid = "char_information",
        accountIdentity = "information",
        forename = output.forename,
        surname = output.surname,
        displayName = output.displayName,
        lastKnownX = output.lastKnownX,
        lastKnownY = output.lastKnownY,
        lastKnownZ = output.lastKnownZ,
    })
end


Internal.worldAgeHours = worldAgeHours
Internal.call = call
Internal.deepEqual = deepEqual
Internal.copy = copy
Internal.assignTable = assignTable
Internal.logIdentity = logIdentity
Internal.presentationIdentityFor = presentationIdentityFor
Internal.isSinglePlayerAuthority = isSinglePlayerAuthority
Internal.accountKeyFor = accountKeyFor
Internal.onlineIDFor = onlineIDFor
Internal.playerModData = playerModData
Internal.informationalFields = informationalFields

return PlayerCharacters
