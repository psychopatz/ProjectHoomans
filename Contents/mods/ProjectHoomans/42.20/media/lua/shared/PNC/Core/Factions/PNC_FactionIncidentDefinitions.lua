-- Server-owned, data-only faction incident balance.

PNC = PNC or {}
PNC.FactionIncidentDefinitions =
    PNC.FactionIncidentDefinitions or {}

local Definitions = PNC.FactionIncidentDefinitions

local VALUES = {
    member_attacked_minor = {
        standing = -8, trust = -10, fear = 2, grievance = 10,
        severity = 0.25,
        tags = { violence = true, assault = true },
    },
    member_attacked_severe = {
        standing = -18, trust = -20, fear = 5, grievance = 25,
        severity = 0.65,
        tags = { violence = true, assault = true, severe = true },
    },
    member_killed = {
        standing = -35, trust = -30, fear = 10, grievance = 45,
        severity = 1,
        tags = { violence = true, killing = true },
    },
    member_rescued = {
        standing = 10, trust = 8, fear = 0, grievance = -4,
        severity = 0.45,
        tags = { aid = true, rescue = true },
    },
    member_protected = {
        standing = 5, trust = 4, fear = 0, grievance = -2,
        severity = 0.25,
        tags = { aid = true, protection = true },
    },
    members_fought_together = {
        standing = 2, trust = 3, fear = 0, grievance = 0,
        severity = 0.15,
        tags = { cooperation = true, combat = true },
    },
    member_abandoned = {
        standing = -8, trust = -12, fear = 0, grievance = 10,
        severity = 0.40,
        tags = { abandonment = true, betrayal = true },
    },
    personal_grievance_report = {
        standing = -5, trust = -5, fear = 0, grievance = 8,
        severity = 0.20,
        tags = { grievance_report = true },
    },
    war_declared = {
        standing = 0, trust = 0, fear = 0, grievance = 0,
        severity = 1, audit = true, preserve = true,
        tags = { treaty = true, war = true },
    },
    peace_made = {
        standing = 0, trust = 0, fear = 0, grievance = 0,
        severity = 1, audit = true, preserve = true,
        tags = { treaty = true, peace = true },
    },
    truce_started = {
        standing = 0, trust = 0, fear = 0, grievance = 0,
        severity = 1, audit = true, preserve = true,
        tags = { treaty = true, truce = true },
    },
    alliance_formed = {
        standing = 0, trust = 0, fear = 0, grievance = 0,
        severity = 1, audit = true, preserve = true,
        tags = { treaty = true, alliance = true },
    },
    alliance_broken = {
        standing = 0, trust = -15, fear = 0, grievance = 10,
        severity = 0.75, audit = true, preserve = true,
        tags = { treaty = true, alliance = true, broken = true },
    },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copy(item)
    end
    return output
end

function Definitions.Get(incidentType)
    local definition = VALUES[tostring(incidentType or "")]
    return definition and copy(definition) or nil
end

function Definitions.Exists(incidentType)
    return VALUES[tostring(incidentType or "")] ~= nil
end

return Definitions
