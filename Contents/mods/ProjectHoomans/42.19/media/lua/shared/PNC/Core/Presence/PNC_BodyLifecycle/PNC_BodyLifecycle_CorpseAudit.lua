-- Pending corpse finalization and bounded lightweight death-marker audits.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.pumpPendingCorpses()
    local cell = getCell and getCell() or nil
    local i
    local pending
    local record
    local square
    local found
    if not cell then
        return
    end
    for i = #Lifecycle.PendingCorpses, 1, -1 do
        pending = Lifecycle.PendingCorpses[i]
        pending.attempts = (tonumber(pending.attempts) or 0) + 1
        record = Internal.registry() and Internal.registry().GetDeathMarker
            and Internal.registry().GetDeathMarker(pending.npcId)
            or Internal.registry() and Internal.registry().Get
                and Internal.registry().Get(pending.npcId) or nil
        square = cell:getGridSquare(pending.x, pending.y, pending.z)
        found = nil
        Internal.forEachCorpse(square, function(corpse)
            local modData = corpse.getModData and corpse:getModData() or nil
            local markerId = modData and (
                modData.PNC_DeathMarkerID or modData.PNC_UUID
            ) or nil
            if not found and markerId
                and tostring(markerId) == tostring(pending.npcId)
            then
                found = corpse
            end
        end)
        if found and record then
            if Internal.ensureCorpseIdentityCard then
                Internal.ensureCorpseIdentityCard(record, found)
            end
            Internal.applyCorpseWornItems(found, pending.wornEntries)
            Internal.stampCorpse(record, found, pending.token)
            Internal.transmitCorpseState(found)
            table.remove(Lifecycle.PendingCorpses, i)
        elseif pending.attempts >= 8 then
            if record then
                local state = Internal.registry().GetDeathMarkerRuntime
                    and Internal.registry().GetDeathMarkerRuntime(record.id)
                    or Internal.ensureRuntime(record)
                state.corpseState = "missing"
                if record.runtime then
                    Internal.mark(record, "corpse", "missing",
                        "corpse_finalize_timeout", "corpse_not_found")
                end
            end
            table.remove(Lifecycle.PendingCorpses, i)
        end
    end
end

function Internal.auditCorpseRecord(record)
    local cell = getCell and getCell() or nil
    local square
    local accepted
    local token
    local state
    local now
    local markerId
    local identityCardCreated = false
    if not cell or not record then
        return
    end
    state = Internal.registry() and Internal.registry().GetDeathMarkerRuntime
        and Internal.registry().GetDeathMarkerRuntime(record.id)
        or Internal.ensureRuntime(record)
    now = Core.Now()
    square = cell:getGridSquare(
        math.floor(tonumber(record.x) or 0),
        math.floor(tonumber(record.y) or 0),
        math.floor(tonumber(record.z) or 0)
    )
    if not square then
        state.corpseState = "unloaded"
        return
    end
    token = record.corpseToken
        or record.corpse and record.corpse.token
    token = token and tostring(token) or nil
    Internal.forEachCorpse(square, function(corpse)
        local modData = corpse.getModData and corpse:getModData() or nil
        local corpseId = modData
            and (modData.PNC_DeathMarkerID or modData.PNC_UUID) or nil
        local corpseToken = modData and modData.PNC_CorpseToken and tostring(modData.PNC_CorpseToken) or nil
        corpseId = corpseId and tostring(corpseId) or nil
        if corpseId == tostring(record.id)
            and (not token or not corpseToken or corpseToken == token)
        then
            if not token then
                token = corpseToken or Core.GenerateID("corpse")
                record.corpseToken = token
            end
            if not accepted then
                accepted = corpse
                markerId = modData and modData.PNC_DeathMarkerID or nil
                if tostring(markerId or "") ~= tostring(record.id) then
                    Internal.stampCorpse(record, corpse, token)
                end
            end
        end
    end)
    if accepted and Internal.ensureCorpseIdentityCard then
        local _, created = Internal.ensureCorpseIdentityCard(record, accepted)
        identityCardCreated = created == true
    end
    if accepted and Lifecycle.IsReanimationDue
        and Lifecycle.IsReanimationDue(record)
        and Lifecycle.SpawnReanimatedZombie
    then
        local spawned = Lifecycle.SpawnReanimatedZombie(record, accepted)
        if spawned then return end
        if identityCardCreated then
            Internal.transmitCorpseState(accepted)
            identityCardCreated = false
        end
        if state.corpseState == "reanimation_retry" then return end
    end
    if accepted then
        if identityCardCreated then
            Internal.transmitCorpseState(accepted)
        end
        state.corpseState = "inert_loaded"
        state.missingSinceAt = 0
        return
    end
    state.corpseState = "missing"
    state.missingSinceAt = (tonumber(state.missingSinceAt) or 0) > 0
        and state.missingSinceAt or now
    if now - state.missingSinceAt
        >= (tonumber(Const.DEATH_MARKER_MISSING_GRACE_MS) or 5000)
        and Internal.registry() and Internal.registry().RemoveDeathMarker
    then
        Internal.registry().RemoveDeathMarker(record.id)
    end
end

function Internal.auditCorpseBatch(reg)
    local dead = {}
    local batchSize = math.max(1, tonumber(Const.CORPSE_AUDIT_BATCH_SIZE) or 12)
    local startAt
    local count
    local i
    if reg.ForEachDeathMarker then
        reg.ForEachDeathMarker(function(candidate)
            dead[#dead + 1] = candidate
        end)
    else
        reg.ForEach(function(candidate)
            if candidate.alive == false then dead[#dead + 1] = candidate end
        end)
    end
    if #dead <= 0 then
        Lifecycle.CorpseAuditCursor = 1
        return
    end
    table.sort(dead, function(a, b)
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    startAt = math.max(1, math.min(#dead, tonumber(Lifecycle.CorpseAuditCursor) or 1))
    count = math.min(batchSize, #dead)
    for i = 0, count - 1 do
        Internal.auditCorpseRecord(dead[((startAt - 1 + i) % #dead) + 1])
    end
    Lifecycle.CorpseAuditCursor = ((startAt - 1 + count) % #dead) + 1
end
