-- ClientPresenceSync adapter for the canonical binding protocol. All lookup
-- admission passes through the reconciler; ModData below is post-bind cache.
local Binding = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Client"
local Runtime = {}
local client
local lastSweep = -250
local function remote()
    return PNC.Core and PNC.Core.IsClientOnly and PNC.Core.IsClientOnly() == true
end
local function now() return PNC.Core.Now() end
local function data(body) return body and body.getModData and body:getModData() end
local function sync() return PNC.ClientPresenceSync end
local function eligible(body, entry)
    if not body or not body.getOnlineID or body:getOnlineID() ~= entry.onlineId
        or (body.isDead and body:isDead())
        or (body.getSquare and not body:getSquare()) then return false end
    local md = data(body)
    return md ~= nil and (md.PNC_Owner == nil or md.PNC_Owner == "ProjectHoomans")
        and (md.PNC_UUID == nil or tostring(md.PNC_UUID) == entry.npcId)
        and (md.PNC_BodyLease == nil or tostring(md.PNC_BodyLease) == entry.incarnation)
end
local function getClient()
    if client then return client end
    client = Binding.NewClient({
        canBind = eligible,
        isValid = function(body, entry)
            local md = data(body)
            return eligible(body, entry) and md.PNC_NPC == true
                and md.PNC_UUID == entry.npcId and md.PNC_BodyLease == entry.incarnation
                and md.PNC_MPBound == true
        end,
        onRemove = function(body)
            -- Called only for a currently bound, still-valid exact tuple.
            if body.removeFromWorld then body:removeFromWorld() end
            if body.removeFromSquare then body:removeFromSquare() end
        end,
        onBind = function(body, entry)
            local md = data(body)
            md.PNC_UUID, md.PNC_NPC = entry.npcId, true
            md.PNC_BodyLease, md.PNC_BodyKind = entry.incarnation, "live"
            md.PNC_MPBound = true
            local s = sync()
            if s then
                s.BodyByID[entry.npcId] = body
                s.BodyByLease[entry.npcId .. ":" .. entry.incarnation] = body
                s.BodyByOnlineID[tostring(entry.onlineId)] = body
            end
        end,
        onUnbind = function(body, entry)
            local md = data(body)
            if md and md.PNC_MPBound == true and md.PNC_UUID == entry.npcId
                and md.PNC_BodyLease == entry.incarnation then
                md.PNC_UUID, md.PNC_NPC, md.PNC_BodyLease = nil, nil, nil
                md.PNC_BodyKind, md.PNC_MPBound = nil, nil
                md.PNC_Owner, md.PNC_OwnerVersion = nil, nil
                md.PNC_PersistedShell, md.PNC_TagVersion = nil, nil
                md.PNC_ShellVersion, md.PNC_ShellCarrier = nil, nil
                md.PNC_ShellCarrierVersion, md.PNC_BaseOutfit = nil, nil
                md.PNC_LiveBodyOnlineID, md.PNC_LiveBodyInstanceID = nil, nil
                if body.setVariable then
                    body:setVariable("PNCActor", false)
                    body:setVariable("PNCLive", false)
                end
            end
            local s = sync()
            if s then
                if s.BodyByID[entry.npcId] == body then s.BodyByID[entry.npcId] = nil end
                local key = entry.npcId .. ":" .. tostring(entry.incarnation)
                if s.BodyByLease[key] == body then s.BodyByLease[key] = nil end
                key = tostring(entry.onlineId)
                if s.BodyByOnlineID[key] == body then s.BodyByOnlineID[key] = nil end
                local state = s.NativePathStateByBody and s.NativePathStateByBody[body]
                if state then state.snapshot, state.releasePending = nil, true end
            end
        end,
    })
    return client
end
function Runtime.AcceptSnapshot(snapshot)
    if not remote() or type(snapshot) ~= "table" then return false end
    local message = snapshot.bodyBinding
    if snapshot.interestDetailed == false or (snapshot.alive == false
        and type(message) ~= "table") then
        if client then client.DropInterest(snapshot.id) end
        return false
    end
    if type(message) ~= "table" or message.npcId ~= tostring(snapshot.id) then return false end
    if message.operation == "bind" and (snapshot.alive == false
        or snapshot.presenceState ~= PNC.Const.PRESENCE_LIVE
        or snapshot.interestDetailed == false
        or message.incarnation ~= tostring(snapshot.liveBodyLease)
        or message.onlineId ~= snapshot.liveBodyOnlineID) then return false end
    return getClient().Receive(message, now())
end
function Runtime.Forget(npcId)
    if remote() and client then client.DropInterest(npcId) end
end
function Runtime.Remove(args)
    if not remote() or type(args) ~= "table" or type(args.bodyBinding) ~= "table"
        or args.bodyBinding.operation ~= "remove"
        or args.bodyBinding.npcId ~= tostring(args.id) then return 0 end
    local m = args.bodyBinding
    local body = getClient().Resolve(m.npcId, m.incarnation, now())
    local accepted = getClient().Receive(m, now())
    return accepted and body and 1 or 0
end
function Runtime.Observe(body)
    if not remote() or not body or not body.getOnlineID then return end
    getClient().Observe(body, body:getOnlineID(), now())
end
function Runtime.Resolve(snapshot)
    if not remote() or type(snapshot) ~= "table" or snapshot.interestDetailed == false
        or snapshot.alive == false or snapshot.presenceState ~= PNC.Const.PRESENCE_LIVE
    then return nil end
    local m = snapshot.bodyBinding
    if type(m) ~= "table" or m.operation ~= "bind" or m.npcId ~= tostring(snapshot.id)
        or m.incarnation ~= tostring(snapshot.liveBodyLease)
        or m.onlineId ~= snapshot.liveBodyOnlineID then return nil end
    local body = getClient().Resolve(snapshot.id, snapshot.liveBodyLease, now())
    return body and body:getOnlineID() == m.onlineId and body or nil
end
function Runtime.Sweep(at)
    if remote() and client and at >= lastSweep + 250 then
        client.Sweep(at)
        lastSweep = at
    end
end
function Runtime.Reset()
    if client then client.Reset() end
    client, lastSweep = nil, -250
end
function Binding.IsClientBody(body)
    local md = data(body)
    local state = PNC.Network and PNC.Network.ClientState
    local snapshot = md and md.PNC_UUID and state and state.snapshots
        and state.snapshots[tostring(md.PNC_UUID)]
    return snapshot ~= nil and Runtime.Resolve(snapshot) == body
end
function Runtime.Diagnostics()
    return client and client.Diagnostics() or { entries=0, observed=0, ready=false }
end
Binding.ClientDiagnostics = Runtime.Diagnostics
return Runtime
