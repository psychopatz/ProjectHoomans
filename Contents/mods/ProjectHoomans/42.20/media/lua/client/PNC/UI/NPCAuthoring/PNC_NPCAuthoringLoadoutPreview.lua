-- Capture only visited picker items. Preview and confirmation share that exact
-- native visual choice, while preparation remains a read-only draft transaction.
local Window = ISPNCNPCAuthoringEditor
local Catalog = PNC.NPCAuthoringCatalog
function Window:loadoutPickerCallbacks(slot, allowed)
    local selections, portraits, count, source = {}, {}, 0, self.draft
    local function refresh(newAllowed)
        if newAllowed then allowed = newAllowed end
        selections, portraits, count, source = {}, {}, 0, self.draft
    end
    local function capture(item)
        if source ~= self.draft then refresh() end
        if not selections[item.id] then
            if count >= 32 then refresh() end
            local native, reason = Catalog.Create(item.id)
            if not native then return nil, reason end
            local spec
            spec, reason = PNC.Inventory.CaptureNativeItem(native)
            if not spec then return nil, reason end
            selections[item.id] = { native = native, spec = spec }
            count = count + 1
        end
        return selections[item.id]
    end
    local function preview(item)
        if allowed and not allowed[item.id] then return nil end
        local selection, reason = capture(item)
        if not selection then return nil, nil, 1, reason end
        if not portraits[item.id] then
            local candidate
            candidate, reason = self:buildLoadoutCandidate(slot, item.id, 1, 'root', selection)
            if not candidate then return nil, nil, 1, reason end
            local model = Window.Internal.Model
            local draft = model.BuildPreviewDraft(candidate)
            local record
            record, reason = model.EnsureRuntimeRecord(draft, true)
            if not record then return nil, nil, 1, reason end
            portraits[item.id] = model.BuildPortraitSpec(draft)
        end
        return portraits[item.id], item.label, 1
    end
    local function choose(item, quantity, destination)
        local selection, reason = capture(item)
        if not selection then return false, reason end
        return self:applyLoadout(slot, item.id, quantity, destination, selection)
    end
    return preview, choose, refresh
end
return Window
