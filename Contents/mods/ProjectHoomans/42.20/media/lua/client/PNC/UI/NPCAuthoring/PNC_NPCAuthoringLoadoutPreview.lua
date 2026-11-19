-- Capture only visited picker items. Preview and confirmation share that exact
-- native visual choice, while preparation remains a read-only draft transaction.
local Window = ISPNCNPCAuthoringEditor
local Weapon = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringWeaponPreview"
local Catalog = PNC.NPCAuthoringCatalog
local Variants = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringItemVariants"
local function slotKey(id)
    return tostring(id):gsub('^.*:', ''):lower()
end

local function showSelectedVisual(portrait, slot, selection)
    local equipment = PNC.Equipment
    if not equipment.VisualStateFromItemState or not portrait.equipment then return end
    local item = selection.spec
    local visual = equipment.VisualStateFromItemState(item.itemState, item.type)
    if not visual then return end
    local loadout = portrait.equipment
    loadout.worn, loadout.wornVisuals = loadout.worn or {}, loadout.wornVisuals or {}
    local location = slot.id
    for key in pairs(loadout.worn) do
        if slotKey(key) == slotKey(location) then location = key; break end
    end
    loadout.worn[location] = item.type
    loadout.wornVisuals[location] = visual
end

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
            local native, reason = Catalog.Create(item.id, slot.kind == 'worn' and slot.id or nil)
            if not native then return nil, reason end
            local spec
            spec, reason = PNC.Inventory.CaptureNativeItem(native)
            if not spec then return nil, reason end
            local baseline = self.previewDraft and self.previewDraft.runtimeRecord
            for _, worn in pairs(baseline and baseline.inventory and baseline.inventory.items or {}) do
                if slot.kind == 'worn' and worn.wornSlot and worn.type == spec.type and
                    slotKey(worn.wornSlot) == slotKey(slot.id) then
                    local stored = PNC.Equipment.VisualStateFromItemState(worn.itemState, spec.type)
                    if stored then
                        PNC.Equipment.StoreVisualStateInItemState(spec, stored)
                        PNC.Equipment.Internal.applyItemVisualState(native, stored)
                    end
                    break
                end
            end
            local original = PNC.Equipment.VisualStateFromItemState
                and PNC.Equipment.VisualStateFromItemState(spec.itemState, spec.type) or {}
            selections[item.id] = { native = native, spec = spec, original = original }
            count = count + 1
        end
        return selections[item.id]
    end
    local function variants(item)
        if allowed and not allowed[item.id] then return {} end
        local selection = capture(item)
        if not selection then return {} end
        if not selection.native.getClothingItem then return {} end
        selection.decals = selection.decals or Variants.Decals(selection.native, selection.original)
        return Variants.Describe(selection.native,
            PNC.Equipment.VisualStateFromItemState(selection.spec.itemState, selection.spec.type),
            selection.decals)
    end
    local function changeVariant(item, field, value)
        local selection = selections[item.id]
        if not selection then return end
        Variants.Apply(selection.native, selection.spec, selection.original, field, value)
        selection.revision = (selection.revision or 0) + 1
        portraits[item.id] = nil
    end
    local function beginVariantEdit(item)
        local selection = capture(item)
        if not selection then return nil end
        local copy = PNC.NPCAuthoring.Registry.Copy
        local previousState = copy(selection.spec.itemState)
        return function(accepted)
            if accepted then return end
            selection.spec.itemState = previousState
            local equipment = PNC.Equipment
            local original = equipment.VisualStateFromItemState(previousState, selection.spec.type)
            if original then equipment.Internal.applyItemVisualState(selection.native, original) end
            selection.revision = (selection.revision or 0) + 1
            portraits[item.id] = nil
        end
    end
    local function preview(item)
        if allowed and not allowed[item.id] then return nil end
        local selection, reason = capture(item)
        if not selection then return nil, nil, 1, reason end
        if not portraits[item.id] then
            local candidate
            candidate, reason = self:buildLoadoutCandidate(slot, item.id, 1, 'root', selection, true)
            if not candidate then return nil, nil, 1, reason end
            local fitReason = reason
            local model = Window.Internal.Model
            local draft = model.BuildPreviewDraft(candidate, self.previewDraft)
            if self.previewDraft and self.previewDraft.runtimeRecord then
                draft.runtimeRecord = PNC.NPCAuthoring.Registry.Copy(self.previewDraft.runtimeRecord)
            end
            local record
            record, reason = model.EnsureRuntimeRecord(draft)
            if not record then return nil, nil, 1, reason end
            local spec = model.BuildPortraitSpec(draft, record)
            if spec and slot.kind == 'held' then
                spec.previewHandItems = { [slot.id] = selection.native }
                spec.previewWeaponPose = slot.weapon and Weapon.Describe(selection.native) or nil
            elseif spec and slot.kind == 'worn' then
                showSelectedVisual(spec, slot, selection)
            end
            if spec then
                spec.key = tostring(spec.key or '') .. ':item:' .. slot.id .. ':' .. item.id
                    .. ':' .. tostring(selection.revision or 0)
            end
            portraits[item.id] = { spec = spec, reason = fitReason }
        end
        local portrait = portraits[item.id]
        return portrait.spec, item.label, 1, portrait.reason
    end
    local function choose(item, quantity, destination)
        local selection, reason = capture(item)
        if not selection then return false, reason end
        return self:applyLoadout(slot, item.id, quantity, destination, selection)
    end
    return preview, choose, refresh, variants, changeVariant, beginVariantEdit
end
return Window
