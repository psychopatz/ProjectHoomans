-- Canonical MP transport binding. Registry/Presence/BodyLifecycle retain all
-- durable and physical authority. This seam only projects verified relations.
PNC = PNC or {}
local Binding = PNC.MultiplayerBodyBinding or {}
PNC.MultiplayerBodyBinding = Binding
local receipts = setmetatable({}, { __mode = "k" })
local projectionKeys = setmetatable({}, { __mode = "k" })
local session
local revision = 0
local diagnostics = { binds=0, unbinds=0, removes=0, lastReason="idle" }

function Binding.ValidOnlineID(value)
    local id = tonumber(value)
    return id ~= nil and id == id and id >= 0 and id <= 32767
        and id == math.floor(id)
end

local function currentShell(record)
    local registry = PNC.Registry
    local runtime = record.runtime
    if record.alive == false or record.presenceState ~= PNC.Const.PRESENCE_LIVE
        or not runtime or not runtime.bodyLease
        or not registry or not registry.GetLiveZombie
    then return nil, nil, nil, "not_live" end
    local body = registry.GetLiveZombie(record.id)
    if not body or not body.getModData or not body.getOnlineID
        or (body.isDead and body:isDead())
        or (body.getSquare and not body:getSquare())
    then return nil, nil, nil, "no_attached_shell" end
    local md = body:getModData()
    if not md or md.PNC_NPC ~= true or md.PNC_BodyKind ~= "live"
        or tostring(md.PNC_UUID) ~= tostring(record.id)
        or tostring(md.PNC_BodyLease) ~= tostring(runtime.bodyLease)
    then return nil, nil, nil, "identity_conflict" end
    local onlineID = tonumber(body:getOnlineID())
    if not Binding.ValidOnlineID(onlineID) then return nil, nil, nil, "invalid_online_id" end
    return body, onlineID, tostring(runtime.bodyLease)
end

function Binding.Build(record)
    if not isServer or isServer() ~= true or not record or record.id == nil then
        return nil
    end
    if not session then session = PNC.Core.GenerateID("body_binding_session") end
    local body, onlineID, lease, reason = currentShell(record)
    -- A detached frame during Presence's body-loss grace is not an
    -- authoritative lifetime transition. Do not retire replicas prematurely.
    if reason == "no_attached_shell" and record.alive ~= false
        and record.presenceState == PNC.Const.PRESENCE_LIVE then return nil end
    local operation = body and "bind" or "unbind"
    local key = body and "binds" or "unbinds"
    diagnostics[key] = diagnostics[key] + 1
    diagnostics.lastReason = reason or "verified_registry_shell"
    local previous = receipts[record]
    -- Each authoritative publication is fresh proof for bounded client TTLs.
    -- Revisions order publications; lease equality still defines incarnation.
    revision = revision + 1
    local message = {
        protocol = 1, session = session, revision = revision,
        npcId = tostring(record.id), operation = operation,
        incarnation = lease, onlineId = onlineID,
    }
    if previous and previous.operation == "bind"
        and (operation ~= "bind" or previous.onlineId ~= onlineID
            or previous.incarnation ~= lease)
    then
        message.previousIncarnation = previous.incarnation
        message.previousOnlineId = previous.onlineId
    end
    if operation == "unbind" and previous and previous.operation == "unbind" then
        message.previousIncarnation = previous.previousIncarnation
        message.previousOnlineId = previous.previousOnlineId
    end
    receipts[record] = message
    return message
end

-- Exact removal proof is constructed from identity captured BEFORE engine
-- detach/corpse conversion. Anonymous legacy hints deliberately fail closed.
-- Build one coherent transport projection. Snapshot builders must not mix a
-- freshly observed body online id with a stale record.liveBodyOnlineID cache:
-- pure clients reject that tuple as internally inconsistent.
function Binding.Projection(record)
    local message = Binding.Build(record)
    local onlineID = nil
    local lease = record and record.runtime
        and record.runtime.bodyLease or nil

    if message and message.operation == "bind" then
        onlineID = message.onlineId
        lease = message.incarnation
        if record then
            record.liveBodyOnlineID = onlineID
            local key = tostring(lease) .. ":" .. tostring(onlineID)
            if projectionKeys[record] ~= key then
                projectionKeys[record] = key
                if PNC.Core and PNC.Core.LogInfo then
                    PNC.Core.LogInfo(
                        "PNC mp_body_binding_ready npc="
                            .. tostring(record.id)
                            .. " lease=" .. tostring(lease)
                            .. " onlineID=" .. tostring(onlineID)
                    )
                end
            end
        end
    elseif record and record.presenceState ~= PNC.Const.PRESENCE_LIVE then
        lease = nil
    end

    return message, onlineID, lease
end

function Binding.Removal(npcId, incarnation, onlineId)
    if not isServer or isServer() ~= true or npcId == nil
        or type(incarnation) ~= "string" or incarnation == ""
        or not Binding.ValidOnlineID(onlineId) then return nil end
    if not session then session = PNC.Core.GenerateID("body_binding_session") end
    revision = revision + 1
    diagnostics.removes = diagnostics.removes + 1
    diagnostics.lastReason = "exact_removal"
    return { protocol = 1, session = session, revision = revision,
        npcId = tostring(npcId), incarnation = incarnation,
        onlineId = tonumber(onlineId), operation = "remove" }
end
function Binding.Diagnostics()
    return { binds=diagnostics.binds, unbinds=diagnostics.unbinds,
        removes=diagnostics.removes, lastReason=diagnostics.lastReason, revision=revision }
end
return Binding
