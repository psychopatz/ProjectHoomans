local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local Appearance = Internal.Appearance
local tr = Internal.tr
local copy = Internal.copy
local comboData = Internal.comboData
local runtimeItemFor = Internal.runtimeItemFor
local conflictWithDraft = Internal.conflictWithDraft
local skinTextureForTone = Internal.skinTextureForTone

function ISPNCUniqueNPCAppearanceWindow:policy(location)
    local appearance = Appearance and Appearance.Normalize
        and Appearance.Normalize(self.draft and self.draft.appearance) or {}
    return appearance.slots and appearance.slots[location]
        or { mode = "random" }
end


function ISPNCUniqueNPCAppearanceWindow:markChanged()
    self.draft.appearanceAuthored = self.draft.appearanceAuthored or {}
    self.draft.appearanceAuthored.appearance = true
    self.draft._dirty = true
    if self.parentEditor and self.parentEditor.onAppearanceChanged then
        self.parentEditor:onAppearanceChanged()
    end
end

function ISPNCUniqueNPCAppearanceWindow:onPolicyChanged(combo)
    local location = combo and combo.bodyLocation
    if not location then return end
    local mode = comboData(combo) or "random"
    local appearance = Appearance.Normalize(self.draft.appearance)
    local previous = appearance.slots[location]
    local spec = { mode = mode }
    if mode == "item" then
        local item = runtimeItemFor(self.draft, location)
        local currentType = previous and previous.type
            or item and item.type
        spec.type = currentType
        spec.wornSlot = location
        spec.itemState = item and copy(item.itemState)
            or previous and copy(previous.itemState) or nil
        if not spec.type then
            mode = "none"
            spec.mode = mode
        end
    end
    if mode == "item" then
        local conflict = conflictWithDraft(self, location)
        if conflict then
            if self.parentEditor and self.parentEditor.setStatus then
                self.parentEditor:setStatus(
                    tr("UI_PNC_UniqueNPCEditor_ClothingConflict",
                        "Clothing conflicts with ") .. conflict)
            end
            self:syncFromDraft()
            return
        end
    end
    appearance.slots[location] = spec
    if mode == "item" or mode == "none" then
        -- A per-slot decision is more specific than a full named outfit.
        -- Keep the saved definition unambiguous and prevent the native preset
        -- from reintroducing clothing the author removed.
        appearance.outfit = { mode = "none" }
    end
    self.draft.appearance = appearance
    self:syncFromDraft()
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onItemChanged(combo)
    local location = combo and combo.bodyLocation
    local fullType = comboData(combo)
    if not location or not fullType then return end
    local conflict = conflictWithDraft(self, location)
    if conflict then
        if self.parentEditor and self.parentEditor.setStatus then
            self.parentEditor:setStatus(
                tr("UI_PNC_UniqueNPCEditor_ClothingConflict",
                    "Clothing conflicts with ") .. conflict)
        end
        self:syncFromDraft()
        return
    end
    local appearance = Appearance.Normalize(self.draft.appearance)
    local previous = appearance.slots[location] or {}
    local item = runtimeItemFor(self.draft, location)
    appearance.slots[location] = {
        mode = "item",
        type = fullType,
        wornSlot = location,
        itemState = item and item.type == fullType
            and copy(item.itemState) or copy(previous.itemState),
    }
    appearance.outfit = { mode = "none" }
    self.draft.appearance = appearance
    self:syncFromDraft()
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onOutfitChanged(combo)
    local value = comboData(combo) or "random"
    local appearance = Appearance.Normalize(self.draft.appearance)
    if string.sub(tostring(value), 1, 6) == "named:" then
        appearance.outfit = { mode = "item",
            id = string.sub(tostring(value), 7) }
    else
        appearance.outfit = { mode = tostring(value) }
    end
    self.draft.appearance = appearance
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:setVoiceDraft(profile)
    if not profile then return end
    self.draft.identity = self.draft.identity or { survivor = {} }
    self.draft.identity.survivor = self.draft.identity.survivor or {}
    self.draft.identity.survivor.voice = profile.prefix
    self.draft.identity.survivor.voicePrefix = profile.prefix
    self.draft.identity.survivor.voiceType = profile.voiceType
    self.draft.identity.survivor.voicePitch = profile.pitch
    local appearance = Appearance.Normalize(self.draft.appearance)
    appearance.voice = {
        mode = "item",
        prefix = profile.prefix,
        type = profile.voiceType,
        pitch = profile.pitch,
    }
    self.draft.appearance = appearance
end

function ISPNCUniqueNPCAppearanceWindow:onVoiceChanged(combo)
    if self.syncing then return end
    local selected = comboData(combo)
    if selected == "random" or selected == nil then
        local appearance = Appearance.Normalize(self.draft.appearance)
        appearance.voice = { mode = "random" }
        self.draft.appearance = appearance
        local survivor = self.draft.identity
            and self.draft.identity.survivor or nil
        if survivor then
            survivor.voice = nil
            survivor.voicePrefix = nil
            survivor.voiceType = nil
            survivor.voicePitch = nil
        end
        self.draft.appearanceAuthored.voice = true
        self.draft.appearanceAuthored.voicePrefix = true
        self.draft.appearanceAuthored.voiceType = true
        self.draft.appearanceAuthored.voicePitch = true
        self:markChanged()
        return
    end
    local style = self.voiceStyles and self.voiceStyles[tonumber(selected)] or nil
    if not style then return end
    self:setVoiceDraft({
        prefix = style.prefix,
        voiceType = style.voiceType,
        pitch = tonumber(self.draft.identity
            and self.draft.identity.survivor
            and self.draft.identity.survivor.voicePitch) or 0,
    })
    self:syncFromDraft()
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onVoicePitchChanged(value)
    if self.syncing then return end
    local appearance = Appearance.Normalize(self.draft.appearance)
    local voice = appearance.voice or {}
    if voice.mode ~= "item" then return end
    local pitch = math.max(-100, math.min(100, math.floor(tonumber(value) or 0)))
    voice.pitch = pitch
    appearance.voice = voice
    self.draft.appearance = appearance
    self.draft.identity.survivor.voicePitch = pitch
    if self.voicePitchValue and self.voicePitchValue.setName then
        self.voicePitchValue:setName(tostring(pitch))
    end
    self:markChanged()
end

function ISPNCUniqueNPCAppearanceWindow:onVoiceSampleChanged(combo)
    -- The sample is preview-only and never changes the authored definition.
end

function ISPNCUniqueNPCAppearanceWindow:onSkinModeChanged(combo)
    if self.syncing then return end
    local mode = comboData(combo) or "random"
    if mode == "legacy" then
        -- Legacy RGB values are still accepted when loading old drafts, but
        -- cannot be authored by this editor because the game stores skin as
        -- a texture/index choice.
        self:syncFromDraft()
        return
    end
    local survivor = self.draft.identity.survivor
    local texture = skinTextureForTone(mode, self.draft.isFemale == true)
    survivor.skinTexture = texture
    survivor.skinColor = nil
    self.draft.appearanceAuthored.skinTexture = true
    self.draft.appearanceAuthored.skinColor = true
    self:syncFromDraft()
    self:markChanged()
end

