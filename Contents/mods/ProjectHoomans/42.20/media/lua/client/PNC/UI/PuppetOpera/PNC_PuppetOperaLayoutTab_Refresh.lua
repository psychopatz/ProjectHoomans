-- Model-to-widget projection for the Puppet Opera layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local addDetail = Internal.addDetail
local tr = Internal.tr
local Class = ISPNCPuppetOperaLayoutTab

function Class:refresh()
    if not self.model or not self.actorList then return end
    local selectedID = self.model.GetSelectedActorID()
    self.actorList:clear()
    local selectedIndex = nil
    for index, row in ipairs(self.model.GetActorRows(
        self.model.GetSnapshot()
    )) do
        self.actorList:addItem(row.id, row)
        if tostring(row.id) == tostring(selectedID) then
            selectedIndex = index
        end
    end
    self.actorList.selected = selectedIndex or 0

    if not self.liveDragPending then
        self.liveList:clear()
        local selectedLiveIndex = nil
        for index, row in ipairs(self.model.GetLiveActorRows(
            self.model.GetActorDiscoveryRadius()
        )) do
            self.liveList:addItem(row.id, row)
            if tostring(row.id) == tostring(
                self.model.GetPendingLiveActorID()
                    or self.model.GetSelectedNPCID()
                    or ""
            ) then
                selectedLiveIndex = index
            end
        end
        self.liveList.selected = selectedLiveIndex or 0
    end

    self.details:clear()
    local selected
    for _, row in ipairs(self.model.GetActorRows(
        self.model.GetSnapshot()
    )) do
        if tostring(row.id) == tostring(selectedID) then selected = row break end
    end
    if not selected then
        addDetail(self.details, "Selection", tr(
            "UI_PNC_PuppetOpera_NoActorSelected", "No actor slot selected"), true)
    else
        addDetail(self.details, "Actor", selected.label)
        addDetail(self.details, "Scene slot", selected.id)
        addDetail(self.details, "Kind", selected.kind or "unbound")
        addDetail(self.details, "Allowed kinds",
            table.concat(selected.allowedKinds or {}, ", "))
        addDetail(self.details, "Anchor", selected.anchor)
        addDetail(self.details, "Binding", selected.bindingID or tr(
            "UI_PNC_PuppetOpera_Unassigned", "unassigned"),
            not selected.bindingID)
        if selected.liveID then
            addDetail(self.details, "Live actor", selected.liveName or "-")
            addDetail(self.details, "Live ID", selected.liveID)
        end
        for _, gridRow in ipairs(self.model.GetGridActors()) do
            if gridRow.id == selected.id then
                addDetail(self.details, "Relative tile",
                    "right=" .. tostring(gridRow.right)
                    .. " forward=" .. tostring(gridRow.forward)
                    .. " z=" .. tostring(gridRow.z))
                addDetail(self.details, "Faces", gridRow.faceTarget)
                break
            end
        end
        addDetail(self.details, "Selected beat",
            tostring(self.model.GetSelectedBeatIndex()))
        addDetail(self.details, "Assigned track",
            self.model.GetSelectionSummary(selected.id))
        if selected.kind == "nearby_live_npc" and selected.bindingID
            and self.model.GetLiveActorReadiness
        then
            local readiness = self.model.GetLiveActorReadiness(
                selected.bindingID
            )
            if readiness then
                addDetail(self.details, "Live readiness",
                    readiness.ready and "ready" or "blocked",
                    readiness.ready ~= true)
                addDetail(self.details, "Action state",
                    readiness.actionState or "-")
                addDetail(self.details, "Action context",
                    readiness.actionContextState or "-")
                addDetail(self.details, "Current owner",
                    readiness.owner or "-")
                addDetail(self.details, "Override",
                    readiness.suspendable
                        and ("suspendable:"
                            .. tostring(readiness.overrideOwnerKind or "idle"))
                        or "none")
                addDetail(self.details, "Readiness reason",
                    readiness.reasonDetail or readiness.reason or "ready",
                    readiness.ready ~= true)
            end
        end
    end
    addDetail(self.details, "Placement", tr(
        "UI_PNC_PuppetOpera_PlacementHint",
        "Drag a live actor onto an empty tile"))
    addDetail(self.details, "Runtime safety", tr(
        "UI_PNC_PuppetOpera_RuntimeSafety",
        "No teleport; server derives world targets"))
end

return Class
