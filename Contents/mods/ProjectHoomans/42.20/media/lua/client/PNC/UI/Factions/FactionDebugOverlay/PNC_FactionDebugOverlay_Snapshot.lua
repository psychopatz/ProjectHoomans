-- Snapshot polling and screen-position maintenance for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local ClientState = Internal.ClientState
local REQUEST_INTERVAL = Internal.REQUEST_INTERVAL

function ISPNCFactionDebugOverlay:requestSnapshot()
    self:resolveSelection()
    if PNC.Client and PNC.Client.RequestFactionDebug then
        PNC.Client.RequestFactionDebug(
            self.sourceFactionID,
            self.npcID,
            self.targetFactionID
        )
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCFactionDebugOverlay:prerender()
    if self.embedded == true then return end
    if PNC.Client and PNC.Client.CanUseDebug
        and not PNC.Client.CanUseDebug()
    then
        Overlay.Close()
        return
    end
    local screenWidth = getCore and getCore()
        and getCore():getScreenWidth() or 1280
    self:setX(math.max(8, screenWidth - self.width - 18))
    self:setY(54)
    local snapshot = ClientState.factionDebug
    if snapshot and snapshot.selectedFactionID then
        self.sourceFactionID = snapshot.selectedFactionID
        self.targetFactionID =
            snapshot.selectedTargetFactionID
        self.npcID = snapshot.selectedNPCID
    end
    local now = PNC.Core.Now()
    local needsInitialSelection = snapshot
        and not snapshot.selectedFactionID
        and snapshot.factions
        and snapshot.factions[1] ~= nil
        and self.sourceFactionID == nil
    if needsInitialSelection
        or now - (tonumber(self.lastRequestAt) or 0)
        >= REQUEST_INTERVAL
    then
        self:requestSnapshot()
    end
end

return Overlay

