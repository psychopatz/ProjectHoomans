-- Bounded tab-scoped generation over the existing draft/blueprint pipeline.
require "PNC/Identity/PNC_UniqueNPCDraft"
require "PNC/Core/Identity/PNC_Identity_Names"
PNC.NPCAuthoringVariation = PNC.NPCAuthoringVariation or {}
local V = PNC.NPCAuthoringVariation
local Model, Identity = PNC.UniqueNPCEditorModel, PNC.Identity
local Registry = PNC.NPCAuthoring.Registry
local function copy(value) return Registry.Copy(value) end
local scopes = {
    bio = { ["identity.forename"] = true, ["identity.surname"] = true, ["identity.nickname"] = true, ["identity.isFemale"] = true },
    attributes = { ["skills.baseLevels"] = true, ["traits.npc"] = true, ["traits.physiological"] = true, ["traits.dynamic"] = true },
    loadout = { appearance = true, startingItems = true, equipmentSpawnMode = true },
}
function V.Includes(scope, id)
    if scope == "appearance" then return id == "appearance" or string.sub(id, 1, 11) == "appearance." end
    return scopes[scope] and scopes[scope][id] == true or false
end
function V.Seed(seed, scope, counter, fingerprint)
    return Identity.MixSeed(seed or 1, "editor:" .. tostring(scope) .. ":" .. tostring(counter or 1) .. ":" .. tostring(fingerprint or ""))
end
local function rotated(values, seed, salt)
    local out = {}
    if #values == 0 then return out end
    local offset = Identity.Index(seed, salt, #values) - 1
    for n = 1, #values do out[n] = values[(offset + n - 1) % #values + 1] end
    return out
end
local function materialize(source, seed)
    local draft = copy(source)
    draft.runtimeRecord = nil
    Model.Randomize(draft, seed)
    local preview = Model.BuildPreviewDraft(draft)
    local record, reason = Model.EnsureRuntimeRecord(preview, true)
    if not record then return nil, reason end
    local spec = Model.BuildPortraitSpec(preview)
    if not spec or not spec.appearance then return nil, "preview_unavailable" end
    return { draft = draft, record = record, look = spec.appearance }
end
local function wardrobe(generated, original)
    local appearance = copy(original or {})
    appearance.outfit = copy(generated.draft.appearance.outfit)
    appearance.slots = copy(generated.draft.appearance.slots)
    for _, item in pairs(generated.record.inventory and generated.record.inventory.items or {}) do
        if item.wornSlot and not item.equipSlot and not item.maxWeight and not item.bagContainer then
            appearance.slots[item.wornSlot] = { mode = "item", type = item.type, wornSlot = item.wornSlot, itemState = copy(item.itemState) }
        end
    end
    return appearance
end
local function companionTrait(id)
    local traits = PNC.StartingCompanionTraits
    if not traits then return false end
    local canonical = PsychopatzCore and PsychopatzCore.Traits and PsychopatzCore.Traits.NormalizeID
        and PsychopatzCore.Traits.NormalizeID(id, traits.OWNER) or id
    if traits.GetDefinition(canonical or id) then return true end
    for _, spec in ipairs(traits.DEFINITIONS or {}) do if spec.resource == id then return true end end
    return false
end
function V.Generate(source, scope, seed)
    if scope == "relations" then return nil, "backstory_pending" end
    if not scopes[scope] and scope ~= "appearance" then return nil, "unknown_variation_scope" end
    local out = copy(source)
    out.runtimeRecord = nil
    out.identity = out.identity or { survivor = {} }
    out.appearance = PNC.Identity.Appearance.Normalize(out.appearance)
    local survivor = out.identity.survivor
    out.authoringClears, out.appearanceAuthored, out.authoredFields = out.authoringClears or {}, out.appearanceAuthored or {}, out.authoredFields or {}
    -- An explicit reroll replaces prior clear intent in this scope, including
    -- canonical debug presets; unrelated clears must remain intact.
    for id in pairs(out.authoringClears) do
        if V.Includes(scope, id) then out.authoringClears[id] = nil end
    end
    if scope == "bio" then
        -- Bio varies names while retaining the chosen/relationship-derived body.
        local full = PNC.IdentityNames.Generate(seed, out.isFemale, out.archetypeID, { namespace = "projecthoomans.editor.bio" })
        local first, last = PNC.IdentityNames.Split(full)
        if not first or not last then return nil, "name_generation_unavailable" end
        survivor.forename, survivor.surname = first, last
        out.displayName = full
        out.identity.nickname = PNC.IdentityNames.ResolveNickname(first, seed, { namespace = "projecthoomans.editor.nickname" })
        out.nicknameCleared = out.identity.nickname == nil
    elseif scope == "attributes" then
        out.skillLevels, out.npcTraits, out.vanillaTraits, out.dynamicTraits = {}, {}, {}, {}
        local skills, npc, vanilla = {}, {}, {}
        for _, group in ipairs(PNC.SkillCatalog.GetGroups()) do for _, skill in ipairs(group.skills or {}) do skills[#skills + 1] = skill.id end end
        for _, definition in ipairs(PNC.NPCTraits.GetDefinitions()) do
            if not companionTrait(definition.id) then npc[#npc + 1] = definition.id end
        end
        local traits = CharacterTraitDefinition and CharacterTraitDefinition.getTraits()
        if traits then
            for index = 0, traits:size() - 1 do
                local entry = traits:get(index)
                local traitType = entry and entry.getType and entry:getType()
                local id = traitType and traitType.getName and traitType:getName()
                if id and not companionTrait(id) then vanilla[#vanilla + 1] = id end
            end
        end
        table.sort(skills); table.sort(npc); table.sort(vanilla)
        for index, id in ipairs(rotated(skills, seed, "skills")) do
            if index > 6 then break end
            Model.TryAddSkill(out, id, Identity.Range(seed, "level:" .. id, 0, 8))
        end
        local npcCount, vanillaCount = 0, 0
        for attempt, id in ipairs(rotated(npc, seed, "npc")) do
            if npcCount >= 2 or attempt > 32 then break end
            local ok = Model.TryAddTrait(out, npcCount == 0 and "npc" or "dynamic", id)
            if ok then npcCount = npcCount + 1 end
        end
        for attempt, id in ipairs(rotated(vanilla, seed, "vanilla")) do
            if vanillaCount >= 2 or attempt > 32 then break end
            if Model.TryAddTrait(out, "vanilla", id) then vanillaCount = vanillaCount + 1 end
        end
        for _, field in ipairs({ "skillLevels", "npcTraits", "vanillaTraits", "dynamicTraits" }) do out.authoredFields[field] = true end
    else
        local input = copy(out)
        if scope == "loadout" then
            input.startingItems = {}
            input.authoredFields.startingItems = true
            input.equipmentSpawnMode = ({ "melee", "ranged", "both" })[Identity.Index(seed, "gear", 3)]
        end
        local generated, reason = materialize(input, seed)
        if not generated then return nil, reason end
        if scope == "appearance" then
            for _, field in ipairs({ "hairModel", "beardModel", "skinTexture", "skinColor", "hairColor" }) do
                survivor[field] = copy(generated.look[field])
                out.appearanceAuthored[field] = true
            end
            if PNC.NPCVoice and PNC.NPCVoice.GetProfile then
                local voice = PNC.NPCVoice.GetProfile({ identitySeed = seed, isFemale = out.isFemale })
                if voice then
                    survivor.voice, survivor.voicePrefix, survivor.voiceType, survivor.voicePitch = voice.prefix, voice.prefix, voice.voiceType, voice.pitch
                    out.appearance.voice = { mode = "item", prefix = voice.prefix, type = voice.voiceType, pitch = voice.pitch }
                end
            end
        else
            out.appearance = wardrobe(generated, out.appearance)
            out.startingItems = {}
            local inventory = generated.record.inventory
            local ids = {}
            for id in pairs(inventory and inventory.items or {}) do ids[#ids + 1] = id end
            table.sort(ids, function(a, b) return tostring(a) < tostring(b) end)
            for _, id in ipairs(ids) do
                local item = inventory.items[id]
                local clothing = item.wornSlot and not item.equipSlot and not item.maxWeight and not item.bagContainer
                local identityItem = string.find(tostring(item.templateKey or ""), "tmpl:identity_card:", 1, true) == 1
                if not clothing and not identityItem and #out.startingItems < 128 then
                    local destination = item.container and item.container ~= "root" and "bag" or nil
                    local spec = PNC.Inventory.Queries.ToDefinitionSpec(item, "variation:" .. tostring(#out.startingItems + 1), destination)
                    if spec then out.startingItems[#out.startingItems + 1] = spec end
                end
            end
            out.equipmentSpawnMode = "none" -- exact gear, not another generated grant
            out.authoredFields.startingItems = true
            out.authoringClears.startingItems = #out.startingItems == 0 or nil
        end
        out.appearanceAuthored.appearance = true
    end
    return out
end
return V
