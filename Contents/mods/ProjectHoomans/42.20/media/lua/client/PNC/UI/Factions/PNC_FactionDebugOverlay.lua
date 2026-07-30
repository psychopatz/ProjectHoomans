-- Embedded diplomacy dashboard plus the controller for the guarded
-- per-NPC faction world overlay.

require "ISUI/ISUIElement"
require "PNC/UI/Factions/PNC_FactionDebugModel"

PNC = PNC or {}
PNC.FactionDebugOverlay = PNC.FactionDebugOverlay or {}

local Overlay = PNC.FactionDebugOverlay
local Model = PNC.FactionDebugModel
local ClientState = PNC.Network.ClientState

local WIDTH = 430
local HEIGHT = 492
local REQUEST_INTERVAL = 1000
local RELATIONSHIP_CHANGE_VISIBLE_MS = 12000

local COLORS = {
    background = { r = 0.025, g = 0.035, b = 0.045 },
    panel = { r = 0.065, g = 0.08, b = 0.095 },
    border = { r = 0.22, g = 0.66, b = 0.76 },
    text = { r = 0.90, g = 0.94, b = 0.96 },
    muted = { r = 0.56, g = 0.64, b = 0.69 },
    success = { r = 0.25, g = 0.78, b = 0.43 },
    warning = { r = 0.94, g = 0.67, b = 0.22 },
    danger = { r = 0.94, g = 0.25, b = 0.22 },
    neutral = { r = 0.35, g = 0.62, b = 0.80 },
}

local function tr(key)
    return getText and getText(key) or key
end

local function shorten(value, maximum)
    return Model.ShortenID(value, maximum)
end

local function stateTone(relation, generatedAt)
    if relation.atWar then return COLORS.danger end
    if relation.allied then return COLORS.success end
    if relation.truceUntil > (tonumber(generatedAt) or 0) then
        return COLORS.warning
    end
    return COLORS.neutral
end

local function statusText(relation, generatedAt)
    if relation.atWar then
        return tr("UI_PNC_FactionOverlayWar")
    end
    if relation.allied then
        return tr("UI_PNC_FactionOverlayAllied")
    end
    local remaining = math.max(
        0,
        (tonumber(relation.truceUntil) or 0)
            - (tonumber(generatedAt) or 0)
    )
    if remaining > 0 then
        return tr("UI_PNC_FactionOverlayTruce")
            .. " " .. string.format("%.1fh", remaining)
    end
    return string.upper(tostring(relation.state or "unknown"))
end

ISPNCFactionDebugOverlay =
    ISUIElement:derive("ISPNCFactionDebugOverlay")

function ISPNCFactionDebugOverlay:initialise()
    ISUIElement.initialise(self)
end

function ISPNCFactionDebugOverlay:drawLabel(
    label,
    value,
    x,
    y,
    valueColor
)
    local muted = COLORS.muted
    local color = valueColor or COLORS.text
    self:drawText(
        tostring(label), x, y,
        muted.r, muted.g, muted.b, 1,
        UIFont.Small
    )
    self:drawText(
        tostring(value), x + 122, y,
        color.r, color.g, color.b, 1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:drawBadge(
    label,
    x,
    y,
    width,
    color
)
    self:drawRect(
        x, y, width, 22,
        0.84, color.r, color.g, color.b
    )
    self:drawRectBorder(
        x, y, width, 22,
        1, color.r, color.g, color.b
    )
    self:drawTextCentre(
        tostring(label),
        x + width / 2,
        y + 4,
        1, 1, 1, 1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:drawMetric(
    label,
    value,
    minimum,
    maximum,
    x,
    y,
    width,
    color
)
    local number = tonumber(value) or 0
    local span = math.max(1, maximum - minimum)
    local ratio = math.max(
        0, math.min(1, (number - minimum) / span)
    )
    self:drawText(
        tostring(label),
        x, y,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tostring(math.floor(number * 10 + 0.5) / 10),
        x + width,
        y,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    local barY = y + 15
    self:drawRect(
        x, barY, width, 8,
        0.90, 0.08, 0.09, 0.10
    )
    self:drawRect(
        x + 1, barY + 1,
        math.max(0, (width - 2) * ratio), 6,
        0.94, color.r, color.g, color.b
    )
    self:drawRectBorder(
        x, barY, width, 8,
        0.80, 0.32, 0.38, 0.42
    )
end

function ISPNCFactionDebugOverlay:drawPanel(x, y, width, height)
    self:drawRect(
        x, y, width, height,
        0.90,
        COLORS.panel.r,
        COLORS.panel.g,
        COLORS.panel.b
    )
    self:drawRectBorder(
        x, y, width, height,
        0.70, 0.18, 0.25, 0.29
    )
end

function ISPNCFactionDebugOverlay:renderWaiting(dashboard)
    self:drawTextCentre(
        tr("UI_PNC_FactionOverlayWaiting"),
        self.width / 2,
        70,
        COLORS.warning.r,
        COLORS.warning.g,
        COLORS.warning.b,
        1,
        UIFont.Medium
    )
    self:drawTextCentre(
        tostring(dashboard.status or "waiting"),
        self.width / 2,
        98,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
end

function ISPNCFactionDebugOverlay:render()
    ISUIElement.render(self)
    local dashboard = Model.BuildDashboard(
        ClientState.factionDebug,
        ClientState.factionDebugAuthorized,
        ClientState.factionDebugReason
    )
    self:drawRect(
        0, 0, self.width, self.height,
        0.94,
        COLORS.background.r,
        COLORS.background.g,
        COLORS.background.b
    )
    self:drawRectBorder(
        0, 0, self.width, self.height,
        0.95,
        COLORS.border.r,
        COLORS.border.g,
        COLORS.border.b
    )
    self:drawRect(
        0, 0, self.width, 30,
        0.98, 0.07, 0.18, 0.22
    )
    self:drawText(
        tr("UI_PNC_FactionOverlayTitle"),
        12, 7,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tr("UI_PNC_FactionOverlayReadOnly"),
        self.width - 12,
        7,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    if dashboard.status ~= "ready" then
        self:renderWaiting(dashboard)
        return
    end

    local source = dashboard.source
    local target = dashboard.target
    local relation = dashboard.forward
    local tone = stateTone(relation, dashboard.generatedAt)
    local contentX = 12
    local contentWidth = self.width - 24

    self:drawPanel(contentX, 40, contentWidth, 62)
    self:drawText(
        shorten(source.name, 28),
        22, 48,
        COLORS.success.r,
        COLORS.success.g,
        COLORS.success.b,
        1,
        UIFont.Medium
    )
    self:drawText(
        tr("UI_PNC_FactionOverlayVersus"),
        22, 72,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    self:drawText(
        target and shorten(target.name, 28)
            or tr("UI_PNC_FactionOverlayNoTarget"),
        48, 72,
        target and COLORS.warning.r or COLORS.muted.r,
        target and COLORS.warning.g or COLORS.muted.g,
        target and COLORS.warning.b or COLORS.muted.b,
        1,
        UIFont.Small
    )
    if target then
        self:drawBadge(
            statusText(relation, dashboard.generatedAt),
            self.width - 142, 56, 118, tone
        )
    end

    self:drawPanel(contentX, 110, contentWidth, 116)
    self:drawText(
        tr("UI_PNC_FactionOverlayDiplomacy"),
        22, 117,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    local half = math.floor((contentWidth - 34) / 2)
    self:drawMetric(
        tr("UI_PNC_FactionOverlayStanding"),
        relation.standing, -100, 100,
        22, 139, half,
        relation.standing < 0
            and COLORS.danger or COLORS.success
    )
    self:drawMetric(
        tr("UI_PNC_FactionOverlayTrust"),
        relation.trust, -100, 100,
        32 + half, 139, half,
        relation.trust < 0
            and COLORS.danger or COLORS.success
    )
    self:drawMetric(
        tr("UI_PNC_FactionOverlayFear"),
        relation.fear, 0, 100,
        22, 181, half,
        COLORS.warning
    )
    self:drawMetric(
        tr("UI_PNC_FactionOverlayGrievance"),
        relation.grievance, 0, 100,
        32 + half, 181, half,
        COLORS.danger
    )

    self:drawPanel(contentX, 234, contentWidth, 70)
    self:drawText(
        tr("UI_PNC_FactionOverlayResolvedIntent"),
        22, 242,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    local intentTone = dashboard.intent.attackAllowed
        and COLORS.danger or COLORS.success
    self:drawBadge(
        string.upper(dashboard.intent.value),
        self.width - 142, 241, 118, intentTone
    )
    self:drawLabel(
        tr("UI_PNC_FactionOverlayRule"),
        shorten(dashboard.intent.rule, 34),
        22, 268
    )
    self:drawTextRight(
        "A=" .. tostring(dashboard.intent.attackAllowed)
            .. " P=" .. tostring(dashboard.intent.pursueAllowed)
            .. " C=" .. tostring(dashboard.intent.commandable),
        self.width - 22, 285,
        intentTone.r, intentTone.g, intentTone.b, 1,
        UIFont.Small
    )

    self:drawPanel(contentX, 312, contentWidth, 76)
    self:drawText(
        tr("UI_PNC_FactionOverlayNPC"),
        22, 320,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    if dashboard.npc then
        local affiliation = dashboard.npc.affiliation or {}
        self:drawLabel(
            tr("UI_PNC_FactionOverlaySelected"),
            shorten(dashboard.npc.name, 30),
            22, 341
        )
        self:drawLabel(
            tr("UI_PNC_FactionOverlayAffiliation"),
            tostring(affiliation.role or "none")
                .. " / "
                .. tostring(affiliation.rank or "none"),
            22, 360
        )
        self:drawTextRight(
            "r" .. tostring(dashboard.npc.recordRevision)
                .. " / p"
                .. tostring(dashboard.npc.presenceRevision),
            self.width - 22, 360,
            COLORS.muted.r,
            COLORS.muted.g,
            COLORS.muted.b,
            1,
            UIFont.Small
        )
    else
        self:drawText(
            tr("UI_PNC_FactionOverlayNoNPC"),
            22, 347,
            COLORS.muted.r,
            COLORS.muted.g,
            COLORS.muted.b,
            1,
            UIFont.Small
        )
    end

    self:drawPanel(contentX, 396, contentWidth, 62)
    self:drawText(
        tr("UI_PNC_FactionOverlayDiagnostics"),
        22, 404,
        COLORS.text.r,
        COLORS.text.g,
        COLORS.text.b,
        1,
        UIFont.Small
    )
    self:drawLabel(
        tr("UI_PNC_FactionOverlayEpisodes"),
        dashboard.activeEpisodeCount,
        22, 426,
        dashboard.activeEpisodeCount > 0
            and COLORS.warning or COLORS.success
    )
    self:drawLabel(
        tr("UI_PNC_FactionOverlayReconcile"),
        dashboard.reconciliationJobCount,
        190, 426,
        dashboard.reconciliationJobCount > 0
            and COLORS.warning or COLORS.success
    )
    local validationText =
        tr("UI_PNC_FactionOverlayNotRun")
    local validationTone = COLORS.muted
    if dashboard.validation then
        validationText = dashboard.validation.ok
            and "PASS" or "FAIL"
        validationTone = dashboard.validation.ok
            and COLORS.success or COLORS.danger
    end
    self:drawText(
        tr("UI_PNC_FactionOverlayInvariant")
            .. ": " .. validationText,
        22, 446,
        validationTone.r,
        validationTone.g,
        validationTone.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tr("UI_PNC_FactionOverlayTelemetry")
            .. " " .. tostring(dashboard.telemetry.count)
            .. "/" .. tostring(dashboard.telemetry.maximum),
        self.width - 22, 446,
        dashboard.telemetry.enabled
            and COLORS.success.r or COLORS.muted.r,
        dashboard.telemetry.enabled
            and COLORS.success.g or COLORS.muted.g,
        dashboard.telemetry.enabled
            and COLORS.success.b or COLORS.muted.b,
        1,
        UIFont.Small
    )

    local latest = dashboard.telemetry.entries[
        #dashboard.telemetry.entries
    ]
    self:drawText(
        latest and (
            "#" .. tostring(latest.sequence)
                .. " " .. tostring(latest.category)
                .. " / " .. tostring(latest.result)
        ) or tr("UI_PNC_FactionOverlayNoTelemetry"),
        14, 470,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        "F" .. tostring(source.revision)
            .. " R" .. tostring(relation.revision)
            .. " G" .. tostring(dashboard.registryRevision),
        self.width - 14, 470,
        COLORS.muted.r,
        COLORS.muted.g,
        COLORS.muted.b,
        1,
        UIFont.Small
    )
end

local function firstDistinctFaction(snapshot, sourceID)
    for _, faction in ipairs(snapshot and snapshot.factions or {}) do
        if faction.id ~= sourceID then return faction.id end
    end
    return nil
end

local function firstNPCForFaction(snapshot, factionID)
    for _, npc in ipairs(snapshot and snapshot.roster or {}) do
        local affiliation = npc.affiliation or {}
        if affiliation.factionID == factionID then
            return npc.id
        end
    end
    local first = snapshot and snapshot.roster
        and snapshot.roster[1] or nil
    return first and first.id or nil
end

function ISPNCFactionDebugOverlay:resolveSelection()
    local snapshot = ClientState.factionDebug
    local sourceID = self.sourceFactionID
        or snapshot and snapshot.selectedFactionID
        or snapshot and snapshot.currentPlayerFactionID
        or snapshot and snapshot.factions
            and snapshot.factions[1]
            and snapshot.factions[1].id
    local targetID = self.targetFactionID
        or snapshot and snapshot.selectedTargetFactionID
    if targetID == sourceID then targetID = nil end
    targetID = targetID
        or firstDistinctFaction(snapshot, sourceID)
    local npcID = self.npcID
        or snapshot and snapshot.selectedNPCID
        or firstNPCForFaction(snapshot, sourceID)
    self.sourceFactionID = sourceID
    self.targetFactionID = targetID
    self.npcID = npcID
end

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

function ISPNCFactionDebugOverlay:new(
    x,
    y,
    width,
    height,
    embedded
)
    local screenWidth = getCore and getCore()
        and getCore():getScreenWidth() or 1280
    local object = ISUIElement:new(
        x or math.max(8, screenWidth - WIDTH - 18),
        y or 54,
        width or WIDTH,
        height or HEIGHT
    )
    setmetatable(object, self)
    self.__index = self
    object.embedded = embedded == true
    object:setCapture(false)
    return object
end

function Overlay.IsVisible()
    return PNC.Nameplates
        and PNC.Nameplates.IsFactionDebugEnabled
        and PNC.Nameplates.IsFactionDebugEnabled()
        or false
end

function Overlay.SetSelection(sourceFactionID, targetFactionID, npcID)
    Overlay.sourceFactionID = sourceFactionID
    Overlay.targetFactionID = targetFactionID
    Overlay.npcID = npcID
    Overlay.lastRequestAt = 0
    if Overlay.IsVisible() then Overlay.Update() end
end

function Overlay.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if PNC.Nameplates
        and PNC.Nameplates.SetFactionDebugEnabled
    then
        PNC.Nameplates.SetFactionDebugEnabled(true, true)
        Overlay.lastRequestAt = 0
        Overlay.Update()
        return true
    end
    return nil
end

function Overlay.Close()
    if PNC.Nameplates
        and PNC.Nameplates.SetFactionDebugEnabled
    then
        PNC.Nameplates.SetFactionDebugEnabled(false, true)
    end
end

function Overlay.Toggle()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return false
    end
    if PNC.Nameplates
        and PNC.Nameplates.ToggleFactionDebug
    then
        local enabled = PNC.Nameplates.ToggleFactionDebug()
        Overlay.lastRequestAt = 0
        if enabled then Overlay.Update() end
        return enabled
    end
    return false
end

function Overlay.NewDashboard(x, y, width, height)
    local dashboard = ISPNCFactionDebugOverlay:new(
        x or 0,
        y or 0,
        width or WIDTH,
        height or HEIGHT,
        true
    )
    dashboard:initialise()
    return dashboard
end

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
        < REQUEST_INTERVAL
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
