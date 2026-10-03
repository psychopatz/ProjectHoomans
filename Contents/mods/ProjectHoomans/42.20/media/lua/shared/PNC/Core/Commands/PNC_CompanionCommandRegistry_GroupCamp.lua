-- Group-camp validation and shared provider seams.
-- Recipient admission, details, and camp application are separate providers.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
local Registry = PNC.Registry
if type(Commands) ~= "table" then return false end

Commands.Internal = Commands.Internal or {}

local function copyTable(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, child in pairs(value) do output[key] = child end
    return output
end

require "PNC/Core/Commands/PNC_CompanionCommandRegistry_GroupCampDetails"
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_GroupCampRecipients"

local function campValidationOrigin(record, player)
    local zombie = record and record.id and Registry.GetLiveZombie(record.id)
        or nil
    -- Player-issued "here" commands use the same origin as the client hint
    -- search. The companion's live body is passed separately for world
    -- validation, but must not move the requested camp location.
    return player or record, zombie
end

local function validateCampSite(record, player, commandContext)
    local resolver = PNC.Semantics
        and PNC.Semantics.CampSiteResolver or nil
    local hint = commandContext and commandContext.campSiteHint
    local origin
    local body
    local validationContext
    local target
    if not resolver or type(resolver.ValidateClientSite) ~= "function" then
        return nil, "camp_site_validation_unavailable"
    end
    if type(hint) ~= "table" then return nil, "camp_site_hint_required" end
    origin, body = campValidationOrigin(record, player)
    validationContext = {
        selectionOrigin = origin,
        origin = origin,
        body = body,
        record = record,
        player = player,
        npcID = record and record.id or nil,
        requestID = commandContext and commandContext.requestID or nil,
    }
    target = {
        kind = "camp_site",
        scope = "here",
        clientHint = hint,
        -- commandContext.radius is the companion-command eligibility radius
        -- (normally 20), not the camp-site discovery radius. Keep site
        -- validation aligned with the client loaded-cell search limit.
        radius = tonumber(commandContext and commandContext.campSiteRadius)
            or tonumber(resolver.DEFAULT_RADIUS) or 32,
    }
    return resolver.ValidateClientSite(target, validationContext)
end

Commands.Internal.CopyTable = copyTable
Commands.Internal.ValidateCampSite = validateCampSite

return true
