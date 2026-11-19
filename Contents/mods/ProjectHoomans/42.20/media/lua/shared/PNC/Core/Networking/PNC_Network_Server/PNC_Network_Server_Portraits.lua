local Codec = require "PNC/Core/Networking/PNC_RosterPortraitCodec"
local Network = PNC.Network
local Internal = Network.Internal
local Const = PNC.Const
local Core = PNC.Core

local MAX_REQUESTS_PER_SECOND = 16
local MAX_RETAINED_PORTRAITS = 128

local capabilities = setmetatable({}, { __mode = "k" })
local lifetimes = setmetatable({}, { __mode = "k" })
local retained = {}
local invalidations
local epoch
local serial = 0

local function equal(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for key, value in pairs(a) do
        if not equal(value, b[key]) then return false end
    end
    for key, _ in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

function Network.ResetPortraitReplication()
    capabilities = setmetatable({}, { __mode = "k" })
    lifetimes = setmetatable({}, { __mode = "k" })
    retained = {}
    invalidations = nil
    epoch = nil
end

function Network.NegotiateRosterPortraits(player, protocol, codec)
    if not player then return false end
    local lean = Const.ROSTER_PORTRAIT_PROTOCOL ~= nil
        and protocol == Const.ROSTER_PORTRAIT_PROTOCOL
        and isServer and isServer() == true
        and (not getSpecificPlayer or player ~= getSpecificPlayer(0))
    if lean then
        local capability = capabilities[player] or { window = 0, requests = 0 }
        capability.packed = codec == Codec.Fingerprint
        capabilities[player] = capability
    else
        capabilities[player] = nil
    end
    return lean == true
end

function Internal.UsesLeanRosterPortraits(player)
    return player ~= nil and capabilities[player] ~= nil
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
    if equal(state.portrait, portrait) then return end
    state.reference = {
        incarnation = state.reference.incarnation,
        revision = state.reference.revision + 1,
    }
    state.portrait = portrait
    state.packed = nil
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
        if equal(state.portrait.equipment, equipment) then return end
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

local function selectPacked(state, portrait)
    if state.packed ~= nil then return state.packed end
    local packed = Codec.Pack(portrait)
    local budget = Network.PayloadBudget
    if packed and budget.Estimate({ packedPortrait = packed, portraitCodec = Codec.Fingerprint }, math.huge)
        >= budget.Estimate({ portrait = portrait }, math.huge)
    then
        packed = nil
    end
    state.packed = packed or false
    return packed
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
    if cached and capability.packed and args.forceResolved ~= true then
        local packed = selectPacked(state, portrait)
        if packed then
            payload.packedPortrait = packed
            payload.portraitCodec = Codec.Fingerprint
        end
    end
    if not payload.packedPortrait then payload.portrait = portrait end
    return Internal.SendToPlayer(player, Const.CMD_ROSTER_PORTRAIT, payload)
end

return Network
