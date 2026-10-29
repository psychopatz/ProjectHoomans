-- Canonical MP transport binding. Registry/Presence/BodyLifecycle retain all
-- durable and physical authority. This seam only projects verified relations.
PNC = PNC or {}
local Binding = PNC.MultiplayerBodyBinding or {}
PNC.MultiplayerBodyBinding = Binding
local receipts = setmetatable({}, { __mode = "k" })
local session
local revision = 0

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
    then return nil end
    local body = registry.GetLiveZombie(record.id)
    if not body or not body.getModData or not body.getOnlineID
        or (body.isDead and body:isDead())
        or (body.getSquare and not body:getSquare())
    then return nil end
    local md = body:getModData()
    if not md or md.PNC_NPC ~= true or md.PNC_BodyKind ~= "live"
        or tostring(md.PNC_UUID) ~= tostring(record.id)
        or tostring(md.PNC_BodyLease) ~= tostring(runtime.bodyLease)
    then return nil end
    local onlineID = tonumber(body:getOnlineID())
    if not Binding.ValidOnlineID(onlineID) then return nil end
    return body, onlineID, tostring(runtime.bodyLease)
end

function Binding.Build(record)
    if not isServer or isServer() ~= true or not record or record.id == nil then
        return nil
    end
    if not session then session = PNC.Core.GenerateID("body_binding_session") end
    local body, onlineID, lease = currentShell(record)
    local operation = body and "bind" or "unbind"
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
    receipts[record] = message
    return message
end

-- Exact removal proof is constructed from identity captured BEFORE engine
-- detach/corpse conversion. Anonymous legacy hints deliberately fail closed.
function Binding.Removal(npcId, incarnation, onlineId)
    if not isServer or isServer() ~= true or npcId == nil
        or type(incarnation) ~= "string" or incarnation == ""
        or not Binding.ValidOnlineID(onlineId) then return nil end
    if not session then session = PNC.Core.GenerateID("body_binding_session") end
    revision = revision + 1
    return { protocol = 1, session = session, revision = revision,
        npcId = tostring(npcId), incarnation = incarnation,
        onlineId = tonumber(onlineId), operation = "remove" }
end
return Binding
