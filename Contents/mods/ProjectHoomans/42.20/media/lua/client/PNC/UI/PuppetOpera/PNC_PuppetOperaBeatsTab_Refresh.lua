-- Model-to-widget projection for the Puppet Opera beat tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaBeatsTabInternal
local addDetail = Internal.addDetail
local Class = ISPNCPuppetOperaBeatsTab

local function hasMethod(target, name)
    return target and type(target[name]) == "function"
end

function Class:refresh()
    local model = self.model
    if not model or not self.beatList
        or not hasMethod(model, "GetSelectedBeatIndex")
        or not hasMethod(model, "GetBeatRows")
        or not hasMethod(model, "GetSelectedBeat")
    then
        return
    end
    local selectedIndex = model.GetSelectedBeatIndex()
    self.beatList:clear()
    local rows = model.GetBeatRows()
    if type(rows) ~= "table" then rows = {} end
    for index, row in ipairs(rows) do
        if type(row) == "table" then
            self.beatList:addItem(row.id, row)
            if index == selectedIndex then self.beatList.selected = index end
        end
    end
    if #self.beatList.items > 0
        and (tonumber(self.beatList.selected) or 0) < 1
    then
        self.beatList.selected = 1
    end
    local beat = model.GetSelectedBeat()
    if self.durationEntry and type(self.durationEntry.setText) == "function" then
        self.durationEntry:setText(tostring(beat and beat.durationMs or ""))
    end
    if not self.details or type(self.details.clear) ~= "function" then
        return
    end
    self.details:clear()
    if type(beat) ~= "table" then
        addDetail(self.details, "Selection", "No beat selected", true)
        return
    end
    addDetail(self.details, "Beat", beat.id)
    addDetail(self.details, "Duration", tostring(beat.durationMs) .. " ms")
    addDetail(self.details, "Synchronization",
        beat.synchronization or "arrival_and_start_barrier")
    if hasMethod(model, "GetActorRows") then
        local actors = model.GetActorRows(nil)
        if type(actors) == "table" then
            for _, actor in ipairs(actors) do
                if type(actor) == "table" then
                    local trackLabel = tostring(actor.label)
                        .. " [slot=" .. tostring(actor.id) .. "]"
                    if actor.liveName and actor.liveID then
                        trackLabel = trackLabel .. " -> "
                            .. tostring(actor.liveName) .. " ["
                            .. tostring(actor.liveID) .. "]"
                    end
                    local summary = "-"
                    if hasMethod(model, "GetSelectionSummary") then
                        summary = model.GetSelectionSummary(actor.id)
                    end
                    addDetail(self.details, "Track " .. trackLabel,
                        summary, actor.supported ~= true)
                end
            end
        end
    end
    if not hasMethod(model, "GetValidation") then
        addDetail(self.details, "MP policy", "validation unavailable", true)
        return
    end
    local schemaOK, runtimeReason = model.GetValidation()
    addDetail(self.details, "MP policy",
        not schemaOK and "invalid draft"
            or (runtimeReason and "local preview; server will reject"
                or "server-approved"),
        not schemaOK or runtimeReason ~= nil)
end

return Class
