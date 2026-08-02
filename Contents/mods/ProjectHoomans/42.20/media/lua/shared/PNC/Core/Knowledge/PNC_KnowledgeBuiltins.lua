-- Built-in knowledge extension registrations. Adding a descriptor elsewhere
-- only needs a provider/resolver registration and no core-service changes.

local Registry = PNC.KnowledgeRegistry
local Descriptors = PNC.KnowledgeDescriptors
local Providers = PNC.KnowledgeProviders
local Resolvers = PNC.KnowledgeResolvers
local Sources = PNC.KnowledgeEvidenceSources
local Categories = PNC.KnowledgeCategories

local function registerCategory(id, order)
    Categories.Register({ id = id, nameKey = "UI_PNC_KnowledgeCategory_" .. id, sortOrder = order })
end
for _, entry in ipairs({
    { "identity", 10 }, { "personality", 20 }, { "preferences", 30 },
    { "capabilities", 40 }, { "habits", 50 }, { "social", 60 },
    { "history", 70 }, { "faction", 80 }, { "medical", 90 }, { "misc", 100 },
}) do registerCategory(entry[1], entry[2]) end

for _, source in ipairs({
    { "direct_disclosure", 1, true, true }, { "observed_behavior", .75, false, false },
    { "conversation", .90, false, false }, { "shared_activity", .80, false, false },
    { "witnessed_event", .75, false, false }, { "item_observation", .85, false, false },
    { "skill_observation", .85, false, false }, { "trusted_gossip", .65, false, false },
    { "rumor", .35, false, false }, { "debug", 1, true, true },
}) do
    Sources.Register(source[1], { reliability = source[2], mayConfirm = source[3], bypassFamiliarity = source[4] })
end

local function familiarityMultiplier(familiarity)
    familiarity = Registry.Clamp(familiarity, 0, 100)
    return .5 + familiarity / 100 * .75
end

local function status(descriptor, confidence, mayConfirm)
    if mayConfirm then return "confirmed" end
    if confidence >= descriptor.discovery.knownThreshold then return "known" end
    if confidence >= descriptor.discovery.suspectedThreshold then return "suspected" end
    return nil
end

Resolvers.Register("signed_evidence", {
    Resolve = function(descriptor, evidence, familiarity)
        local signed, total, confirms = 0, 0, false
        for _, entry in ipairs(evidence or {}) do
            local source = Sources.Get(entry.sourceType) or {}
            local weight = Registry.Clamp(entry.strength, 0, 1)
                * Registry.Clamp(entry.reliability or source.reliability, 0, 1)
            if not source.bypassFamiliarity then weight = weight * familiarityMultiplier(familiarity) end
            local direction = tonumber(entry.direction) or 0
            if direction == 0 and source.mayConfirm and entry.payload and entry.payload.observedValue ~= nil then
                direction = tonumber(entry.payload.observedValue) and tonumber(entry.payload.observedValue) >= .5 and 1 or -1
            end
            signed = signed + direction * weight
            total = total + math.abs(weight)
            confirms = confirms or source.mayConfirm == true
        end
        if total <= 0 then return nil end
        local confidence = Registry.Clamp(math.abs(signed) / math.max(1, total), 0, 1)
        confidence = Registry.Clamp(confidence * math.min(1, total), 0, 1)
        local resolvedStatus = status(descriptor, confidence, confirms)
        if not resolvedStatus then return nil end
        return { value = signed >= 0 and "high" or "low", confidence = confidence, status = resolvedStatus }
    end,
})

Resolvers.Register("categorical_votes", {
    Resolve = function(descriptor, evidence, familiarity)
        local votes, total, confirms = {}, 0, false
        for _, entry in ipairs(evidence or {}) do
            local payload = entry.payload or {}
            local value = payload.observedValue
            if value ~= nil then
                local source = Sources.Get(entry.sourceType) or {}
                local weight = Registry.Clamp(entry.strength, 0, 1) * Registry.Clamp(entry.reliability or source.reliability, 0, 1)
                if not source.bypassFamiliarity then weight = weight * familiarityMultiplier(familiarity) end
                votes[tostring(value)] = (votes[tostring(value)] or 0) + weight
                total = total + weight
                confirms = confirms or source.mayConfirm == true
            end
        end
        local value, weight
        for candidate, candidateWeight in pairs(votes) do
            if not weight or candidateWeight > weight or (candidateWeight == weight and candidate < value) then value, weight = candidate, candidateWeight end
        end
        if not value then return nil end
        local confidence = Registry.Clamp((weight or 0) / math.max(1, total), 0, 1) * math.min(1, total)
        local resolvedStatus = status(descriptor, confidence, confirms)
        return resolvedStatus and { value = value, confidence = confidence, status = resolvedStatus } or nil
    end,
})

Resolvers.Register("direct_fact", {
    Resolve = function(descriptor, evidence)
        local selected
        for _, entry in ipairs(evidence or {}) do
            local source = Sources.Get(entry.sourceType)
            if source and source.mayConfirm and entry.payload and entry.payload.observedValue ~= nil
                and (not selected or (tonumber(entry.createdAt) or 0) > (tonumber(selected.createdAt) or 0))
            then selected = entry end
        end
        if not selected then return nil end
        return { value = selected.payload.observedValue, confidence = 1, status = "confirmed" }
    end,
})
Resolvers.Register("threshold_boolean", Resolvers.Get("categorical_votes"))
Resolvers.Register("competence_band", Resolvers.Get("categorical_votes"))

Providers.Register("pnc_social_profile", {
    GetValue = function(record, descriptor)
        local personality = record and record.social and record.social.personality or nil
        local field = descriptor and descriptor.presentation and descriptor.presentation.truthField
        return personality and field and personality[field] or nil
    end,
})

Providers.Register("pnc_identity", {
    GetValue = function(record, descriptor)
        local identity = PNC.Identity and PNC.Identity.GetCharacterSummary
            and PNC.Identity.GetCharacterSummary(record) or {}
        local field = descriptor and descriptor.presentation and descriptor.presentation.truthField
        return identity and field and identity[field] or nil
    end,
})

Providers.Register("pnc_skill", {
    GetValue = function(record, descriptor)
        local skillID = descriptor and descriptor.presentation and descriptor.presentation.skillID
        return PNC.Skills and PNC.Skills.GetLevel and skillID
            and PNC.Skills.GetLevel(record, skillID) or nil
    end,
})

Providers.Register("pnc_faction", {
    GetValue = function(record)
        local factionID = record and record.affiliation and record.affiliation.factionID or nil
        local faction = factionID and PNC.Factions and PNC.Factions.GetPresentation
            and PNC.Factions.GetPresentation(factionID) or nil
        return faction and faction.name or nil
    end,
})

local function descriptor(id, category, field, valueType, resolverID, privacy, discovery, presentation)
    presentation = presentation or {}
    presentation.truthField = field
    Descriptors.Register({
        id = id, version = 1, category = category, providerID = "pnc_social_profile",
        resolverID = resolverID, valueType = valueType, privacy = privacy,
        discovery = discovery, capabilities = {
            observable = discovery.allowObservation == true, disclosable = discovery.allowDisclosure == true,
            inferable = discovery.allowInference == true, gossipable = false, decayable = true,
        }, presentation = presentation,
    })
end

local observable = { allowInference = true, allowObservation = true, allowDisclosure = true, minimumFamiliarity = 10, suspectedThreshold = .30, knownThreshold = .70 }
local personal = { allowInference = false, allowObservation = false, allowDisclosure = true, minimumFamiliarity = 25, suspectedThreshold = .30, knownThreshold = .70 }
descriptor("personality.orientation", "social", "orientation", "categorical", "direct_fact", "private", personal, { topicID = "social" })
descriptor("preference.food", "preferences", "foodPreference", "categorical", "categorical_votes", "personal", personal, { topicID = "preferences" })
descriptor("personality.romance_style", "personality", "romanceStyle", "categorical", "categorical_votes", "private", personal, { topicID = "personality" })
descriptor("personality.jealousy_style", "personality", "jealousyStyle", "categorical", "categorical_votes", "private", personal, { topicID = "personality" })
descriptor("personality.social_style", "personality", "socialStyle", "categorical", "categorical_votes", "observable", observable, { topicID = "personality" })
for _, field in ipairs({ "compassion", "sociability", "forgiveness", "bravery", "materialism", "aggression", "loyalty" }) do
    descriptor("personality." .. field, "personality", field, "band", "signed_evidence", "observable", observable, {
        positiveLabel = field, negativeLabel = "not_" .. field, topicID = "personality",
    })
end

Descriptors.Register({
    id = "identity.name", version = 1, category = "identity", providerID = "pnc_identity",
    resolverID = "direct_fact", valueType = "text_enum", privacy = "personal",
    discovery = personal, capabilities = { disclosable = true, decayable = false },
    presentation = { truthField = "displayName", topicID = "identity_name" },
})
Descriptors.Register({
    id = "identity.archetype", version = 1, category = "identity", providerID = "pnc_identity",
    resolverID = "direct_fact", valueType = "text_enum", privacy = "personal",
    discovery = personal, capabilities = { disclosable = true, decayable = false },
    presentation = { truthField = "archetypeLabel", topicID = "background" },
})
Descriptors.Register({
    id = "faction.identity", version = 1, category = "faction", providerID = "pnc_faction",
    resolverID = "direct_fact", valueType = "text_enum", privacy = "personal",
    discovery = personal, capabilities = { disclosable = true, decayable = false },
    presentation = { topicID = "identity_name" },
})

for _, group in ipairs(PNC.SkillCatalog and PNC.SkillCatalog.GetGroups and PNC.SkillCatalog.GetGroups() or {}) do
    for _, skill in ipairs(group.skills or {}) do
        Descriptors.Register({
            id = "skill." .. tostring(skill.id), version = 1, category = "capabilities",
            providerID = "pnc_skill", resolverID = "direct_fact", valueType = "scalar",
            privacy = "personal", discovery = personal,
            capabilities = { disclosable = true, observable = true, decayable = true },
            presentation = { skillID = skill.id, topicID = "skill." .. tostring(skill.id) },
        })
    end
end

return Registry
