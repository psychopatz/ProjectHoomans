-- Input routing for the Puppet Opera beat list.

PNC = PNC or {}

local Class = ISPNCPuppetOperaBeatsTab

function Class:onBeatListMouseDown(list, x, y)
    if ISScrollingListBox
        and type(ISScrollingListBox.onMouseDown) == "function"
    then
        ISScrollingListBox.onMouseDown(list, x, y)
    end
    local selected = list and type(list.getItem) == "function"
        and list:getItem() or nil
    local model = self.model
    if not selected or not selected.index or not model
        or type(model.SelectBeat) ~= "function"
    then
        return false
    end
    model.SelectBeat(selected.index)
    self:refresh()
    local owner = self.ownerWindow
    if owner and type(owner.refreshViews) == "function" then
        owner:refreshViews()
    end
    return true
end

return Class
