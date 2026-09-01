if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


local setJobPermission = Internal.setJobPermission
local cancelSpecialOrder = Internal.cancelSpecialOrder
local colonistHomeAction = Internal.colonistHomeAction
local colonistFollowAction = Internal.colonistFollowAction

function Internal.handleStorageColonistAction(player, args, action)
    local ok
    local reason
    local details
    local storage
    local record
    if action == "storage_player_deposit" then
        ok, reason, details, storage =
            PNC.ColonyStorageService.RequestPlayerDeposit(player, args)
    elseif action == "storage_player_withdraw" then
        ok, reason, details, storage =
            PNC.ColonyStorageService.RequestPlayerWithdrawal(player, args)
    elseif action == "storage_npc_deposit" then
        ok, reason, details, storage, record =
            PNC.ColonyStorageService.RequestNPCDeposit(player, args)
        if record and PNC.Network and PNC.Network.SendInventoryDelta then
            PNC.Network.SendInventoryDelta(
                player, record, tonumber(args.inventoryRevision) or 0)
        end
    elseif action == "storage_npc_deposit_all" then
        ok, reason, details, storage, record =
            PNC.ColonyStorageService.RequestNPCCourierDeposit(player, args)
        if record and PNC.Network and PNC.Network.SendCharacterPayload then
            PNC.Network.SendCharacterPayload(player, record)
        end
    elseif action == "storage_debug" then
        ok, reason, storage, details =
            PNC.ColonyStorageService.DebugAction(player, args)
        if ok and details and details.npcId and PNC.Registry
            and PNC.Registry.Get and PNC.Network
            and PNC.Network.SendCharacterPayload
        then
            local record = PNC.Registry.Get(tostring(details.npcId))
            if record then
                PNC.Network.SendCharacterPayload(player, record)
            end
        end
    elseif action == "storage_upgrade" then
        ok, reason, storage, details =
            PNC.ColonyStorageService.Upgrade(player, args)
    elseif action == "job_permission_set" then
        ok, reason, details = setJobPermission(player, args)
    elseif action == "order_cancel" then
        ok, reason, details = cancelSpecialOrder(player, args)
    elseif action == "colonist_return_home" then
        ok, reason, details = colonistHomeAction(player, args, false)
    elseif action == "colonist_follow_player" then
        ok, reason, details = colonistFollowAction(player, args)
    elseif action == "colonist_recover" then
        ok, reason, details = colonistHomeAction(player, args, true)
    else
        return nil
    end
    return {
        ok = ok, reason = reason, details = details,
        storage = storage,
    }
end

return Management
