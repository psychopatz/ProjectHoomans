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
            signed = signed + (tonumber(entry.direction) or 0) * weight
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
        local votes, total = {}, 0
        for _, entry in ipairs(evidence or {}) do
            local payload = entry.payload or {}
            local value = payload.observedValue
            if value ~= nil then
                local source = Sources.Get(entry.sourceType) or {}
                local weight = Registry.Clamp(entry.strength, 0, 1) * Registry.Clamp(entry.reliability or source.reliability, 0, 1)
                if not source.bypassFamiliarity then weight = weight * familiarityMultiplier(familiarity) end
                votes[tostring(value)] = (votes[tostring(value)] or 0) + weight
                total = total + weight
            end
        end
        local value, weight
        for candidate, candidateWeight in pairs(votes) do
            if not weight or candidateWeight > weight or (candidateWeight == weight and candidate < value) then value, weight = candidate, candidateWeight end
        end
        if not value then return nil end
        local confidence = Registry.Clamp((weight or 0) / math.max(1, total), 0, 1) * math.min(1, total)
        local resolvedStatus = status(descriptor, confidence, false)
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
descriptor("personality.orientation", "social", "orientation", "categorical", "direct_fact", "private", personal)
descriptor("preference.food", "preferences", "foodPreference", "categorical", "categorical_votes", "personal", personal)
descriptor("personality.romance_style", "personality", "romanceStyle", "categorical", "categorical_votes", "private", personal)
descriptor("personality.jealousy_style", "personality", "jealousyStyle", "categorical", "categorical_votes", "private", personal)
descriptor("personality.social_style", "personality", "socialStyle", "categorical", "categorical_votes", "observable", observable)
for _, field in ipairs({ "compassion", "sociability", "forgiveness", "bravery", "materialism", "aggression", "loyalty" }) do
    descriptor("personality." .. field, "personality", field, "band", "signed_evidence", "observable", observable, {
        positiveLabel = field, negativeLabel = "not_" .. field,
    })
end

return Registry
