-- Client Puppet Opera preview lease and replay runtime.
--
-- This spoke owns only local presentation previews. Live session requests,
-- placement-preview state, and server snapshots remain in the coordinator;
-- local movement/beat execution remains in Client_Runtime.lua.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Client = Opera.Client or {}
Opera.Client = Client
local Internal = Client.Internal or {}
Client.Internal = Internal

local State = Internal.State
local timestamp = Internal.timestamp
local localPlayer = Internal.localPlayer

local PREVIEW_PLAYER_OWNER = "ProjectHoomans.PuppetOperaPreview"
local PREVIEW_NPC_OWNER_KEY = "PNC_PuppetOperaPreviewOwner"
local PREVIEW_NPC_OWNER = "ProjectHoomans.PuppetOperaPreview"

local function previewNPCMarker(body)
    local modData = body and body.getModData and body:getModData() or nil
    return modData and tostring(modData[PREVIEW_NPC_OWNER_KEY] or "")
        or ""
end

local function markPreviewNPC(body)
    local modData = body and body.getModData and body:getModData() or nil
    if modData then modData[PREVIEW_NPC_OWNER_KEY] = PREVIEW_NPC_OWNER end
end

local function clearPreviewNPCMarker(body)
    local modData = body and body.getModData and body:getModData() or nil
    if modData and previewNPCMarker(body) == PREVIEW_NPC_OWNER then
        modData[PREVIEW_NPC_OWNER_KEY] = nil
    end
end

function Client.PreviewPlayer(entry)
    if type(entry) ~= "table" then return false, "player_preview_entry_missing" end
    local controller = PsychopatzCore
        and PsychopatzCore.Animation
        and PsychopatzCore.Animation.Player
        or nil
    if not controller or not controller.Play then
        return false, "player_animation_controller_unavailable"
    end
    local runtime = controller.Runtime and controller.Runtime() or nil
    if runtime and runtime.active == true then
        if tostring(runtime.owner or "") ~= PREVIEW_PLAYER_OWNER then
            return false, "player_animation_owned_by_other"
        end
        local handle = controller.GetActiveHandle
            and controller.GetActiveHandle() or nil
        if controller.Stop then controller.Stop(handle, "preview_replaced") end
    end
    local player = controller.ResolveLocalPlayer
        and controller.ResolveLocalPlayer() or localPlayer()
    local accepted, reason = controller.Play(player, entry, {
        owner = PREVIEW_PLAYER_OWNER,
        loop = State.previewLoop == true,
        actionEvents = {},
    })
    if accepted == true then State.previewPlayerOwner = PREVIEW_PLAYER_OWNER end
    return accepted == true, reason
end

function Client.PreviewNPC(entry, npcID, body, record)
    if type(entry) ~= "table" then return false, "npc_preview_entry_missing" end
    local debugPlayer = PNC.AnimationDebugPlayer
    if not debugPlayer or not debugPlayer.PlayXML then
        return false, "npc_animation_debug_player_unavailable"
    end
    local id = tostring(npcID or "")
    local active = debugPlayer.active
    if active then
        if tostring(active.npcId or "") ~= id
            or State.previewNPCID ~= id
            or previewNPCMarker(active.body) ~= PREVIEW_NPC_OWNER
        then
            return false, "npc_preview_owned_by_other"
        end
    end
    if active and debugPlayer.Stop then
        clearPreviewNPCMarker(active.body)
        debugPlayer.Stop("preview_replaced")
    end
    -- The Presentation Lab's default preview is intentionally a generic
    -- debugger lease. Puppet Opera previews are a non-combat presentation
    -- lease, otherwise PlayBump leaves the body in `bumped` and the server
    -- readiness gate correctly rejects the same actor as action-state busy.
    -- Keep this option at the shared Animation.PlayBump boundary so the
    -- builder uses the same XML/BumpType pipeline as the NPC lab without
    -- weakening the normal NPC action route.
    local accepted, reason = debugPlayer.PlayXML(
        entry,
        id,
        body,
        record,
        {
            sceneId = PREVIEW_NPC_OWNER .. ":" .. id,
            sceneRevision = 0,
            leaseUntil = timestamp() + 10000,
            keepManagedUseless = false,
            nonCombat = true,
            loop = State.previewLoop == true,
        }
    )
    if accepted == true then
        State.previewNPCID = id
        State.previewNPCBody = debugPlayer.active
            and debugPlayer.active.body or body
        State.previewNPCEntry = entry
        State.previewNPCRecord = record
        State.previewNPCNextAt = timestamp() + 900
        markPreviewNPC(State.previewNPCBody)
    end
    return accepted == true, reason
end

function Client.StopPreview()
    local stopped = false
    local controller = PsychopatzCore
        and PsychopatzCore.Animation
        and PsychopatzCore.Animation.Player
        or nil
    local runtime = controller and controller.Runtime and controller.Runtime()
        or nil
    if controller and runtime and runtime.active
        and tostring(runtime.owner or "") == PREVIEW_PLAYER_OWNER
    then
        local handle = controller.GetActiveHandle
            and controller.GetActiveHandle() or nil
        stopped = controller.Stop(handle, "preview_stopped") == true or stopped
    end
    local debugPlayer = PNC.AnimationDebugPlayer
    if debugPlayer and debugPlayer.active
        and tostring(debugPlayer.active.npcId or "")
            == tostring(State.previewNPCID or "")
        and previewNPCMarker(debugPlayer.active.body) == PREVIEW_NPC_OWNER
    then
        clearPreviewNPCMarker(debugPlayer.active.body)
        stopped = debugPlayer.Stop("preview_stopped") == true or stopped
    end
    State.previewPlayerOwner = nil
    State.previewNPCID = nil
    State.previewNPCBody = nil
    State.previewNPCEntry = nil
    State.previewNPCRecord = nil
    State.previewNPCNextAt = 0
    return stopped
end

function Client.SetPreviewLoopEnabled(enabled)
    State.previewLoop = enabled == true
    if not State.previewLoop then State.previewNPCNextAt = 0 end
    return State.previewLoop
end

function Client.GetPreviewLoopEnabled()
    return State.previewLoop == true
end

local function pumpPreviewLoop()
    if State.previewLoop ~= true then return end
    local debugPlayer = PNC.AnimationDebugPlayer
    local active = debugPlayer and debugPlayer.active or nil
    if not active
        or tostring(active.npcId or "") ~= tostring(State.previewNPCID or "")
        or previewNPCMarker(active.body) ~= PREVIEW_NPC_OWNER
    then
        return
    end
    local current = timestamp()
    if debugPlayer.Maintain then
        debugPlayer.Maintain(active.body, current)
    end
    if current < (tonumber(State.previewNPCNextAt) or 0) then return end
    if debugPlayer.Replay and State.previewNPCEntry then
        local accepted = debugPlayer.Replay()
        if accepted == true then
            local entry = State.previewNPCEntry
            local duration = tonumber(entry.durationMs) or 900
            local speed = tonumber(entry.speed) or 1
            duration = math.floor(duration / math.max(0.1, speed))
            duration = math.max(250, math.min(5000, duration))
            State.previewNPCNextAt = current + duration
            if debugPlayer.active and debugPlayer.active.body then
                markPreviewNPC(debugPlayer.active.body)
            end
        end
    end
end

Internal.pumpPreviewLoop = pumpPreviewLoop

return Client
