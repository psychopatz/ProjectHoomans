-- Preview framing is presentation state, never an authored NPC mutation.
local Window = ISPNCNPCAuthoringEditor
local Weapon = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringWeaponPreview"

local function stowedItems(equipment, heldPrimary)
    local gear = PNC.Equipment
    if not equipment or not gear or not gear.ResolveAttachedLocation or not AttachedLocations then return nil end
    local group = AttachedLocations.getGroup("Human")
    local items, occupied = {}, {}
    for location, fullType in pairs(equipment.attached or {}) do
        if group:getLocation(location) and type(fullType) == 'string' then
            local item = gear.CreateItem(fullType)
            if item then items[location], occupied[location] = item, true end
        end
    end
    for _, hand in ipairs({ 'primaryFullType', 'secondaryFullType' }) do
        local item = (not heldPrimary or hand ~= 'primaryFullType') and equipment[hand] and gear.CreateItem(equipment[hand])
        local location = item and gear.ResolveAttachedLocation(item, nil, occupied)
        if location and group:getLocation(location) then items[location], occupied[location] = item, true end
    end
    for _ in pairs(items) do return items end
end

local function bindPreviewClick(editor, model)
    if not model or model.pncLoadoutClickBound then return end
    model.animateWhilePaused = true
    local onMouseDown, onMouseUp = model.onMouseDown, model.onMouseUp
    local downX, downY
    model.onMouseDown = function(view, x, y)
        downX, downY = x, y
        return onMouseDown(view, x, y)
    end
    model.onMouseUp = function(view, x, y)
        local click = view.mouseDown and downX and math.abs(x - downX) <= 4 and math.abs(y - downY) <= 4
        local handled = onMouseUp(view, x, y)
        if click then editor:deselectLoadoutPart() end
        return handled
    end
    model.pncLoadoutClickBound = true
end

function Window:syncPortraitView(force, resetBodyView)
    local panel, source = self.portraitPanel, self.portraitSourceSpec
    if not panel or not source then return false end
    local face = self.tabPanel and self.tabPanel:getActiveView() == self.appearanceTab
    local mode = face and 'face' or 'body'
    local loadout = self.tabPanel and self.pages and self.tabPanel:getActiveView() == self.pages.loadout
    local region = face and 'head' or loadout and self.loadoutViewRegion or 'body'
    panel:setViewRegion(region, resetBodyView, panel:getViewRegion() ~= nil)
    self.portraitMode = mode
    local spec = PNC.NPCAuthoring.Registry.Copy(source)
    spec.faceOnly, spec.includeCurrentClothing = face == true, false
    spec.key = tostring(source.key or source.id) .. ':' .. mode
    if face then
        spec.equipment = {}
        spec.appearance = spec.appearance or {}
        spec.appearance.outfit, spec.appearance.outfitItems, spec.appearance.outfitItemSpecs = nil, {}, {}
    elseif loadout then
        spec.key = spec.key .. ':loadout'
        if self.stowedPortraitKey ~= spec.key then
            local gear = PNC.Equipment
            local primary = spec.equipment and spec.equipment.primaryFullType
            local item = primary and gear and gear.CreateItem(primary)
            self.loadoutWeaponPose = Weapon.Describe(item)
            self.loadoutHandItems = self.loadoutWeaponPose and { primary = item } or nil
            self.stowedPortraitItems = stowedItems(spec.equipment, self.loadoutHandItems)
            self.stowedPortraitKey = spec.key
        end
        spec.previewStowedItems = self.stowedPortraitItems
        spec.previewWeaponPose = self.loadoutWeaponPose
        spec.previewHandItems = self.loadoutHandItems
    end
    if self.previewSpecKey ~= spec.key then
        self.nextWeaponPreviewAt, self.weaponPreviewEndsAt = nil, nil
    end
    self.portraitTarget, self.previewSpecKey = spec, spec.key
    local rendered = panel:setTarget(nil, spec, force == true)
    bindPreviewClick(self, panel.modelView)
    return rendered == true
end
function Window:wavePortrait(now)
    local panel = self.portraitPanel
    if not panel or not panel.modelView or not panel:isReallyVisible() then return end
    panel:playAnimation('greeting.wavehi', 2200)
    self.nextPreviewWaveAt = now + 12000 + ZombRand(7000)
end

function Window:update()
    if ISPanel.update then ISPanel.update(self) end
    local voice = self.appearanceTab and self.appearanceTab.voicePreview
    if voice then voice:Update() end
    local panel = self.portraitPanel
    if panel and panel.modelView and panel:isReallyVisible() and panel.setWeaponPreviewAttacking
        and self.portraitTarget and self.portraitTarget.previewWeaponPose and getTimeInMillis then
        local now = getTimeInMillis()
        if not self.nextWeaponPreviewAt then self.nextWeaponPreviewAt = now + 700 end
        if now >= self.nextWeaponPreviewAt then
            panel:setWeaponPreviewAttacking(true)
            self.weaponPreviewEndsAt = now + 900
            self.nextWeaponPreviewAt = now + 3600
        elseif self.weaponPreviewEndsAt and now >= self.weaponPreviewEndsAt then
            panel:setWeaponPreviewAttacking(false)
            self.weaponPreviewEndsAt = nil
        end
    else
        self.nextWeaponPreviewAt, self.weaponPreviewEndsAt = nil, nil
    end
    if self.portraitMode ~= 'face' or not panel or not panel.modelView
        or not panel:isReallyVisible() or not getTimeInMillis then
        self.nextPreviewWaveAt = nil
        return
    end
    local now = getTimeInMillis()
    if not self.nextPreviewWaveAt then
        self.nextPreviewWaveAt = now + 8000
    elseif now >= self.nextPreviewWaveAt and (not voice or voice.handle == 0) then
        self:wavePortrait(now)
    end
end
return Window
