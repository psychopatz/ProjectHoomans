-- Diagnostics indexing and relationship-change notifications for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local ClientState = Internal.ClientState
local RELATIONSHIP_CHANGE_VISIBLE_MS =
    Internal.RELATIONSHIP_CHANGE_VISIBLE_MS

function Overlay.RefreshDiagnosticsCache()
    local snapshot = ClientState.factionDebug
    if Overlay.indexedSnapshot == snapshot then return end
    local byID = {}
    local now = PNC.Core.Now()
    Overlay.lastRelationshipSequenceByNPCID =
        Overlay.lastRelationshipSequenceByNPCID or {}
    Overlay.activeRelationshipChanges =
        Overlay.activeRelationshipChanges or {}
    for _, diagnostic in ipairs(
        snapshot and snapshot.npcDiagnostics or {}
    ) do
        if diagnostic.npcID then
            byID[diagnostic.npcID] = diagnostic
            local changes =
                diagnostic.relationshipChanges or {}
            local latest = changes[#changes]
            local seen =
                Overlay.lastRelationshipSequenceByNPCID[
                    diagnostic.npcID
                ]
            local latestSequence = latest
                and (tonumber(latest.sequence) or 0) or 0
            if latest
                and (
                    seen == nil
                    or latestSequence
                        ~= (tonumber(seen) or 0)
                )
            then
                local unseen = 0
                for _, change in ipairs(changes) do
                    if seen == nil
                        or latestSequence
                            < (tonumber(seen) or 0)
                        or (tonumber(change.sequence) or 0)
                            > (tonumber(seen) or 0)
                    then
                        unseen = unseen + 1
                    end
                end
                Overlay.activeRelationshipChanges[
                    diagnostic.npcID
                ] = {
                    value = latest,
                    count = unseen,
                    expiresAt = now
                        + RELATIONSHIP_CHANGE_VISIBLE_MS,
                }
                Overlay.lastRelationshipSequenceByNPCID[
                    diagnostic.npcID
                ] = latest.sequence
            end
        end
    end
    Overlay.diagnosticsByNPCID = byID
    Overlay.indexedSnapshot = snapshot
end

function Overlay.GetNPCDiagnostic(npcID)
    Overlay.RefreshDiagnosticsCache()
    return Overlay.diagnosticsByNPCID
        and Overlay.diagnosticsByNPCID[npcID] or nil
end

function Overlay.GetRelationshipChange(npcID)
    Overlay.RefreshDiagnosticsCache()
    local active = Overlay.activeRelationshipChanges
        and Overlay.activeRelationshipChanges[npcID] or nil
    if not active then return nil end
    if PNC.Core.Now()
        >= (tonumber(active.expiresAt) or 0)
    then
        Overlay.activeRelationshipChanges[npcID] = nil
        return nil
    end
    return active.value, active.count
end

function Overlay.Update()
    if not Overlay.IsVisible() then return false end
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        if PNC.Nameplates
            and PNC.Nameplates.SetFactionDebugEnabled
        then
            PNC.Nameplates.SetFactionDebugEnabled(false, false)
        end
        return false
    end
    Overlay.RefreshDiagnosticsCache()
    local now = PNC.Core.Now()
    if now - (tonumber(Overlay.lastRequestAt) or 0)
        < Internal.REQUEST_INTERVAL
    then
        return false
    end
    if PNC.Client.RequestFactionDebug then
        local snapshot = ClientState.factionDebug
        PNC.Client.RequestFactionDebug(
            Overlay.sourceFactionID
                or snapshot and snapshot.selectedFactionID
                or snapshot and snapshot.currentPlayerFactionID,
            Overlay.npcID
                or snapshot and snapshot.selectedNPCID,
            Overlay.targetFactionID
                or snapshot and snapshot.selectedTargetFactionID
        )
        Overlay.lastRequestAt = now
        return true
    end
    return false
end

return Overlay
