-- Compact, client-owned snapshot adapter for HoomansLLM.
--
-- Project Hoomans remains authoritative for all gameplay data. This module
-- only selects a bounded presentation of canonical client replicas for the
-- Python conversation service; it never writes a relationship, task, item,
-- faction, health, or combat value.

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Context = PNC.HoomansLLM.Context or {}

local Context = PNC.HoomansLLM.Context
local Message = PsychopatzCore.Conversation.Message
local ToolPolicy = PNC.ConversationLLMTools

local NEED_TYPES = { "hunger", "thirst", "fatigue" }
local NEED_LEVEL_WEIGHT = {
    NORMAL = 0,
    MINOR = 1,
    MODERATE = 2,
    SEVERE = 3,
    CRITICAL = 4,
}
local needsCache = {}
local needsCacheOrder = {}
local NEED_CACHE_LIMIT = 32

local function text(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function sourceFor(entry)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local id = tostring(entry and entry.id or "")
    local primary = entry and (entry.snapshot or entry.record) or nil
    local replica = state.snapshots and state.snapshots[id] or nil
    if type(primary) ~= "table" then return replica or {} end
    if type(replica) ~= "table" or replica.needs == nil then return primary end
    local merged = {}
    for key, value in pairs(primary) do merged[key] = value end
    for key, value in pairs(replica) do merged[key] = value end
    return merged
end

local function copyMap(source, keys)
    local output = {}
    if type(source) ~= "table" then return output end
    for _, key in ipairs(keys) do
        if source[key] ~= nil then output[key] = source[key] end
    end
    return output
end

local function buildNeedsDigest(npcID, source)
    local values = source and source.needs
    if type(values) ~= "table" then return nil end
    local signatureParts = {}
    local digest = {}
    local highestType = nil
    local highestLevel = "NORMAL"
    local highestWeight = -1
    for _, needType in ipairs(NEED_TYPES) do
        local value = tonumber(values[needType])
        if value ~= nil then
            value = math.max(0, math.min(1, value))
            signatureParts[#signatureParts + 1] = needType .. ":" .. tostring(value)
            digest[needType] = value
            local definitions = PNC.NeedsDefinitions
            local level = definitions and definitions.GetLevel
                and definitions.GetLevel(needType, value) or nil
            if level then
                digest[needType .. "_level"] = level
                local weight = NEED_LEVEL_WEIGHT[level] or 0
                if weight > highestWeight then
                    highestWeight = weight
                    highestType = needType
                    highestLevel = level
                end
            end
        end
    end
    if #signatureParts == 0 then return nil end
    local id = tostring(npcID or "unknown-npc")
    local signature = table.concat(signatureParts, "|")
    local cached = needsCache[id]
    if cached and cached.signature == signature then
        return cached.digest
    end
    digest.highest = highestType
    digest.urgency = string.lower(highestLevel)
    digest.revision = (cached and cached.revision or 0) + 1
    digest.sampled_at = tonumber(
        source.needsSampledAt or source.snapshotAt or values.sampledAt
    )
    needsCache[id] = {
        signature = signature,
        revision = digest.revision,
        digest = digest,
    }
    if not cached then
        needsCacheOrder[#needsCacheOrder + 1] = id
        while #needsCacheOrder > NEED_CACHE_LIMIT do
            local oldest = table.remove(needsCacheOrder, 1)
            if oldest ~= id then needsCache[oldest] = nil end
        end
    end
    return digest
end

function Context.ResetTransientState()
    needsCache = {}
    needsCacheOrder = {}
end

local function compactParticipants(view, npcID, npcName, playerID, playerName)
    local output = {}
    local seen = {}
    local session = view and view.session or {}
    local values = session.participants or {}
    for index = 1, math.min(#values, 16) do
        local participant = values[index]
        local id = type(participant) == "table"
            and (participant.id or participant.speakerID)
            or participant
        id = text(id, nil)
        if id and not seen[id] then
            seen[id] = true
            output[#output + 1] = {
                id = id,
                name = type(participant) == "table"
                    and (participant.name or participant.speakerName) or id,
                kind = type(participant) == "table"
                    and (participant.kind or participant.speakerKind) or "npc",
                active = type(participant) ~= "table" or participant.active ~= false,
            }
        end
    end
    if not seen[playerID] then
        output[#output + 1] = {
            id = playerID, name = playerName, kind = "player", active = true,
        }
    end
    if not seen[npcID] then
        output[#output + 1] = {
            id = npcID, name = npcName, kind = "npc", active = true,
        }
    end
    return output
end

local function worldUUID()
    if Message and Message.GetSaveID then
        return Message.GetSaveID()
    end
    -- getCurrentSaveName is a Build 42 Lua global backed by the current save
    -- directory. It is stable for a save and available to client Lua.
    local saveName = getCurrentSaveName and getCurrentSaveName()
        or getWorld and getWorld()
        or "default"
    return "pz-save:" .. text(saveName, "default")
end

local function playerUUID(view)
    local context = view and view.spec and view.spec.context or {}
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = clientState.playerContext or {}
    return text(
        playerContext.characterUUID
            or context.characterUUID
            or view and view.spec and view.spec.characterUUID,
        "unbound-player"
    )
end

local function isProviderFailure(message, content)
    local speaker = tostring(message and (message.speakerKind or message.speaker) or "")
    if speaker ~= "npc" then return false end

    if Message and Message.IsLLMContextEligible then
        return not Message.IsLLMContextEligible(message, content)
    end

    local source = message and message.source
    if type(source) ~= "table" then source = {} end
    if source.contextEligible == false
        or source.providerFailure == true
        or source.excludeFromLLM == true
    then
        return true
    end

    -- History predates source metadata, so retain a narrow compatibility
    -- filter for fallback text that was already persisted to a save.
    local lowered = string.lower(tostring(content or ""))
    return string.find(lowered, "i cannot answer right now", 1, true) ~= nil
        or string.find(lowered, "provider request failed", 1, true) ~= nil
        or string.find(lowered, "provider returned an empty response", 1, true) ~= nil
        or string.find(lowered, "openai-compatible provider", 1, true) ~= nil
end

local function recentConversation(view, currentMessage)
    local history = view and view.historyPart and view.historyPart.messages or {}
    local output = {}
    local first = math.max(1, #history - 7)
    local textResolver = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    for index = first, #history do
        local message = history[index]
        local payload = message and (message.payload or message) or nil
        local content = textResolver and textResolver.Resolve
            and textResolver.Resolve(payload) or ""
        content = text(content, nil)
        if content
            and not isProviderFailure(message, content)
            and not (index == #history and content == currentMessage)
        then
            output[#output + 1] = {
                role = message and message.speaker == "player"
                    and "user" or "assistant",
                content = string.sub(content, 1, 500),
            }
        end
    end
    return output
end

local function availableTools(entry)
    local seen = { social_react = true }
    local output = {
        ToolPolicy and ToolPolicy.BuildDefinition
            and ToolPolicy.BuildDefinition()
            or {
                type = "function",
                ["function"] = {
                    name = "social_react",
                    description = "Express a bounded social reaction; gameplay authority decides whether it applies.",
                    parameters = {
                        type = "object",
                        properties = {
                            kind = { type = "string" },
                            intensity = { type = "string" },
                        },
                        additionalProperties = false,
                    },
                },
            },
    }
    local commands = PNC.CompanionCommands
    if not commands or not commands.List then return output end
    for _, definition in ipairs(commands.List()) do
        local commandID = text(definition and definition.id, nil)
        if commandID and definition.clientOnly ~= true and #output < 12 then
            local safeCommandID = string.gsub(commandID, "[^%w%-_]", "_")
            local toolName = "order_" .. string.sub(safeCommandID, 1, 52)
            if not seen[toolName] then
                seen[toolName] = true
                output[#output + 1] = {
                    type = "function",
                    ["function"] = {
                        name = toolName,
                        description = "Request the Project Hoomans order '" .. commandID
                            .. "'; authority validates it.",
                        parameters = {
                            type = "object",
                            properties = {
                                command_id = {
                                    type = "string",
                                    enum = { commandID },
                                    description = "The exact command ID to validate.",
                                },
                            },
                            required = { "command_id" },
                            additionalProperties = false,
                        },
                    },
                }
            end
        end
    end
    return output
end

function Context.GetToolDefinitions(entry)
    return availableTools(entry)
end

local function toolCatalogReference(definitions)
    local bridge = PsychopatzCore and PsychopatzCore.Bridge
    if not bridge or type(bridge.GetToolCatalog) ~= "function" then
        return nil, nil
    end
    local catalog = bridge.GetToolCatalog()
    local catalogID = catalog and text(catalog.catalog_id, nil)
    local rows = catalog and catalog.tools or nil
    if not catalogID or type(rows) ~= "table" then return nil, nil end
    local known = {}
    for _, row in ipairs(rows) do
        local id = text(row and row.id, nil)
        if id then known[id] = true end
    end
    local IDs = {}
    for _, tool in ipairs(definitions or {}) do
        local definition = tool and tool["function"] or nil
        local name = text(definition and definition.name, nil)
        local id = name and "projecthoomans.llm:" .. name or nil
        if not id or not known[id] then return nil, nil end
        IDs[#IDs + 1] = id
    end
    return catalogID, IDs
end

function Context.Build(view, message)
    local definition = view and view.spec or {}
    local presentation = definition.context or {}
    local block = presentation.conversationBlockContext or {}
    local entry = presentation.entry or {}
    local source = sourceFor(entry)
    local identity = source.identity or {}
    local npcID = text(definition.npcID or entry.id, "unknown-npc")
    local npcName = text(presentation.npcName, npcID)
    local playerName = text(presentation.playerName, "the player")
    local playerID = playerUUID(view)
    local worldHours = tonumber(
        Message and Message.GetWorldAgeHours and Message.GetWorldAgeHours()
            or presentation.worldAgeHours
    ) or 0
    local lifecycle = presentation.conversationLifecycleState or {}
    local gameDay = Message and Message.GetGameDay
        and Message.GetGameDay(worldHours)
        or math.floor(worldHours / 24)
    local participants = compactParticipants(
        view, npcID, npcName, playerID, playerName
    )
    local relationship = presentation.relationship
        or presentation.relationshipSnapshot
        or PNC.Conversation and PNC.Conversation.Relationship
        and PNC.Conversation.Relationship.GetPresentation
        and PNC.Conversation.Relationship.GetPresentation(npcID)
        or {}
    local personality = block.npcPersonality
        or source.socialProfile
        or source.personality
        or source.social and source.social.personality
        or {}
    local traits = block.npcTraits
        or source.vanillaTraits
        or source.traits
        or source.socialTraits
        or {}
    local preferences = source.preferences or entry.preferences or {}
    local state = copyMap(source, {
        "aiState", "activeBehavior", "activeJob", "orderKind", "attackType",
        "inCombat", "attackMode", "healthState", "staminaState",
        "presenceState", "weaponMode", "weaponStatus", "tacticalClass",
    })
    local needs = buildNeedsDigest(npcID, source)
    if needs then state.needs = needs end
    local voiceProfile = PNC.NPCVoice
        and PNC.NPCVoice.GetProfile
        and PNC.NPCVoice.GetProfile(source, entry.zombie)
        or nil
    local characterCard = {
        archetype = text(source.archetypeLabel or identity.archetypeLabel, nil),
        archetype_id = text(source.archetypeID or identity.archetypeID, nil),
        role = text(presentation.factionRole or presentation.npcType, "survivor"),
        traits = traits,
        personality = personality,
    }
    local definitions = availableTools(entry)
    local catalogID, availableToolIDs = toolCatalogReference(definitions)
    local context = {
        world_uuid = worldUUID(),
        player_uuid = playerID,
        npc_uuid = npcID,
        conversation_id = view.session and view.session.llmSessionID or nil,
        conversation_token = text(lifecycle.token, nil),
        voice_binding = voiceProfile and {
            npc_uuid = npcID,
            slot = tostring(voiceProfile.prefix or "")
                .. ":" .. tostring(voiceProfile.voiceType or 0),
            pitch = tonumber(voiceProfile.pitch) or 0,
        } or nil,
        npc_name = npcName,
        player_name = playerName,
        game_day = gameDay,
        world_age_hours = worldHours,
        participants = participants,
        scene = {
            participants = participants,
            active_participants = participants,
            current_speaker_id = npcID,
            addressed_targets = { playerID },
            current_topic = text(
                presentation.conversationTopic or block.topic,
                nil
            ),
        },
        current_topic = text(
            presentation.conversationTopic or block.topic,
            nil
        ),
        message = string.sub(text(message, ""), 1, 4000),
        tool_ack_text = "I'll check that now.",
        character_card = characterCard,
        relationship_snapshot = relationship,
        relationship_capabilities = {
            state = relationship.state or relationship.category,
            revision = relationship.revision,
            available_reactions = ToolPolicy and ToolPolicy.ListAvailable
                and ToolPolicy.ListAvailable(relationship) or {},
        },
        preferences = preferences,
        current_state = state,
        recent_conversation = recentConversation(view, text(message, "")),
        session_id = view.session and view.session.llmSessionID or nil,
        metadata = {
            source = "project-hoomans",
            relationship_state = text(presentation.conversationRelationshipID, "unknown"),
            world_age_hours = worldHours,
            game_day = gameDay,
            needs_revision = needs and needs.revision or nil,
        },
    }
    if catalogID then
        context.tool_catalog_id = catalogID
        context.available_tool_ids = availableToolIDs
    else
        -- Compatibility path for older Core builds and non-catalog bridges.
        context.available_tools = definitions
    end
    return context
end

return Context
