local Window = ISPNCScavengeWindow
if not Window then return end

local Internal = Window.Internal or {}
local Controller = Internal.Controller
local ScavengeModel = Internal.ScavengeModel

local function selectedIds(window, autoOnly)
    return ScavengeModel.SelectableEntryIDs(
        window.snapshot and window.snapshot.manifest or {},
        window.selectedEntries, autoOnly)
end

function Window:onAction(button)
    local action = button.internal
    if action == "containers" or action == "floorItems"
        or action == "corpses"
    then
        self.sourcePolicy[action] = self.sourcePolicy[action] ~= true
        self:updateToggleTitles()
        self:rebuildManifest()
        return
    end
    if action == "search" then
        local stopping = self.searchButton.getToggleState
            and self.searchButton:getToggleState()
            or Controller.IsSearchActive(self.snapshot)
        local ok, reason
        if stopping then
            ok, reason = Controller.StopSearch(self.snapshot, self.npcId)
        else
            ok, reason = Controller.StartSearch({
                npcId = self.npcId, npcIds = self.npcIds,
                radius = PNC.Const.SCAVENGE_DEFAULT_RADIUS,
                sourcePolicy = self.sourcePolicy,
            })
        end
        if ok == true then self:updateSearchControl(not stopping) end
        if ok ~= true then self.lastFailure = reason or "search_failed" end
        return ok, reason
    end
    if action == "take_all" then
        local ids = ScavengeModel.AllAvailableEntryIDs(
            self.snapshot and self.snapshot.manifest)
        if #ids < 1 then self.lastFailure = "selection_empty"; return false end
        return PNC.Client.SendScavengeRequest("queue_multiple", {
            sessionId = self.snapshot and self.snapshot.sessionId,
            revision = self.snapshot and self.snapshot.revision,
            entryIds = ids,
        })
    end
    if action == "take_selected" or action == "take_auto" then
        local ids = selectedIds(self, action == "take_auto")
        if #ids < 1 then self.lastFailure = "selection_empty"; return false end
        return PNC.Client.SendScavengeRequest("queue_multiple", {
            sessionId = self.snapshot and self.snapshot.sessionId,
            revision = self.snapshot and self.snapshot.revision,
            entryIds = ids,
        })
    end
    if action == "disband" then
        return Controller.Disband(self.snapshot, self.npcId)
    end
    if action == "debug_dump" then
        self.debugEnabled = not self.debugEnabled
        self.debugButton:setTitle(self.debugEnabled and "Live Debug: ON"
            or "Live Debug: OFF")
        self.nextDebugRequestAt = 0
        self:requestResponsiveLayout(true)
        self:rebuildStatus()
        if not self.debugEnabled then return true end
        return PNC.Client.SendScavengeRequest("debug_dump", {
            sessionId = self.snapshot and self.snapshot.sessionId,
        })
    end
    if action == "close" then self:close(); return true end
end
