local Scene = PNC.ConversationScene
local Internal = Scene.Internal

local function activeParley(record, token)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local parley = runtime and runtime.conversationParley or nil
    if not lease or not parley
        or tostring(lease.token or "") ~= tostring(token or "")
        or tostring(parley.token or "") ~= tostring(token or "")
    then
        return nil, nil
    end
    return lease, parley
end

local function leaseMatchesPlayer(lease, player)
    if tostring(lease.playerUsername or "") ~= tostring(
        player and player.getUsername and player:getUsername() or ""
    ) then
        return false
    end
    return lease.playerOnlineID == nil
        or tostring(lease.playerOnlineID) == tostring(
            player and player.getOnlineID and player:getOnlineID() or ""
        )
end

local function reject(player, reason)
    Internal.SendCeasefireResult(player, false, reason)
    return false, reason
end

function Internal.HandleCeasefire(player, record, zombie, token)
    local lease
    local parley
    local factionID
    local key
    local ok
    local reason
    local entry
    lease, parley = activeParley(record, token)
    if not lease then return reject(player, "no_active_parley") end
    if not leaseMatchesPlayer(lease, player) then
        return reject(player, "lease_owner_mismatch")
    end
    factionID = PNC.Factions
        and PNC.Factions.GetOrganizationalFactionID
        and PNC.Factions.GetOrganizationalFactionID(record) or nil
    if not factionID or not PNC.Factions.PacifyForPlayer then
        return reject(player, "faction_unavailable")
    end
    key = Internal.PlayerKey(player, "conversation_ceasefire")
    if not key or key ~= parley.playerKey then
        return reject(player, "player_identity_unavailable")
    end
    ok, reason, entry = PNC.Factions.PacifyForPlayer(
        factionID,
        key,
        {
            worldAgeHours = Internal.WorldAgeHours(),
            durationHours = Scene.CEASEFIRE_HOURS,
            reason = "conversation_ceasefire",
            sourceNPCID = record.id,
        }
    )
    if ok then
        entry = entry or {}
        entry.factionID = factionID
        Internal.ApplyParley(record, zombie, "conversation_ceasefire")
    end
    Internal.SendCeasefireResult(player, ok, reason, entry)
    return ok, reason, entry
end
