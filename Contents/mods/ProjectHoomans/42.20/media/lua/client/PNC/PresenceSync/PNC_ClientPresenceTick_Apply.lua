--[[
    PNC Client Presence Tick: resolved-snapshot body application.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Const = PNC.Const
local ClientState = PNC.Network and PNC.Network.ClientState
local Tick = Internal.PresenceTick or {}
Internal.PresenceTick = Tick
local RemoteSnapshots = Tick.RemoteSnapshots
local Presentation = Tick.Presentation or {}
Tick.Presentation = Presentation
local isSnapshotDebugEnabled = Internal.IsSnapshotDebugEnabled
local logClientMotionDebug = Internal.LogClientMotionDebug
local applySnapshotFacing = Internal.ApplySnapshotFacing
local applySnapshotToBody = Internal.ApplySnapshotToBody
local pruneSnapshotDuplicates = Internal.PruneSnapshotDuplicates
local resolveSnapshotBody = Internal.ResolveSnapshotBody
local bindNativePathSnapshot = Internal.BindNativePathSnapshot
local voiceTriggers = PNC.NPCVoice
    and PNC.NPCVoice.Triggers or nil
local combatAudio = PNC.NPCCombatAudio

local function resolveSnapshotBodyFromIndexes(snapshot)
    local id
    if type(snapshot) ~= "table" or snapshot.id == nil then
        return nil
    end
    id = tostring(snapshot.id)
    return Sync.BodyByLease[
        id .. ":" .. tostring(snapshot.liveBodyLease or "")
    ] or Sync.BodyByInstanceID[
        tostring(snapshot.liveBodyInstanceID or "")
    ] or Sync.BodyByID[id] or Sync.BodyByOnlineID[
        tostring(snapshot.liveBodyOnlineID or "")
    ]
end

local function hasIncapacitatedSnapshots()
    local snapshot
    if Sync.hasLocalIncapacitatedSnapshots ~= nil then
        return Sync.hasLocalIncapacitatedSnapshots == true
    end
    for _, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.healthState == "incapacitated" then
            Sync.hasLocalIncapacitatedSnapshots = true
            return true
        end
    end
    Sync.hasLocalIncapacitatedSnapshots = false
    return false
end

local function applySnapshots(
    now,
    remoteReplica,
    applyLocalVisuals,
    localVisualMaintainDue,
    localSnapshotChangedByID
)
    local id
    local snapshot
    local body
    local snapshotState
    local snapshotChanged
    local presentationChanged
    local presentationDue
    local facingDue
    local bindingDue
    if not applyLocalVisuals and not hasIncapacitatedSnapshots() then
        return
    end
    for id, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.interestDetailed ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE and snapshot.alive ~= false
        then
            body = resolveSnapshotBody
                and resolveSnapshotBody(snapshot)
                or resolveSnapshotBodyFromIndexes(snapshot)
            if body then
                if applyLocalVisuals
                    or snapshot.healthState == "incapacitated"
                then
                    if remoteReplica then
                        snapshotState, snapshotChanged, presentationDue,
                            presentationChanged =
                            RemoteSnapshots.PresentationDue(
                                tostring(id),
                                snapshot,
                                body,
                                now
                            )
                        bindingDue = RemoteSnapshots.NativeBindingDue(
                            snapshotState,
                            snapshot,
                            body,
                            now,
                            snapshotChanged,
                            presentationChanged
                        )
                        if bindingDue then
                            if bindNativePathSnapshot then
                                bindNativePathSnapshot(
                                    snapshot,
                                    body,
                                    now
                                )
                            end
                            snapshotState.nextNativeBindAt = now
                                + (tonumber(Const.CLIENT_REMOTE_NATIVE_BIND_MS) or 250)
                            snapshotState.nativeMoveActive = snapshot.visualState
                                and snapshot.visualState.nativeMoveActive == true
                            snapshotState.attackActive = snapshot.visualState
                                and snapshot.visualState.attackActive == true
                        end
                        facingDue = RemoteSnapshots.FacingDue(
                            snapshotState,
                            snapshot,
                            now
                        )
                        -- Native PathFindBehavior2 and zombie replication own
                        -- facing while delegated movement is active.
                        if facingDue and applySnapshotFacing then
                            applySnapshotFacing(body, snapshot)
                        end
                    else
                        snapshotChanged = localSnapshotChangedByID[
                            tostring(id)
                        ] == true
                        presentationDue = localVisualMaintainDue
                    end
                    -- Incapacitated bodies need an idempotent repair pass even
                    -- when the snapshot and its motion key are unchanged.
                    -- The engine can reassert stagger/crawler flags between
                    -- snapshot applications, so the health-state branch must
                    -- not be throttled by normal presentation cadence.
                    if snapshotChanged or presentationDue
                        or snapshot.healthState == "incapacitated"
                    then
                        pruneSnapshotDuplicates(snapshot, body)
                        -- The embodied NPC is already an engine-replicated
                        -- IsoZombie.  Project Zomboid smooths its authoritative
                        -- server position just as it does for Bandits.  Applying
                        -- roster-snapshot X/Y interpolation here creates a second
                        -- transport owner that continually rewinds the native
                        -- network mover.
                        -- The authoritative SP/listen-server body was already
                        -- faced by PathService. Dedicated clients alone apply
                        -- replicated facing.
                        applySnapshotToBody(snapshot, body, remoteReplica)
                        if combatAudio and combatAudio.Observe then
                            combatAudio.Observe(snapshot, body, now)
                        end
                        if voiceTriggers and voiceTriggers.Observe then
                            voiceTriggers.Observe(
                                snapshot,
                                body,
                                remoteReplica,
                                now
                            )
                        end
                    end
                end
            elseif isSnapshotDebugEnabled(snapshot)
                and (now - (tonumber(Sync.UnresolvedLogAtByID[tostring(id)]) or 0)) >= 3000
            then
                Sync.UnresolvedLogAtByID[tostring(id)] = now
                logClientMotionDebug(
                    snapshot,
                    id,
                    "body_unresolved",
                    "onlineID=" .. tostring(snapshot.liveBodyOnlineID or "nil")
                        .. " instanceID=" .. tostring(snapshot.liveBodyInstanceID or "nil")
                )
            end
        end
    end
end

Presentation.ApplySnapshots = applySnapshots
