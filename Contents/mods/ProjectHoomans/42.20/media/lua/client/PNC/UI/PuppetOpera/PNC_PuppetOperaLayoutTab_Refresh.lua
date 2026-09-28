-- Model-to-widget projection for the Puppet Opera layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local Class = ISPNCPuppetOperaLayoutTab

function Class:refresh()
    if not self.model or not self.actorList then return end
    local selectedID = self.model.GetSelectedActorID()
    local snapshot = self.model.GetSnapshot()
    local actorRows = self.model.GetActorRows(snapshot)
    self.actorList:clear()
    local selectedIndex = nil
    for index, row in ipairs(actorRows) do
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

    if self.timeline then self.timeline:refresh() end
end

return Class
