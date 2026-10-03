-- Bounded recipient admission for group-camp commands.
-- This provider owns candidate filtering and deterministic ordering only.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Registry = PNC.Registry
if type(Commands) ~= "table" then return false end

Commands.Internal = Commands.Internal or {}

local function isOwnedCompanion(record, player)
    -- Group CAMP is a command to nearby owned companions, not a command
    -- restricted to records whose previous order happened to be FOLLOW.
    -- CAMP replaces that previous order, so checking it here made the
    -- server reject valid nearby companions that were guarding, roaming, or
    -- already finishing another compatible order.
    if not record or not player then
        return false
    end
    if not Commands.IsCompanion(record)
        or not Commands.IsOwnedByPlayer(record, player)
    then
        return false
    end
    -- Do not duplicate the ownership identity fields here. The authoritative
    -- verifier supports the current organization/character ownership model;
    -- requiring legacy order owner fields would reject valid companions even
    -- after the verifier has accepted them.
    return true
end

-- A logical LIVE record is not enough for this command. Group camp is a
-- nearby, materialized-world action: an abstract record has no body that can
-- walk to its assigned room and must remain outside this assignment pass.
local function materializedLive(record)
    local body
    if not record or record.alive == false
        or tostring(record.presenceState or Const.PRESENCE_LIVE)
            ~= tostring(Const.PRESENCE_LIVE)
    then
        return false
    end
    body = record.id and Registry
        and type(Registry.GetLiveZombie) == "function"
        and Registry.GetLiveZombie(record.id) or nil
    if not body
        or type(body.getX) ~= "function"
        or type(body.getY) ~= "function"
        or type(body.getZ) ~= "function"
    then
        return false
    end
    if body.isDead and body:isDead() then return false end
    return true, body
end

local function requestedTargetIDs(commandContext)
    local values = commandContext and commandContext.targetIDs
    local output
    local seen
    local value
    local id
    local maximum
    if type(values) ~= "table" then return nil, false end
    output = {}
    seen = {}
    maximum = math.min(#values, 32)
    for index = 1, maximum do
        value = values[index]
        id = type(value) == "table" and value.id or value
        if id ~= nil and tostring(id) ~= "" then
            id = tostring(id)
            if not seen[id] then
                seen[id] = true
                output[#output + 1] = id
            end
        end
    end
    return output, true
end

local function collectGroupCampRecipients(player, radius, commandContext)
    local requested
    local explicit
    local output = {}
    local seen = {}

    requested, explicit = requestedTargetIDs(commandContext)

    local function consider(record)
        local live
        local allowed
        local id = record and record.id and tostring(record.id) or ""
        if id == "" or seen[id] or not isOwnedCompanion(record, player)
        then
            return
        end
        allowed, live = materializedLive(record)
        if not allowed or not live then return end
        allowed = Commands.CanPlayerCommand(record, player, radius)
        if allowed ~= true then return end
        seen[id] = true
        output[#output + 1] = record
    end

    if explicit then
        for index = 1, #requested do
            consider(Registry.Get(requested[index]))
        end
    elseif Registry.ForEach then
        -- Compatibility for server-owned callers and older clients that do
        -- not yet send the nearby candidate list. The same live/radius gate
        -- still applies, so this fallback cannot revive distant or abstract
        -- group-camp behavior.
        Registry.ForEach(consider)
    end
    table.sort(output, function(left, right)
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return output, explicit
end

Commands.Internal.CollectGroupCampRecipients = collectGroupCampRecipients

return true
