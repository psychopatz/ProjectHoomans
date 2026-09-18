-- Selected-entry detail projection for the animation catalog tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaAnimationTabInternal
local addDetail = Internal.addDetail
local selectorText = Internal.selectorText
local Class = ISPNCPuppetOperaAnimationTab

function Class:refreshDetails()
    if not self.details then return end
    self.details:clear()
    local entry = self:getSelectedEntry()
    if not entry then
        addDetail(self.details, "Selection", "No matching catalog entry", true)
        return
    end
    local owner = self.ownerWindow
    local model = owner and owner.model
    if not model then
        addDetail(self.details, "Selection", "Model unavailable", true)
        return
    end
    local approved = self.catalogName == "player"
        and model.IsPlayerEntryServerApproved(entry)
        or model.IsNPCEntryServerApproved(entry)
    local actorID = model.GetActorForCatalog(self.catalogName)
    local selectedActor
    for _, row in ipairs(model.GetActorRows(model.GetSnapshot()) or {}) do
        if actorID and tostring(row.id) == tostring(actorID) then
            selectedActor = row
            break
        end
    end
    addDetail(self.details, "Actor slot",
        selectedActor and selectedActor.label or "No actor slot selected",
        selectedActor == nil)
    addDetail(self.details, "Scene slot", actorID or "-", actorID == nil)
    addDetail(self.details, "Kind",
        selectedActor and selectedActor.kind or "unbound",
        selectedActor == nil or selectedActor.kind == "unbound")
    addDetail(self.details, "Binding",
        selectedActor and (selectedActor.liveName or selectedActor.bindingID)
            or "-",
        selectedActor == nil or not selectedActor.bindingID)
    addDetail(self.details, "Live ID",
        selectedActor and selectedActor.liveID or "-",
        selectedActor == nil or not selectedActor.liveID)
    if actorID then
        addDetail(self.details, "Assignment", model.GetSelectionSummary(actorID))
    end
    addDetail(self.details, "Catalog", self.catalogName)
    local capability = entry.puppetOperaCapability
    addDetail(self.details, "Capability",
        capability and capability.id or "unregistered",
        not capability or capability.scenePolicy ~= "scene_approved")
    addDetail(self.details, "Scene policy",
        capability and capability.scenePolicy or "preview_only",
        not capability or capability.scenePolicy ~= "scene_approved")
    if capability and capability.warning then
        addDetail(self.details, "Safety note", capability.warning, true)
    end
    addDetail(self.details, "State", entry.state)
    addDetail(self.details, "Source", entry.source or entry.folder)
    local route = entry.route
    if self.catalogName == "npc" then
        route = model.EntryBumpType(entry)
            and "zombie_bump -> XML" or "native clip preview only"
    end
    addDetail(self.details, "Route", route or "player_action")
    if self.catalogName == "player" and entry.bridgePath then
        addDetail(self.details, "Bridge", entry.bridgePath)
    end
    addDetail(self.details, "Node", entry.node)
    addDetail(self.details, "Clip", entry.anim or "(none)", not entry.anim)
    addDetail(self.details, "File", entry.path or entry.file)
    if self.catalogName == "player" then
        addDetail(self.details, "Action", entry.action or entry.emote or "-")
        addDetail(self.details, "Mode", entry.mode)
        addDetail(self.details, "Entry ID", model.PlayerEntryID(entry))
        addDetail(self.details, "MP policy",
            approved
                and "server-approved" or "local preview only",
            not approved)
    else
        local bump = model.EntryBumpType(entry)
        local selectors = selectorText(entry)
        addDetail(self.details, "BumpType", bump or "-", not bump)
        addDetail(self.details, "Selectors",
            selectors ~= "" and selectors or "none",
            selectors ~= "")
        addDetail(self.details, "Direct route",
            bump and (entry.puppetOperaDirect and "yes"
                or "requires selectors") or "preview only",
            not (bump and entry.puppetOperaDirect))
        addDetail(self.details, "Entry ID", model.NPCEntryID(entry))
        addDetail(self.details, "MP policy",
            approved
                and "server-approved" or "local preview only",
            not approved)
    end
    addDetail(self.details, "Playback",
        (entry.looped and "looped" or "one-shot") .. " @ "
            .. tostring(entry.speed or 1.0))
    addDetail(self.details, "Events", tostring(#(entry.events or {})))
end

return Class
