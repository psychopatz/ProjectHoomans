PNC = PNC or {}
PNC.Identity = PNC.Identity or {}

pcall(require, "PNC/Core/Identity/PNC_Identity_Appearance")

local Identity = PNC.Identity
local Archetypes = PNC.Archetypes
local Appearance = Identity.Appearance

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    return value
end

local function resolveHumanSkinTexture(value, isFemale)
    local texture = value and tostring(value) or ""
    local expected = isFemale and "FemaleBody" or "MaleBody"
    if texture ~= "" and string.find(texture, expected, 1, true) then
        return texture
    end
    return isFemale and "FemaleBody01" or "MaleBody01"
end

local function normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

local function choose(list, seed, salt)
    if type(list) ~= "table" or #list <= 0 then
        return nil
    end
    return list[Identity.Index(seed, salt, #list)]
end

local function preserveGeneratedLookState(record, look)
    local inventory = record and record.inventory
    local byType = {}
    local used = {}
    local output = {}
    local item
    local key
    local fullType
    if type(look) ~= "table" or type(inventory) ~= "table"
        or type(inventory.items) ~= "table"
    then
        return look
    end
    for _, item in pairs(inventory.items) do
        key = tostring(item and item.templateKey or "")
        if item and string.sub(key, 1, 9) == "tmpl:look:" then
            fullType = tostring(item.type or "")
            if fullType ~= "" then
                byType[fullType] = byType[fullType] or {}
                byType[fullType][#byType[fullType] + 1] = item
            end
        end
    end
    for index, value in ipairs(look) do
        fullType = tostring(value or "")
        local candidates = byType[fullType]
        local selected
        if candidates then
            for candidateIndex, candidate in ipairs(candidates) do
                local marker = tostring(fullType) .. ":" .. tostring(candidateIndex)
                if not used[marker] then
                    used[marker] = true
                    selected = candidate
                    break
                end
            end
        end
        output[index] = selected and {
            type = fullType,
            wornSlot = selected.wornSlot,
            itemState = copy(selected.itemState),
        } or fullType
    end
    return output
end

function Identity.ResolveArchetypeID(source)
    local seed
    local tacticalClass
    local options
    local explicit = normalizeString(source and source.archetypeID or nil)
    if explicit and Archetypes.Get(explicit) then
        return Archetypes.Get(explicit).id
    end
    seed = Identity.NormalizeSeed(source and source.identitySeed or nil, tostring(source and source.tacticalClass or "colonist"))
    tacticalClass = PNC.Types and PNC.Types.NormalizeTacticalClass and PNC.Types.NormalizeTacticalClass(source and source.tacticalClass) or tostring(source and source.tacticalClass or "colonist")
    options = tacticalClass == "hostile" and Archetypes.GetHostileDefaults() or Archetypes.GetColonistDefaults()
    return tostring(choose(options, seed, "archetype:" .. tacticalClass) or "General")
end

function Identity.ResolveIsFemale(source, seed)
    if source and source.identity and source.identity.isFemale ~= nil then
        return source.identity.isFemale == true
    end
    if source and source.isFemale ~= nil then
        return source.isFemale == true
    end
    return Identity.Index(seed, "gender", 2) == 1
end

function Identity.ResolveDisplayName(source, seed, isFemale, archetypeID)
    local explicit = normalizeString(source and (source.displayName or source.name) or nil)
    if source and source.identity and normalizeString(source.identity.displayName) then
        return normalizeString(source.identity.displayName)
    end
    if explicit then
        return explicit
    end
    return "Survivor"
end

function Identity.ApplyRecordIdentity(record, source)
    local seed
    local archetype
    local resolvedIdentity
    if not record then
        return nil
    end
    seed = Identity.NormalizeSeed(
        source and (source.identitySeed or (source.identity and source.identity.seed)) or record.identitySeed,
        tostring(source and (source.displayName or source.name or source.tacticalClass) or record.id or "pnc")
    )
    archetype = Archetypes.Get(Identity.ResolveArchetypeID(source or record))
    resolvedIdentity = type(source and source.identity) == "table" and PNC.Core.DeepCopy(source.identity)
        or type(record.identity) == "table" and PNC.Core.DeepCopy(record.identity)
        or Identity.GenerateResolvedIdentity({
            id = record.id,
            displayName = source and source.displayName or source and source.name or nil,
            name = source and source.name or nil,
            isFemale = source and source.isFemale,
            archetypeID = archetype.id,
            archetypeLabel = archetype.label,
            identitySeed = seed,
        })
    resolvedIdentity.seed = seed
    resolvedIdentity.archetypeID = archetype.id
    resolvedIdentity.archetypeLabel = archetype.label
    resolvedIdentity.displayName = Identity.ResolveDisplayName({ identity = resolvedIdentity, displayName = source and source.displayName or nil, name = source and source.name or nil }, seed, resolvedIdentity.isFemale == true, archetype.id)
    record.identity = resolvedIdentity
    record.identitySeed = resolvedIdentity.seed
    record.archetypeID = resolvedIdentity.archetypeID
    record.archetypeLabel = resolvedIdentity.archetypeLabel
    record.isFemale = resolvedIdentity.isFemale == true
    record.name = resolvedIdentity.displayName
    record.visualProfile = normalizeString(source and source.visualProfile or record.visualProfile) or archetype.visualProfile
    record.outfit = normalizeString(source and source.outfit or record.outfit) or nil
    -- Defaults belong only at record creation. Applying identity during a
    -- snapshot/load/reconciliation pass must preserve player-edited work
    -- policy, otherwise a UI refresh silently restores archetype values.
    record.allowedJobs = PNC.Core.DeepCopy(record.allowedJobs
        or archetype.allowedJobs or {})
    record.jobPriorities = PNC.Core.DeepCopy(record.jobPriorities or {})
    return record
end

function Identity.RollAppearance(record)
    local archetype
    local genderKey
    local seed
    local lookPool
    local look
    local survivor
    local spawnOutfit
    local runtime
    local hairColor
    local skinColor
    local cacheKey
    local appearanceResult
    local appearancePolicy
    local resolvedOutfit
    if not record then
        return nil
    end
    Identity.ApplyRecordIdentity(record, record)
    seed = Identity.NormalizeSeed(record.identitySeed, record.id)
    archetype = Archetypes.Get(record.archetypeID)
    genderKey = record.isFemale and "female" or "male"
    lookPool = archetype.looks and archetype.looks[genderKey] or nil
    look = choose(lookPool, seed, "look:" .. tostring(archetype.id))
    look = preserveGeneratedLookState(record, look)
    appearanceResult = Appearance and Appearance.Resolve
        and Appearance.Resolve(record, look) or {
            itemSpecs = {}, items = type(look) == "table"
                and PNC.Core.DeepCopy(look) or {},
        }
    appearancePolicy = appearanceResult.policy or {}
    survivor = record.identity and record.identity.survivor or {}
    spawnOutfit = archetype.looks and archetype.looks.spawnOutfit or {}
    if Appearance and Appearance.HasExplicitSlots
        and Appearance.HasExplicitSlots(appearancePolicy)
    then
        -- A named outfit is a complete native preset.  Once the definition
        -- contains an authored item/none slot, applying that preset first
        -- would reintroduce clothing the author explicitly selected or
        -- removed.  Exact slots become the sole clothing authority.
        resolvedOutfit = nil
    elseif appearancePolicy.outfit
        and appearancePolicy.outfit.mode == "none"
    then
        resolvedOutfit = nil
    elseif appearancePolicy.outfit
        and appearancePolicy.outfit.mode == "item"
        and appearancePolicy.outfit.id
    then
        resolvedOutfit = tostring(appearancePolicy.outfit.id)
    else
        resolvedOutfit = record.outfit
            or (record.isFemale and spawnOutfit.female or spawnOutfit.male)
    end
    hairColor = survivor.hairColor or {}
    skinColor = survivor.skinColor or {}
    runtime = record.runtime or {}
    record.runtime = runtime
    cacheKey = table.concat({
        tostring(seed),
        tostring(archetype.id),
        tostring(record.isFemale == true),
        tostring(record.outfit or ""),
        tostring(survivor.skinTexture or ""),
        tostring(survivor.hairModel or ""),
        tostring(survivor.beardModel or ""),
        tostring(hairColor.r or ""),
        tostring(hairColor.g or ""),
        tostring(hairColor.b or ""),
        tostring(skinColor.r or ""),
        tostring(skinColor.g or ""),
        tostring(skinColor.b or ""),
        tostring(survivor.voicePrefix or ""),
        tostring(survivor.voiceType or ""),
        tostring(survivor.voicePitch or ""),
        Appearance and Appearance.Signature
            and Appearance.Signature(record.appearance) or "",
    }, "|")
    if runtime.appearanceCacheKey == cacheKey and runtime.appearanceCache then
        if not runtime.generatedAppearance then
            runtime.generatedAppearance = PNC.Core.DeepCopy(
                runtime.appearanceCache)
        end
        return runtime.appearanceCache
    end
    runtime.appearanceCache = {
        outfit = resolvedOutfit,
        outfitMode = appearancePolicy.outfit
            and appearancePolicy.outfit.mode or "random",
        outfitItems = PNC.Core.DeepCopy(appearanceResult.items or {}),
        outfitItemSpecs = PNC.Core.DeepCopy(appearanceResult.itemSpecs or {}),
        appearancePolicy = PNC.Core.DeepCopy(appearanceResult.policy),
        skinTexture = resolveHumanSkinTexture(survivor.skinTexture, record.isFemale == true),
        skinColor = survivor.skinColor,
        hairModel = survivor.hairModel,
        beardModel = record.isFemale and nil or survivor.beardModel,
        hairColor = survivor.hairColor,
        voice = survivor.voice,
        voicePrefix = survivor.voicePrefix or survivor.voice,
        voiceType = survivor.voiceType,
        voicePitch = survivor.voicePitch,
    }
    if not runtime.generatedAppearance then
        runtime.generatedAppearance = PNC.Core.DeepCopy(runtime.appearanceCache)
    end
    runtime.appearanceCacheKey = cacheKey
    return runtime.appearanceCache
end

function Identity.GetCharacterSummary(record)
    local archetype = Archetypes.Get(record and record.archetypeID or nil)
    local identity = record and record.identity or {}
    return {
        displayName = identity.displayName or "Unknown",
        archetypeID = archetype.id,
        archetypeLabel = archetype.label,
        identitySeed = identity.seed or record and record.identitySeed or 1,
        isFemale = identity.isFemale == true or record and record.isFemale == true or false,
        recruited = record and record.recruited == true or false,
        tacticalClass = record and record.tacticalClass or "colonist",
        survivor = PNC.Core.DeepCopy(identity.survivor or {}),
    }
end
