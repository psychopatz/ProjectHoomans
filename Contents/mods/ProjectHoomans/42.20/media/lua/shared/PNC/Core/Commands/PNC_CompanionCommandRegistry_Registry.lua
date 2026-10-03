-- Companion command registration and definition lookup.
-- Authority checks and order application remain in the parent entry module.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
if type(Commands) ~= "table" then return false end

Commands.Definitions = Commands.Definitions or {}
Commands.DefinitionOrder = Commands.DefinitionOrder or {}
Commands.Groups = Commands.Groups or {}
Commands.GroupOrder = Commands.GroupOrder or {}

local function appendDefinitionID(commandID)
    local i
    for i = 1, #Commands.DefinitionOrder do
        if Commands.DefinitionOrder[i] == commandID then return end
    end
    Commands.DefinitionOrder[#Commands.DefinitionOrder + 1] = commandID
end

function Commands.RegisterGroup(definition)
    local groupID
    if type(definition) ~= "table" then return false end
    groupID = tostring(definition.id or "")
    if groupID == "" then return false end
    definition.id = groupID
    Commands.Groups[groupID] = definition
    local i
    for i = 1, #Commands.GroupOrder do
        if Commands.GroupOrder[i] == groupID then return true end
    end
    Commands.GroupOrder[#Commands.GroupOrder + 1] = groupID
    return true
end

function Commands.GetGroup(groupID)
    return Commands.Groups[tostring(groupID or "")]
end

function Commands.ListGroups()
    local output = {}
    local i
    local definition
    for i = 1, #Commands.GroupOrder do
        definition = Commands.Groups[Commands.GroupOrder[i]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

function Commands.Register(definition)
    local commandID
    if type(definition) ~= "table" then return false end
    commandID = tostring(definition.id or "")
    if commandID == "" or (
        type(definition.buildOrder) ~= "function"
        and definition.attackType == nil
        and type(definition.apply) ~= "function"
        and definition.clientOnly ~= true
    ) then
        return false
    end
    definition.id = commandID
    Commands.Definitions[commandID] = definition
    appendDefinitionID(commandID)
    return true
end

function Commands.NormalizeAttackType(value)
    if PNC.Types and PNC.Types.NormalizeAttackType then
        return PNC.Types.NormalizeAttackType(value)
    end
    value = string.lower(tostring(value or "auto"))
    if value == "auto" or value == "melee"
        or value == "ranged" or value == "none"
    then
        return value
    end
    return "auto"
end

function Commands.GetCurrentAttackType(record)
    return Commands.NormalizeAttackType(record and record.attackType)
end

function Commands.IsCurrent(record, commandID)
    local definition = Commands.Get(commandID)
    if not definition or definition.attackType == nil then return false end
    return Commands.GetCurrentAttackType(record)
        == Commands.NormalizeAttackType(definition.attackType)
end

function Commands.GetAttackTypeDefinition(attackType)
    local normalized = Commands.NormalizeAttackType(attackType)
    local definitions = Commands.List()
    local i
    local definition
    for i = 1, #definitions do
        definition = definitions[i]
        if definition.attackType ~= nil
            and Commands.NormalizeAttackType(definition.attackType) == normalized
        then
            return definition
        end
    end
    return nil
end

function Commands.Get(commandID)
    return Commands.Definitions[tostring(commandID or "")]
end

-- Command-specific eligibility stays at the player-command authority
-- boundary. Faction behavior and other server-owned order producers call
-- OrderSystem directly and intentionally do not inherit player restrictions.
function Commands.CanApply(record, player, commandID)
    local definition = Commands.Get(commandID)
    local allowed
    local reason
    if not definition then return false, "unknown_command" end
    if type(definition.canApply) ~= "function" then
        return true, "commandable"
    end
    allowed, reason = definition.canApply(record, player)
    if allowed ~= true then
        return false, reason or "command_rejected"
    end
    return true, reason or "commandable"
end

function Commands.List()
    local output = {}
    local i
    local definition
    for i = 1, #Commands.DefinitionOrder do
        definition = Commands.Definitions[Commands.DefinitionOrder[i]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

return true
