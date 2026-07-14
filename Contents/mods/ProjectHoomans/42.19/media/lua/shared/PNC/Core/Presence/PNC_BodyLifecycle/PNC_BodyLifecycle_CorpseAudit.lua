-- Pending corpse finalization and bounded corpse-record audits.

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
        record = Internal.registry() and Internal.registry().Get and Internal.registry().Get(pending.npcId) or nil
        square = cell:getGridSquare(pending.x, pending.y, pending.z)
        found = nil
        Internal.forEachCorpse(square, function(corpse)
            local modData = corpse.getModData and corpse:getModData() or nil
            if not found and (not modData or not modData.PNC_UUID or tostring(modData.PNC_UUID) == pending.npcId) then
                found = corpse
            end
        end)
        if found and record then
            Internal.applyCorpseWornItems(found, pending.wornEntries)
            Internal.stampCorpse(record, found, pending.token)
            Internal.transmitCorpseState(found)
            table.remove(Lifecycle.PendingCorpses, i)
        elseif pending.attempts >= 8 then
            if record then
                Internal.ensureRuntime(record).corpseState = "missing"
                Internal.mark(record, "corpse", "missing", "corpse_finalize_timeout", "corpse_not_found")
            end
            table.remove(Lifecycle.PendingCorpses, i)
        end
    end
end

function Internal.auditCorpseRecord(record)
    local cell = getCell and getCell() or nil
    local descriptor = record and record.corpse or nil
    local square
    local accepted
    local token
    local state
    if not cell or not record or record.alive ~= false then
        return
    end
    state = Internal.ensureRuntime(record)
    if not descriptor then
        state.corpseState = "missing"
        return
    end
    square = cell:getGridSquare(
        math.floor(tonumber(descriptor.x) or tonumber(record.x) or 0),
        math.floor(tonumber(descriptor.y) or tonumber(record.y) or 0),
        math.floor(tonumber(descriptor.z) or tonumber(record.z) or 0)
    )
    if not square then
        state.corpseState = "unloaded"
        return
    end
    token = descriptor.token and tostring(descriptor.token) or nil
    Internal.forEachCorpse(square, function(corpse)
        local modData = corpse.getModData and corpse:getModData() or nil
        local corpseId = modData and modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
        local corpseToken = modData and modData.PNC_CorpseToken and tostring(modData.PNC_CorpseToken) or nil
        if corpseId == tostring(record.id) then
            if not token then
                token = corpseToken or Core.GenerateID("corpse")
                descriptor.token = token
            end
            if corpseToken == token or corpseToken == nil then
                if not accepted then
                    accepted = corpse
                    Internal.stampCorpse(record, corpse, token)
                else
                    Internal.removeCorpse(corpse)
                end
            else
                Internal.removeCorpse(corpse)
            end
        end
    end)
    state.corpseState = accepted and "inert_loaded" or "missing"
end

function Internal.auditCorpseBatch(reg)
    local dead = {}
    local batchSize = math.max(1, tonumber(Const.CORPSE_AUDIT_BATCH_SIZE) or 12)
    local startAt
    local count
    local i
    reg.ForEach(function(candidate)
        if candidate.alive == false then
            dead[#dead + 1] = candidate
        end
    end)
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
