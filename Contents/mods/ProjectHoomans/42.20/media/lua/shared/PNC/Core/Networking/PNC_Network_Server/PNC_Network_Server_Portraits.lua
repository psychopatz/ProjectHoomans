local Codec = require "PNC/Core/Networking/PNC_RosterPortraitCodec"
local Patch = require "PNC/Core/Networking/PNC_RosterPortraitPatch"
local Network = PNC.Network
local Internal = Network.Internal
local Const = PNC.Const
local Core = PNC.Core

local MAX_REQUESTS_PER_SECOND = 16
local MAX_RETAINED_PORTRAITS = 128

local capabilities = setmetatable({}, { __mode = "k" })
local domainDeltaFallback = setmetatable({}, { __mode = "k" })
local lifetimes = setmetatable({}, { __mode = "k" })
local retained = {}
local invalidations
local epoch
local serial = 0

function Network.ResetPortraitReplication()
    capabilities = setmetatable({}, { __mode = "k" })
    domainDeltaFallback = setmetatable({}, { __mode = "k" })
    lifetimes = setmetatable({}, { __mode = "k" })
    retained = {}
    invalidations = nil
    epoch = nil
end

function Network.NegotiateDomainDeltas(player, protocol)
    if not player then return false end
    local supported = Const.DOMAIN_DELTA_PROTOCOL == nil
        or protocol == nil
        or tonumber(protocol) == tonumber(Const.DOMAIN_DELTA_PROTOCOL)
    if supported then
        domainDeltaFallback[player] = nil
        return true
    end
    domainDeltaFallback[player] = true
    return false
end

function Internal.UsesDomainDeltas(player)
    return not (player ~= nil and domainDeltaFallback[player] == true)
end

function Network.NegotiateRosterPortraits(player, protocol, codec, patch)
    if not player then return false end
    local lean = Const.ROSTER_PORTRAIT_PROTOCOL ~= nil
        and protocol == Const.ROSTER_PORTRAIT_PROTOCOL
        and isServer and isServer() == true
        and (not getSpecificPlayer or player ~= getSpecificPlayer(0))
    if lean then
        local capability = capabilities[player] or { window = 0, requests = 0 }
        capability.packed = codec == Codec.Fingerprint
        capability.patch = patch == Patch.Protocol
        capabilities[player] = capability
    else
        capabilities[player] = nil
    end
    return lean == true
end

function Internal.UsesLeanRosterPortraits(player)
    return player ~= nil and capabilities[player] ~= nil
end

function Internal.PruneRosterPortraitCapabilities(interests)
    for player, _ in pairs(capabilities) do
        local state = interests[Internal.PlayerKey(player)]
        if not state or state.player ~= player then capabilities[player] = nil end
    end
    for player, _ in pairs(domainDeltaFallback) do
        local state = interests[Internal.PlayerKey(player)]
        if not state or state.player ~= player then
            domainDeltaFallback[player] = nil
        end
    end
end

local function lifetime(record)
    local state = lifetimes[record]
    if state then return state end
    epoch = epoch or tostring(Core.Now())
    serial = serial + 1
    state = { reference = { incarnation = epoch .. ":" .. tostring(serial), revision = 1 } }
    lifetimes[record] = state
    return state
end

function Internal.GetPortraitReference(record)
    return lifetime(record).reference
end

local function release(record)
    for index, entry in ipairs(retained) do
        if entry == record then
            table.remove(retained, index)
            return
        end
    end
end

function Network.ForgetPortraitRecord(record)
    if not record then return end
    release(record)
    lifetimes[record] = nil
    if invalidations then invalidations[record] = nil end
end

local function retain(record, state, portrait)
    if not state.portrait then
        if #retained >= MAX_RETAINED_PORTRAITS then
            -- Entries at capacity can still return a resolved baseline.
            -- Their clients revalidate it when it is revisited.
            return false
        end
        retained[#retained + 1] = record
    end
    state.portrait = portrait
    return true
end

local function update(record, state, portrait)
    if Patch.Equal(state.portrait, portrait) then return end
    state.previous = { revision = state.reference.revision, portrait = state.portrait }
    state.reference = {
        incarnation = state.reference.incarnation,
        revision = state.reference.revision + 1,
    }
    state.portrait = portrait
    state.packed, state.packedBytes, state.fullBytes = nil, nil, nil
    state.patch, state.patchBytes = nil, nil
    Network.QueueRosterDelta(record, false, "portrait_changed", false)
end

local function queueInvalidation(record, scope)
    local state = lifetimes[record]
    if not state or not state.portrait then return end
    invalidations = invalidations or {}
    if invalidations[record] ~= "all" then invalidations[record] = scope end
end

function Network.RefreshPortraitEquipment(record)
    queueInvalidation(record, "equipment")
end

function Network.RefreshRosterPortrait(record)
    queueInvalidation(record, "all")
end

local function processInvalidation(record, state, scope)
    local identity = PNC.Identity
    if scope == "equipment" then
        local equipment = identity.NormalizePortraitEquipment(record)
        if Patch.Equal(state.portrait.equipment, equipment) then return end
        local projection = Core.ShallowCopy(state.portrait)
        projection.equipment = equipment
        update(record, state, projection)
    else
        update(record, state, identity.ProjectPortrait(record))
    end
end

function Internal.FlushPortraitInvalidations()
    if not invalidations then return end
    local queued = invalidations
    invalidations = nil
    for record, scope in pairs(queued) do
        local state = lifetimes[record]
        if state and state.portrait then
            processInvalidation(record, state, scope)
        end
    end
end

local function estimatedCost(payload)
    local bytes, sections, oversize = Network.PayloadBudget.Estimate(payload)
    if oversize or sections._omittedSections then return math.huge end
    return bytes
end

local function fullBytes(state)
    state.fullBytes = state.fullBytes or estimatedCost({ portrait = state.portrait })
    return state.fullBytes
end

local function selectPacked(state)
    if state.packed ~= nil then return state.packed end
    local packed = Codec.Pack(state.portrait)
    if packed then
        local bytes = estimatedCost(
            { packedPortrait = packed, portraitCodec = Codec.Fingerprint })
        if bytes < fullBytes(state) then
            state.packed = packed
            state.packedBytes = bytes
            return packed
        end
    end
    state.packed = false
end

local function selectPatch(state, args, packed)
    local previous = state.previous
    if not previous or args.baseRevision ~= previous.revision
        or args.targetRevision ~= state.reference.revision
        or previous.revision + 1 ~= state.reference.revision
    then
        return nil
    end
    if state.patch == nil then
        local changes = Patch.Create(previous.portrait, state.portrait)
        state.patch = changes and {
            protocol = Patch.Protocol, baseRevision = previous.revision,
            targetRevision = state.reference.revision, changes = changes,
        } or false
        if state.patch then
            state.patchBytes = estimatedCost({ portraitPatch = state.patch })
        end
    end
    if state.patch and state.patchBytes < (packed and state.packedBytes or fullBytes(state)) then
        return state.patch
    end
    return nil
end

function Network.SendRosterPortrait(player, args)
    local capability = capabilities[player]
    if not capability or type(args) ~= "table" or type(args.id) ~= "string" or #args.id > 128
        or type(args.incarnation) ~= "string" or #args.incarnation > 128
        or type(args.requestID) ~= "string" or #args.requestID > 128
    then
        return false
    end
    local window = math.floor(Core.Now() / 1000)
    if capability.window ~= window then
        capability.window, capability.requests = window, 0
    end
    if capability.requests >= MAX_REQUESTS_PER_SECOND then return false end
    capability.requests = capability.requests + 1

    -- Roster portraits have the roster's visibility. This path never returns
    -- character details or inventory and cannot hydrate runtime-only views.
    local registry = PNC.Registry
    local record
    if registry.Data then
        record = registry.Data[args.id]
    else
        record = registry.Get(args.id)
    end
    local state = record and lifetimes[record]
    local identity = PNC.Identity
    if not state or state.reference.incarnation ~= args.incarnation
        or not identity or not identity.ProjectPortrait
    then
        return false
    end
    if invalidations and invalidations[record] then
        local scope = invalidations[record]
        invalidations[record] = nil
        processInvalidation(record, state, scope)
    end
    local portrait = state.portrait or identity.ProjectPortrait(record)
    local cached = retain(record, state, portrait)
    local payload = {
        id = args.id,
        requestID = args.requestID,
        portraitRef = state.reference,
        transient = not cached,
    }
    local packed, patch
    if cached and args.forceResolved ~= true then
        if capability.packed then packed = selectPacked(state) end
        if capability.patch then patch = selectPatch(state, args, packed) end
    end
    if patch then
        payload.portraitPatch = patch
    elseif packed then
        payload.packedPortrait = packed
        payload.portraitCodec = Codec.Fingerprint
    else
        payload.portrait = portrait
    end
    return Internal.SendToPlayer(player, Const.CMD_ROSTER_PORTRAIT, payload)
end

return Network
