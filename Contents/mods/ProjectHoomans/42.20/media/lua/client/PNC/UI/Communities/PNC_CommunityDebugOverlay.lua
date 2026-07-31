-- Read-only controller for community diagnostics rendered by NPC nameplates.

PNC = PNC or {}
PNC.CommunityDebugOverlay = PNC.CommunityDebugOverlay or {}

local Overlay = PNC.CommunityDebugOverlay
local ClientState = PNC.Network.ClientState

Overlay.lastRequestAt = Overlay.lastRequestAt or 0

function Overlay.Update(force)
    local nameplatesVisible = PNC.Nameplates
        and PNC.Nameplates.IsCommunityDebugEnabled
        and PNC.Nameplates.IsCommunityDebugEnabled()
    local mapBasesVisible = PNC.MapDisplay
        and PNC.MapDisplay.AreBasesVisible
        and PNC.MapDisplay.AreBasesVisible()
    if not nameplatesVisible and not mapBasesVisible
    then
        return false
    end
    local now = PNC.Core.Now()
    if force == true
        or now - (tonumber(Overlay.lastRequestAt) or 0)
            >= 1500
    then
        Overlay.lastRequestAt = now
        local snapshot = ClientState.communityDebug or {}
        return PNC.Client.RequestCommunityDebug(
            snapshot.selectedCommunity
                and snapshot.selectedCommunity.id,
            snapshot.selectedFactionID,
            snapshot.selectedNPC
                and snapshot.selectedNPC.id
        )
    end
    return false
end

function Overlay.GetNPCDiagnostic(npcID)
    local diagnostics = ClientState.communityDebug
        and ClientState.communityDebug.npcDiagnostics or {}
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.id == npcID then
            return diagnostic
        end
    end
    return nil
end

function Overlay.SetVisible(visible)
    if not PNC.Nameplates
        or not PNC.Nameplates.SetCommunityDebugEnabled
    then
        return false
    end
    local result = PNC.Nameplates.SetCommunityDebugEnabled(
        visible == true,
        true
    )
    if result then Overlay.Update(true) end
    return result
end

function Overlay.Toggle()
    if not PNC.Nameplates
        or not PNC.Nameplates.ToggleCommunityDebug
    then
        return false
    end
    local visible =
        PNC.Nameplates.ToggleCommunityDebug()
    if visible then Overlay.Update(true) end
    return visible
end

function Overlay.IsVisible()
    return PNC.Nameplates
        and PNC.Nameplates.IsCommunityDebugEnabled
        and PNC.Nameplates.IsCommunityDebugEnabled()
        or false
end

return Overlay
