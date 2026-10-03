-- Provider and handler registration plus durable effect indexing.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.WorldEffectService
local Internal = Service.Internal
local Repository = Internal.Repository or PNC.WorkRepository
local now = Internal.Now
local markDirty = Internal.MarkDirty
local effectsFor = Internal.EffectsFor
local ownerIDFor = Internal.OwnerIDFor
local pending = Internal.Pending
local pointsFor = Internal.PointsFor
local effectID = Internal.EffectID
local entryKey = Internal.EntryKey
local pointKey = Internal.PointKey

local function removeEntry(key)
    local entry = Service.Runtime.entries[key]
    if not entry then return end
    for _, point in ipairs(entry.points or {}) do
        local bucket = Service.Runtime.byPoint[point.key]
        if bucket then
            bucket[key] = nil
            local empty = true
            for _ in pairs(bucket) do empty = false; break end
            if empty then Service.Runtime.byPoint[point.key] = nil end
        end
    end
    Service.Runtime.entries[key] = nil
end

local function removeOwnerEntries(providerID, ownerID)
    local ownerKey = tostring(providerID) .. ":" .. tostring(ownerID)
    local keys = Service.Runtime.byOwner[ownerKey]
    if keys then
        for _, key in ipairs(keys) do removeEntry(key) end
    end
    Service.Runtime.byOwner[ownerKey] = nil
end

local function indexOwner(providerID, owner, shouldDirty)
    local provider = Service.Providers[tostring(providerID)]
    if not provider or type(owner) ~= "table" then return 0 end
    local ownerID = ownerIDFor(providerID, provider, owner)
    if ownerID == "" then return 0 end
    removeOwnerEntries(providerID, ownerID)
    local ownerKey = tostring(providerID) .. ":" .. ownerID
    local ownerKeys = {}
    local count = 0
    for _, effect in ipairs(effectsFor(provider, owner)) do
        if pending(effect, provider, owner) then
            if not effect.id and not effect.effectId then
                effect.id = effectID(providerID, ownerID, effect)
                if shouldDirty ~= false then markDirty(provider, owner) end
            end
            local key = entryKey(providerID, ownerID, effect)
            local entry = {
                key = key, providerID = tostring(providerID),
                ownerID = ownerID, owner = owner, effect = effect,
                points = {},
            }
            for _, point in ipairs(pointsFor(providerID, provider, owner,
                effect)) do
                local keyAtPoint = pointKey(point.x, point.y, point.z)
                if keyAtPoint then
                    point.key = keyAtPoint
                    entry.points[#entry.points + 1] = point
                    local bucket = Service.Runtime.byPoint[keyAtPoint]
                        or {}
                    bucket[key] = true
                    Service.Runtime.byPoint[keyAtPoint] = bucket
                end
            end
            Service.Runtime.entries[key] = entry
            ownerKeys[#ownerKeys + 1] = key
            count = count + 1
        end
    end
    Service.Runtime.byOwner[ownerKey] = ownerKeys
    return count
end

local function listProviderOwners(provider)
    if not provider or type(provider.List) ~= "function" then return {} end
    local owners = provider.List()
    return type(owners) == "table" and owners or {}
end

function Service.RegisterProvider(providerID, provider)
    providerID = tostring(providerID or "")
    if providerID == "" or type(provider) ~= "table" then
        return false, "INVALID_WORLD_EFFECT_PROVIDER"
    end
    Service.Providers[providerID] = provider
    Service.Runtime.indexed = false
    return true
end

function Service.Register(kind, handler)
    kind = tostring(kind or "")
    if kind == "" or type(handler) ~= "table"
        or type(handler.Apply) ~= "function"
    then return false, "INVALID_WORLD_EFFECT_HANDLER" end
    Service.Handlers[kind] = handler
    return true
end

function Service.IndexOwner(providerID, owner)
    return indexOwner(providerID, owner, true)
end

function Service.IndexOrder(order)
    return indexOwner("WORK_ORDER", order, true)
end

function Service.MarkPending(providerID, owner, effect, reason)
    if type(effect) ~= "table" then return false, "INVALID_WORLD_EFFECT" end
    local at = now()
    local previous = tostring(effect.waitReason or "")
    effect.state = "PENDING"
    effect.waitReason = tostring(reason or "WORLD_UNAVAILABLE")
    effect.updatedAt = at
    if previous ~= effect.waitReason or effect.nextRetryAt == nil then
        effect.nextRetryAt = 0
    end
    markDirty(Service.Providers[tostring(providerID)], owner)
    indexOwner(providerID, owner, false)
    return true, "WORLD_EFFECT_PENDING"
end

Internal.RemoveEntry = removeEntry
Internal.RemoveOwnerEntries = removeOwnerEntries
Internal.IndexOwner = indexOwner
Internal.ListProviderOwners = listProviderOwners
