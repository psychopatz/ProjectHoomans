local Window = ISPNCScavengeWindow
if not Window then return end

local Internal = Window.Internal or {}
local UI = Internal.UI
local Layout = Internal.Layout
local tr = Internal.tr
local ScavengeUI = PNC.ScavengeUI

function ISPNCScavengeWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ScavengeUI.instance = nil
end

function ISPNCScavengeWindow:new(x, y, width, height, options)
    local o = UI.Window.new(self, x, y, width, height, options or {})
    o.resizable = true
    o.sourcePolicy = { containers = true, floorItems = true, corpses = true }
    o.expandedGroups = {}
    o.selectedEntries = {}
    o.entryById = {}
    o.debugEnabled = false
    o.nextDebugRequestAt = 0
    o.estimatedLoad = 0
    return o
end

local function getOrCreate()
    if ScavengeUI.instance then return ScavengeUI.instance end
    local spec = { width = 820, height = 600, minWidth = 700,
        minHeight = 500, maxWidth = 1050, maxHeight = 760,
        anchor = "center" }
    local bounds = Layout.ResolveWindow(spec)
    local title = tr("UI_PNC_Scavenge_Title", "Scavenging")
    local window = ISPNCScavengeWindow:new(bounds.x, bounds.y,
        bounds.width, bounds.height, {
            title = title,
            responsiveSpec = spec,
            persistenceKey = "ProjectHoomans:ScavengeWindow:v2",
            resizable = true,
        })
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    ScavengeUI.instance = window
    return window
end

function ScavengeUI.OpenSetup(npcId, context)
    local window = getOrCreate()
    window:setNPC(npcId, context)
    window:setVisible(true)
    window:bringToTop()
    PNC.Client.SendScavengeRequest("request_policy", { npcId = npcId })
    local state = PNC.Network and PNC.Network.ClientState or nil
    local active = state and state.activeScavengeSessionId
    local snapshot = active and state.scavengeSessions
        and state.scavengeSessions[active] or nil
    if snapshot then
        window:applySnapshot(snapshot)
        -- The Colony tab is the assignment editor. Preserve its current team
        -- even while showing the previous run's manifest so Start Search uses
        -- the NPCs the player just selected.
        window:setNPC(npcId, context)
    end
    return true
end

function ScavengeUI.ReceiveSnapshot(snapshot)
    local window = ScavengeUI.instance
    if window then
        window:applySnapshot(snapshot)
        window:setVisible(true)
    end
    return window ~= nil
end

