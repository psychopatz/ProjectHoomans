-- Shared companion-target and camp-site context resolution.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local ClientState = PNC.Network.ClientState

require "PNC/Networking/ClientActions/PNC_ClientActions_CompanionDiagnostics"

local function commandRecord(npcId, context)
    local record = npcId and Registry and Registry.Get
        and Registry.Get(npcId) or nil
    if not record and npcId and ClientState and ClientState.snapshots then
        record = ClientState.snapshots[tostring(npcId)]
    end
    if record then return record end
    if type(context) == "table" then
        return context.record or context.source or context.snapshot
            or context.target and context.target.source
            or context.target
    end
    return nil
end

local function isCampEmoteContext(context)
    return type(context) == "table"
        and tostring(context.origin or "") == "companion_emote"
end

local function isCampRejectionReason(reason)
    reason = tostring(reason or "")
    return string.sub(reason, 1, 5) == "camp_"
        or string.sub(reason, 1, 9) == "campfire_"
end

local function showCampRejection(player, npcId, reason, context, record)
    local presentation = PNC.CompanionCommandPresentation
    local actor
    local presentationContext
    if not isCampRejectionReason(reason) then
        return false
    end
    if not presentation then
        pcall(require, "PNC/Commands/PNC_CompanionCommandPresentation")
        presentation = PNC.CompanionCommandPresentation
    end
    if not presentation or not presentation.ShowCommandRejection then
        return false
    end
    actor = npcId and Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(npcId) or nil
    presentationContext = type(context) == "table" and context or {}
    presentationContext.target = presentationContext.target or record
    presentationContext.playerActor = player
    presentation.ShowCommandRejection(
        player,
        actor,
        "camp",
        reason,
        presentationContext
    )
    return true
end

local function clientCampSiteHints()
    local semantics = PNC.Semantics
    local hints = semantics and semantics.ClientCampSiteHints or nil
    if hints and type(hints.Resolve) == "function" then return hints end
    pcall(require, "PNC/Semantics/PNC_SemanticCampSiteHints")
    semantics = PNC.Semantics
    hints = semantics and semantics.ClientCampSiteHints or nil
    return hints
end

local function findLocalCampSiteHint(player, npcId, context)
    local hints = clientCampSiteHints()
    local record = commandRecord(npcId, context)
    -- "Here" is the player's requested location. The companion may still be
    -- several tiles away and is expected to travel to the selected room or
    -- campfire after the order is accepted.
    local origin = player
    local body
    local searchContext = {}
    local hint
    local reason
    if type(context) == "table"
        and type(context.campSiteHint) == "table"
    then
        return context.campSiteHint
    end
    if npcId ~= nil and record and Registry
        and type(Registry.GetLiveZombie) == "function"
    then
        body = Registry.GetLiveZombie(record.id or npcId)
    end
    if not hints or type(hints.Resolve) ~= "function" then
        return nil, "camp_site_discovery_unavailable"
    end
    if type(context) == "table" then
        for key, value in pairs(context) do searchContext[key] = value end
    end
    searchContext.player = player
    searchContext.selectionOrigin = origin
    searchContext.worldOrigin = origin
    searchContext.record = record
    searchContext.body = body
    searchContext.npcID = npcId
    hint, reason = hints.Resolve({
        kind = "camp_site",
        scope = "here",
        radius = tonumber(hints.MAX_RADIUS) or 32,
    }, searchContext)
    if hint then return hint end
    -- Detailed observer failures are useful for diagnostics, but the command
    -- contract exposes one stable local-rejection reason to the UI and LLM.
    return nil, "camp_no_visible_site"
end

local function rejectUnsafeCampLocally(player, npcId, scope, context)
    local commands = PNC.CompanionCommands
    local record = commandRecord(npcId, context)
    local radius = tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
    local reason
    local hint
    if not commands then return false end
    if npcId ~= nil then
        if not record then return false end
        if commands.CanPlayerCommand
            and commands.CanPlayerCommand(record, player, radius) ~= true
        then
            return false
        end
        hint, reason = findLocalCampSiteHint(player, npcId, context)
        if hint then return false, nil, hint end
        if not isCampEmoteContext(context) then
            showCampRejection(
                player, npcId, reason or "camp_no_visible_site",
                context, record)
        end
        return true, reason or "camp_no_visible_site"
    end
    if string.lower(tostring(scope or "")) ~= "group"
    then
        return false
    end
    hint, reason = findLocalCampSiteHint(player, nil, context)
    if hint then return false, nil, hint end
    if not isCampEmoteContext(context) then
        showCampRejection(
            player, nil, reason or "camp_no_visible_site", context, nil)
    end
    return true, reason or "camp_no_visible_site"
end

-- Nearby discovery is intentionally client-owned: the client can only see
-- loaded candidates, while the server remains the final authority.  Send
-- only stable NPC ids across that boundary; never forward the client-side
-- snapshots, positions, or semantic observations as authoritative data.
local MAX_GROUP_TARGET_IDS = 32

local function groupTargetIDs(scope, context)
    local values
    local output
    local seen
    local candidate
    local id
    local maximum
    if string.lower(tostring(scope or "")) ~= "group"
        or type(context) ~= "table"
        or type(context.targets) ~= "table"
    then
        return nil
    end
    values = context.targets
    output = {}
    seen = {}
    maximum = math.min(#values, MAX_GROUP_TARGET_IDS)
    for index = 1, maximum do
        candidate = values[index]
        id = type(candidate) == "table" and candidate.id or candidate
        if id ~= nil and tostring(id) ~= "" then
            id = tostring(id)
            if not seen[id] then
                seen[id] = true
                output[#output + 1] = id
            end
        end
    end
    return output
end

Internal.CommandRecord = commandRecord
Internal.IsCampEmoteContext = isCampEmoteContext
Internal.IsCampRejectionReason = isCampRejectionReason
Internal.ShowCampRejection = showCampRejection
Internal.RejectUnsafeCampLocally = rejectUnsafeCampLocally
Internal.GroupTargetIDs = groupTargetIDs

return Internal

