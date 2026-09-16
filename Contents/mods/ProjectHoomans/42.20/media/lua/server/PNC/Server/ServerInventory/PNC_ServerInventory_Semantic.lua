-- Narrow semantic handoff adapter for authoritative NPC-to-player transfers.
--
-- Semantic providers may decide *which* item is wanted, but they must not
-- mutate inventories themselves. This adapter reuses the existing lease,
-- revision, native-item, rollback, and replication boundaries.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local Network = PNC.Network
local Inventory = PNC.Inventory
local checkRevision = Internal.checkRevision
local transferNPCToPlayer = Internal.transferNPCToPlayer

local function authorize(player, record, token)
    local authority = PNC.Conversation
        and PNC.Conversation.Authority
    local internal = authority and authority.Internal
    if not player or not record then return false, "npc_not_found" end
    if tostring(token or "") == "" then
        return false, "conversation_lease_required"
    end
    if not internal or type(internal.ValidateLease) ~= "function" then
        return false, "conversation_authority_unavailable"
    end
    return internal.ValidateLease(player, record, token)
end

function Service.SemanticTransferNPCToPlayer(player, record, args)
    args = type(args) == "table" and args or {}
    local authorized
    local reason
    local revisionOK
    local sinceRevision
    local revisionDetails
    local success
    if args.direction ~= "npc_to_player" then
        return false, "semantic_direction_invalid"
    end

    authorized, reason = authorize(
        player,
        record,
        args.conversationToken or args.token
    )
    if authorized ~= true then return false, reason end

    revisionOK, sinceRevision, revisionDetails = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        return false, sinceRevision, revisionDetails
    end

    args.playerContainer = args.playerContainer or "root"
    success, reason = transferNPCToPlayer(
        player, record, args, sinceRevision)
    return success == true, reason
end

return Service
