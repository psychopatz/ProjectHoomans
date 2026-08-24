if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local Network = PNC.Network
local canGift = Internal.canGift
local canManage = Internal.canManage
local notify = Internal.notify
local checkRevision = Internal.checkRevision
local transferPlayerToNPC = Internal.transferPlayerToNPC
local transferNPCToPlayer = Internal.transferNPCToPlayer
local applyGiftEffect = Internal.applyGiftEffect

function Service.Transfer(player, args)
    args = args or {}
    local record = args.id and Registry.Get(tostring(args.id)) or nil
    local giftMode = args.gift == true
    local allowed, reason
    if giftMode then
        allowed, reason = canGift(player, record, args)
    else
        allowed, reason = canManage(player, record)
    end
    if not allowed then return notify(player, false, reason, args) end
    local revisionOK, sinceRevision = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        return notify(player, false, sinceRevision, args)
    end
    local success
    local details
    if args.direction == "player_to_npc" then
        success, reason, details = transferPlayerToNPC(
            player, record, args, sinceRevision
        )
    elseif args.direction == "npc_to_player" then
        success, reason = transferNPCToPlayer(player, record, args, sinceRevision)
    else
        success, reason = false, "invalid_direction"
    end
    if success and giftMode then
        details = applyGiftEffect(player, record, args, details)
    end
    return notify(player, success, reason, args, details)
end
