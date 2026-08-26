-- Shared social-event dependencies, safety checks, and lookup.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
PNC.SocialEvents.Internal = PNC.SocialEvents.Internal or {}

local SocialEvents = PNC.SocialEvents
local Core = PNC.Core
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local RelationshipTypes = PNC.RelationshipTypes
local Relationships = PNC.Relationships
local Definitions = PNC.SocialEventDefinitions
local ProfileTypes = PNC.SocialProfileTypes
local ProfileMath = PNC.SocialProfileMath
local Conduct = PNC.Conduct
local ConductDefinitions = PNC.ConductDefinitions

local function personalRelationshipQueries()
    local personal = Relationships and Relationships.Personal
    return personal and personal.Queries or Relationships
end

local function personalRelationshipCommands()
    local personal = Relationships and Relationships.Personal
    return personal and personal.Commands or Relationships
end

local FACTION_INCIDENT_BY_SOCIAL_EVENT = {
    saved_from_incapacitation = "member_rescued",
    protected_from_attacker = "member_protected",
    survived_combat_together = "members_fought_together",
    abandoned_in_combat = "member_abandoned",
}

local function factionIDForEntityKey(key)
    local parsed = EntityRef.Parse(key)
    if not parsed or not PNC.Factions then return nil end
    if parsed.kind == "npc" then
        local record = Registry and Registry.Get
            and Registry.Get(parsed.npcID) or nil
        return record
            and PNC.Factions.GetFactionID(record)
            or nil
    end
    if parsed.kind == "player" then
        local faction =
            PNC.Factions
                .GetDiplomacyFactionForPlayerKey(key)
        return faction and faction.id or nil
    end
    return nil
end

local function result(ok, reason, fields)
    local output = fields or {}
    output.ok = ok == true
    if reason then
        output.reason = reason
    end
    return output
end

local function finiteNumber(value)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function validString(value)
    return type(value) == "string"
        and value ~= ""
        and #value <= 512
        and not string.find(value, "%c")
end

local function isSafe(value, seen, depth, budget)
    local valueType = type(value)
    local key
    local item
    if valueType == "nil"
        or valueType == "string"
        or valueType == "boolean"
    then
        return true
    end
    if valueType == "number" then
        return finiteNumber(value) ~= nil
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return false
    end
    depth = depth or 0
    if depth >= 8 then
        return false
    end
    seen = seen or {}
    budget = budget or { count = 0 }
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > 128
            or (type(key) ~= "string" and type(key) ~= "number")
            or not isSafe(key, seen, depth + 1, budget)
            or not isSafe(item, seen, depth + 1, budget)
        then
            seen[value] = nil
            return false
        end
    end
    seen[value] = nil
    return true
end

local function copySafe(value)
    local output
    local key
    local item
    if type(value) ~= "table" then
        return value
    end
    output = {}
    for key, item in pairs(value) do
        output[key] = copySafe(item)
    end
    return output
end

local function enabled()
    local configured = not PNC.Config
        or not PNC.Config.Relationships
        or PNC.Config.Relationships.EnableSocialEvents ~= false
    if PNC.Sandbox and PNC.Sandbox.GetBoolean then
        return PNC.Sandbox.GetBoolean(
            "EnableSocialEvents",
            configured
        )
    end
    return configured
end

local function isAuthority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function SocialEvents.GetDefinition(eventType)
    local definition = type(eventType) == "string"
        and Definitions[eventType] or nil
    return definition and copySafe(definition) or nil
end

local Internal = SocialEvents.Internal
Internal.PersonalRelationshipQueries = personalRelationshipQueries
Internal.PersonalRelationshipCommands = personalRelationshipCommands
Internal.FactionIncidentBySocialEvent = FACTION_INCIDENT_BY_SOCIAL_EVENT
Internal.FactionIDForEntityKey = factionIDForEntityKey
Internal.Result = result
Internal.FiniteNumber = finiteNumber
Internal.ValidString = validString
Internal.IsSafe = isSafe
Internal.CopySafe = copySafe
Internal.Enabled = enabled
Internal.IsAuthority = isAuthority

return Internal
