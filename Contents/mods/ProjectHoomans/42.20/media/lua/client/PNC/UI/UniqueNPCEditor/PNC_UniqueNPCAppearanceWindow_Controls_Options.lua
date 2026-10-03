local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local tr = Internal.tr
local selectData = Internal.selectData
local voiceOptions = Internal.voiceOptions
local addOptions = Internal.addOptions
local AudioDebug = Internal.AudioDebug
local skinToneOptions = Internal.skinToneOptions
local skinToneFromTexture = Internal.skinToneFromTexture
local skinTextureForTone = Internal.skinTextureForTone
local locations = Internal.locations
local labelFor = Internal.labelFor
local itemOptions = Internal.itemOptions
local runtimeItemFor = Internal.runtimeItemFor

function ISPNCUniqueNPCAppearanceWindow:buildVoiceOptions()
    self.voiceStyles = voiceOptions(self.draft and self.draft.isFemale == true)
    local options = {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
    }
    for _, style in ipairs(self.voiceStyles) do
        options[#options + 1] = { id = style.id, label = style.label }
    end
    addOptions(self.voiceCombo, options)
    self.voiceEvents = AudioDebug and AudioDebug.GetVoiceEvents
        and AudioDebug.GetVoiceEvents() or {}
    local eventOptions = {}
    for _, event in ipairs(self.voiceEvents) do
        eventOptions[#eventOptions + 1] = {
            id = event.suffix,
            label = tostring(event.suffix) .. " ("
                .. tostring(event.category or "Voice") .. ")",
        }
    end
    addOptions(self.voiceSampleCombo, eventOptions)
    selectData(self.voiceSampleCombo, "ShoutHey")
end

function ISPNCUniqueNPCAppearanceWindow:buildOutfitOptions()
    local options = {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "none", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
    }
    if type(getAllOutfits) == "function" then
        local female = self.draft and self.draft.isFemale == true
        local ok, values = pcall(getAllOutfits, female)
        if ok and values and values.size then
            for index = 0, values:size() - 1 do
                local id = tostring(values:get(index))
                options[#options + 1] = { id = "named:" .. id, label = id }
            end
        end
    end
    addOptions(self.outfitCombo, options)
end

function ISPNCUniqueNPCAppearanceWindow:refreshGenderOptions()
    local survivor = self.draft and self.draft.identity
        and self.draft.identity.survivor or nil
    local tone = survivor and skinToneFromTexture(survivor.skinTexture)
        or "random"
    if survivor and tone ~= "random" and tone ~= "legacy" then
        -- HumanVisual texture names are gender-specific. Preserve the
        -- selected native tone when the General tab changes gender.
        survivor.skinTexture = skinTextureForTone(tone,
            self.draft.isFemale == true)
    end
    addOptions(self.skinModeCombo,
        skinToneOptions(self.draft and self.draft.isFemale == true))
    self:buildOutfitOptions()
    self:buildVoiceOptions()
    self:syncFromDraft()
end

function ISPNCUniqueNPCAppearanceWindow:addLocationRow(location)
    local row = { location = location, label = labelFor(location) }
    row.labelControl = ISLabel:new(0, 0, 24, row.label,
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    row.labelControl:initialise()
    self.content:addChild(row.labelControl)
    row.policy = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onPolicyChanged)
    row.policy:initialise()
    row.policy.bodyLocation = location
    addOptions(row.policy, {
        { id = "random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "none", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
        { id = "item", label = tr("UI_PNC_UniqueNPCEditor_Selected", "Selected item") },
    })
    self.content:addChild(row.policy)
    row.item = ISComboBox:new(0, 0, 1, 24, self,
        ISPNCUniqueNPCAppearanceWindow.onItemChanged)
    row.item:initialise()
    row.item.bodyLocation = location
    addOptions(row.item, itemOptions(location))
    self.content:addChild(row.item)
    row.runtimeItem = runtimeItemFor(self.draft, location)
    self.rows[#self.rows + 1] = row
end
