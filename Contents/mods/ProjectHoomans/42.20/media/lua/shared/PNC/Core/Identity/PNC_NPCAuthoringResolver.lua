-- Context/policy resolution for the canonical sparse NPC blueprint.
--
-- This is the only resolver used by Unique NPC previews and starter policy
-- consumers.  Its trace is intentionally data-only so normal UI and debug
-- inspection can consume the same bounded explanation.

PNC = PNC or {}
PNC.NPCAuthoringResolver = PNC.NPCAuthoringResolver or {}

local Resolver = PNC.NPCAuthoringResolver
local Registry = PNC.NPCAuthoringFieldRegistry
local Blueprint = PNC.NPCAuthoringBlueprint

Resolver.SOURCES = {
    explicit = true,
    generated = true,
    inherited = true,
    derived = true,
    authoritative = true,
}

local function copy(value)
    return Registry.Copy(value)
end

local function identityIndex(seed, salt, count)
    local Identity = PNC.Identity
    if Identity and Identity.Index then
        return Identity.Index(seed, salt, count)
    end
    return ((tonumber(Registry.Hash(
        tostring(seed) .. ":" .. tostring(salt)
    )) or 1) % count) + 1
end

local function identityMix(seed, salt)
    local Identity = PNC.Identity
    if Identity and Identity.MixSeed then
        return Identity.MixSeed(seed, salt)
    end
    return tonumber(Registry.Hash(tostring(seed) .. ":" .. tostring(salt))) or 1
end

local function contextValue(context, key)
    if type(context) ~= "table" then return nil end
    if context[key] ~= nil then return context[key] end
    if type(context.playerContext) == "table" then
        return context.playerContext[key]
    end
    return nil
end

local function playerSurname(context)
    local value = contextValue(context, "playerSurname")
    local player = contextValue(context, "player")
    local descriptor
    if value ~= nil then return tostring(value) ~= "" and tostring(value) or nil end
    if player and player.getDescriptor then
        descriptor = player:getDescriptor()
        if descriptor and descriptor.getSurname then
            value = descriptor:getSurname()
        end
    end
    return value and tostring(value) ~= "" and tostring(value) or nil
end

local function playerFemale(context)
    local value = contextValue(context, "playerFemale")
    local player = contextValue(context, "player")
    local descriptor
    if value ~= nil then return value == true end
    if player and player.isFemale then return player:isFemale() == true end
    if player and player.getDescriptor then
        descriptor = player:getDescriptor()
        if descriptor and descriptor.isFemale then
            return descriptor:isFemale() == true
        end
    end
    return false
end

local function playerAppearance(context)
    return contextValue(context, "playerAppearance")
        or contextValue(context, "appearance")
end

local function orientation(context)
    return tostring(contextValue(context, "orientation")
        or contextValue(context, "socialOrientation") or "straight")
end

local function relationshipFemale(spec, context, seed)
    local Traits = PNC.StartingCompanionTraits
    local randomFemale = identityIndex(seed, "relationship.sex", 2) == 1
    local female = playerFemale(context)
    if Traits and Traits.ResolveCompanionFemale then
        return Traits.ResolveCompanionFemale(
            spec, female, orientation(context), randomFemale
        )
    end
    if spec.sex == "female" then return true end
    if spec.sex == "male" then return false end
    if spec.sex == "random" then return randomFemale end
    if orientation(context) == "gay" then return female end
    if orientation(context) == "bisexual" then return randomFemale end
    return not female
end

local function relationshipPolicy(spec)
    local policy = {
        id = "starting-companion:" .. tostring(spec and spec.id or "unknown"),
        bindings = {},
        -- Starter authority is applied by StartingCompanionService after
        -- character creation.  The same policy metadata is consumed by the
        -- client import sanitizer; it is not a UI-only deny list.
        serverControlledFields = {
            ["factionID"] = true,
        },
        serverControlledKeys = {
            id = true,
            uniqueDefinitionId = true,
            runtimeID = true,
            npcID = true,
            ownerID = true,
            ownerUsername = true,
            playerUUID = true,
            communityID = true,
            position = true,
            debug = true,
            debugAuthorized = true,
        },
        required = {
            ["identity.forename"] = true,
            ["identity.surname"] = true,
            ["identity.isFemale"] = true,
        },
    }
    if not spec then return policy end
    if spec.sharesSurname then
        policy.bindings["identity.surname"] = {
            mandatory = true,
            source = "inherited",
            rule = "relationship.player_surname",
            dependencies = { "player.surname" },
            editable = false,
            resolve = function(context)
                return playerSurname(context)
            end,
        }
        policy.displayNameProjection = {
            source = "derived",
            rule = "relationship.name_projection",
            dependencies = {
                "identity.forename",
                "identity.surname",
                "player.surname",
            },
            editable = false,
        }
    end
    if spec.sharesAppearance then
        policy.bindings["appearance.skinTexture"] = {
            mandatory = true,
            source = "inherited",
            rule = "relationship.family_appearance",
            dependencies = { "player.skinTexture", "player.sex" },
            editable = false,
            resolve = function(context, seedValue, blueprint, fieldID, value)
                local appearance = playerAppearance(context) or {}
                local texture = tostring(appearance.skinTexture or "")
                local index = string.match(texture, "Body(%d+)")
                if not index then return nil end
                return (relationshipFemale(spec, context, seedValue)
                    and "FemaleBody" or "MaleBody") .. index
            end,
        }
        policy.bindings["appearance.skinColor"] = {
            mandatory = true,
            source = "inherited",
            rule = "relationship.family_appearance",
            dependencies = { "player.skinColor" },
            editable = false,
            resolve = function(context)
                local appearance = playerAppearance(context) or {}
                return appearance.skinColor
            end,
        }
        policy.bindings["appearance.hairColor"] = {
            mandatory = true,
            source = "inherited",
            rule = "relationship.family_appearance",
            dependencies = { "player.hairColor" },
            editable = false,
            resolve = function(context)
                local appearance = playerAppearance(context) or {}
                return appearance.hairColor
            end,
        }
    end
    -- Random is a default for free-sex relationships, not a mandatory rule.
    if spec.sex ~= "random" then
    policy.bindings["identity.isFemale"] = {
        mandatory = true,
        source = "derived",
        rule = "relationship.sex_policy",
        dependencies = { "player.sex", "player.orientation", "slot.generationSeed" },
        editable = false,
        resolve = function(context, seedValue)
            return relationshipFemale(spec, context, seedValue)
        end,
    }
    end
    return policy
end

Resolver.Policies = Resolver.Policies or {}
Resolver.Policies.Debug = Resolver.Policies.Debug or {
    id = "unique-npc-debug",
    bindings = {},
    required = {
        ["identity.forename"] = true,
        ["identity.surname"] = true,
        ["identity.isFemale"] = true,
    },
}

function Resolver.PolicyForStartingCompanion(spec)
    return relationshipPolicy(spec)
end

local function generatedIdentityField(fieldID, context, seed)
    local IdentityNames = PNC.IdentityNames
    local female = contextValue(context, "isFemale")
    local generated
    local forename
    local surname
    if fieldID == "identity.isFemale" then
        return identityIndex(seed, "identity.gender", 2) == 1
    end
    if (fieldID == "identity.forename" or fieldID == "identity.surname")
        and IdentityNames and IdentityNames.Generate
    then
        generated = IdentityNames.Generate(
            seed,
            female == true,
            contextValue(context, "archetypeID"),
            { namespace = "projecthoomans.identity.authoring" }
        )
        forename, surname = string.match(tostring(generated or ""), "^(%S+)%s+(.+)$")
        if fieldID == "identity.forename" then return forename end
        if fieldID == "identity.surname" then return surname end
    end
    if fieldID == "identity.forename" then
        return "Alex" .. tostring(identityMix(seed, "forename") % 97)
    end
    if fieldID == "identity.surname" then
        return "Companion" .. tostring(identityMix(seed, "surname") % 97)
    end
    return nil
end

local function generatedValue(field, context, seedValue, blueprint)
    local value
    if field.generate then
        value = field.generate(context, seedValue, blueprint)
    end
    if value == nil then
        value = generatedIdentityField(field.id, context, seedValue)
    end
    return value
end

local function traceEntry(fieldID, source, value, binding, editable)
    local output = {
        fieldID = fieldID,
        source = source,
        rule = binding and binding.rule or nil,
        dependencies = binding and copy(binding.dependencies or {}) or {},
        editable = editable ~= false,
    }
    if value ~= nil then output.value = copy(value) end
    return output
end

local function setResolved(outputBlueprint, fieldID, value)
    local nextBlueprint
    if value == nil then return outputBlueprint, "value_missing" end
    nextBlueprint = Blueprint.Set(outputBlueprint, fieldID, value)
    if not nextBlueprint then return nil, "resolved_field_invalid:" .. tostring(fieldID) end
    return nextBlueprint
end

local function projectDisplayName(outputBlueprint, authoredBlueprint, trace,
    policy)
    local projection = policy and policy.displayNameProjection
    local surnameState
    local surname
    local forenameState
    local forename
    local displayState
    local displayValue
    local derivedForename
    local derivedDisplayName
    local reason
    local binding
    if not projection then return outputBlueprint end
    surnameState, surname = Blueprint.Get(
        outputBlueprint, "identity.surname")
    if surnameState ~= "value" or not surname then
        return outputBlueprint
    end
    forenameState, forename = Blueprint.Get(
        outputBlueprint, "identity.forename")
    displayState, displayValue = Blueprint.Get(
        authoredBlueprint, "identity.displayName")
    if forenameState ~= "value" and displayState == "value" then
        derivedForename = string.match(tostring(displayValue), "^(%S+)")
        if derivedForename then
            outputBlueprint, reason = setResolved(
                outputBlueprint, "identity.forename", derivedForename)
            if not outputBlueprint then return nil, reason end
            trace.fields["identity.forename"] = traceEntry(
                "identity.forename",
                "derived",
                derivedForename,
                {
                    rule = "identity.display_name_parts",
                    dependencies = { "identity.displayName" },
                },
                false
            )
            forename = derivedForename
        end
    end
    if not forename then
        forenameState, forename = Blueprint.Get(
            outputBlueprint, "identity.forename")
    end
    if not forename then return outputBlueprint end
    derivedDisplayName = tostring(forename) .. " " .. tostring(surname)
    outputBlueprint, reason = setResolved(
        outputBlueprint, "identity.displayName", derivedDisplayName)
    if not outputBlueprint then return nil, reason end
    binding = {
        rule = projection.rule,
        dependencies = projection.dependencies,
    }
    trace.fields["identity.displayName"] = traceEntry(
        "identity.displayName",
        projection.source or "derived",
        derivedDisplayName,
        binding,
        projection.editable ~= false
    )
    return outputBlueprint
end

function Resolver.ResolvePlan(blueprint, context, policy, options)
    local normalized
    local reason
    local outputBlueprint
    local trace
    local seedValue
    local fields
    local binding
    local explicitState
    local explicitValue
    local value
    local source
    local editable
    local fieldID
    local field
    local authoritative
    local dependencies
    local displayNameState
    local count = 0
    context = type(context) == "table" and context or {}
    policy = policy or Resolver.Policies.Debug
    options = type(options) == "table" and options or {}
    normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return nil, reason end
    -- Validate field shape and clear semantics before applying context.  The
    -- resolver may fill generated or bound required fields, so this
    -- pre-resolution check deliberately omits resolved-field requirements.
    local structurallyValid
    structurallyValid, reason = Blueprint.Validate(normalized, {
        bindings = policy.bindings,
        required = {},
    })
    if not structurallyValid then return nil, reason end
    seedValue = normalized.generationSeed
        or context.generationSeed
        or context.seed
        or Registry.Hash("resolver")
    outputBlueprint = Blueprint.Clone(normalized)
    trace = {
        schemaId = Blueprint.SCHEMA_ID,
        schemaVersion = Blueprint.SCHEMA_VERSION,
        policy = policy.id,
        generationSeed = seedValue,
        fields = {},
        count = 0,
    }
    fields = Registry.List()
    authoritative = context.authoritativeFields or {}
    displayNameState = Blueprint.Get(normalized, "identity.displayName")
    for _, field in ipairs(fields) do
        if field.authorable then
            count = count + 1
            if count > Registry.MAX_FIELDS then return nil, "resolution_trace_limit" end
            fieldID = field.id
            binding = policy.bindings and policy.bindings[fieldID] or nil
            if binding and not field.bindingAllowed then
                return nil, "field_binding_not_allowed:" .. fieldID
            end
            explicitState, explicitValue = Blueprint.Get(normalized, fieldID)
            value = authoritative[fieldID]
            if value ~= nil then
                source = "authoritative"
                editable = false
                outputBlueprint, reason = setResolved(outputBlueprint, fieldID, value)
                if not outputBlueprint then return nil, reason end
                trace.fields[fieldID] = traceEntry(
                    fieldID, source, value,
                    { rule = "authoritative.runtime", dependencies = { "runtime.authority" } },
                    editable
                )
            elseif binding then
                if binding.resolve then
                    value = binding.resolve(
                        context, seedValue, normalized, fieldID, explicitValue
                    )
                else
                    value = nil
                end
                if value ~= nil then
                    source = binding.source or "derived"
                    editable = binding.editable ~= false
                    outputBlueprint, reason = setResolved(outputBlueprint, fieldID, value)
                    if not outputBlueprint then return nil, reason end
                    local entry = traceEntry(fieldID, source, value, binding, editable)
                    if explicitState == "clear" then entry.clearIgnored = true end
                    trace.fields[fieldID] = entry
                elseif binding.mandatory then
                    return nil, "mandatory_binding_unresolved:" .. fieldID
                elseif explicitState == "value" then
                    outputBlueprint, reason = setResolved(outputBlueprint, fieldID, explicitValue)
                    if not outputBlueprint then return nil, reason end
                    trace.fields[fieldID] = traceEntry(
                        fieldID, "explicit", explicitValue, nil, true
                    )
                else
                    trace.fields[fieldID] = traceEntry(
                        fieldID, "generated", nil, binding, true
                    )
                end
            elseif explicitState == "value" then
                trace.fields[fieldID] = traceEntry(
                    fieldID, "explicit", explicitValue, nil, true
                )
            elseif explicitState == "clear" then
                trace.fields[fieldID] = traceEntry(
                    fieldID, "explicit", nil,
                    { rule = "explicit-clear", dependencies = {} }, true
                )
            else
                value = generatedValue(field, context, seedValue, normalized)
                if (fieldID == "identity.forename"
                    or fieldID == "identity.surname")
                    and displayNameState == "value"
                then
                    -- Identity.GenerateResolvedIdentity owns parsing an
                    -- explicit display name.  Do not replace its forename or
                    -- surname with a second generated truth.
                    value = nil
                end
                if value ~= nil then
                    outputBlueprint, reason = setResolved(outputBlueprint, fieldID, value)
                    if not outputBlueprint then return nil, reason end
                    trace.fields[fieldID] = traceEntry(
                        fieldID, "generated", value, nil, true
                    )
                end
            end
        end
    end
    outputBlueprint, reason = projectDisplayName(
        outputBlueprint, normalized, trace, policy)
    if not outputBlueprint then return nil, reason end
    trace.count = count
    return {
        blueprint = outputBlueprint,
        definition = Blueprint.ToDefinition(outputBlueprint, {
            id = options.id or normalized.id,
            version = options.version,
        }),
        trace = trace,
        blueprintFingerprint = Blueprint.Fingerprint(normalized),
    }
end

function Resolver.Resolve(blueprint, context, policy, options)
    local plan, reason = Resolver.ResolvePlan(blueprint, context, policy, options)
    if not plan then return nil, reason end
    return plan.definition, plan.trace
end

function Resolver.AttachIdentityTrace(trace, identity)
    local output = copy(trace or {})
    output.fields = output.fields or {}
    local survivor = identity and identity.survivor or {}
    local values = {
        ["identity.displayName"] = identity and identity.displayName or nil,
        ["identity.forename"] = survivor and survivor.forename or nil,
        ["identity.surname"] = survivor and survivor.surname or nil,
        ["identity.nickname"] = identity and identity.nickname or nil,

        ["appearance.hairModel"] = survivor and survivor.hairModel or nil,
        ["appearance.beardModel"] = survivor and survivor.beardModel or nil,
        ["appearance.skinTexture"] = survivor and survivor.skinTexture or nil,
        ["appearance.skinColor"] = survivor and survivor.skinColor or nil,
        ["appearance.hairColor"] = survivor and survivor.hairColor or nil,
    }
    if identity then values["identity.isFemale"] = identity.isFemale end
    local fieldID
    local value
    for fieldID, value in pairs(values) do
        if value ~= nil then
            if not output.fields[fieldID] then
                output.fields[fieldID] = traceEntry(
                    fieldID, "generated", value, nil, true
                )
                output.count = (tonumber(output.count) or 0) + 1
            else
                output.fields[fieldID].value = copy(value)
            end
        end
    end
    return output
end

function Resolver.BuildResolutionSummary(trace, limit)
    local output = {}
    local fields = trace and trace.fields or {}
    local ids = {}
    local maximum = math.max(1, math.floor(tonumber(limit) or 64))
    for fieldID in pairs(fields) do ids[#ids + 1] = fieldID end
    table.sort(ids)
    for index = 1, math.min(#ids, maximum) do
        output[#output + 1] = copy(fields[ids[index]])
    end
    return output
end

return Resolver
