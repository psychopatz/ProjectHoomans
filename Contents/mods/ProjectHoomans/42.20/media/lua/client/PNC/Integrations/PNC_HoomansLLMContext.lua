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

local function text(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function sourceFor(entry)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local id = tostring(entry and entry.id or "")
    return entry and (entry.snapshot or entry.record)
        or state.snapshots and state.snapshots[id] or {}
end

local function copyMap(source, keys)
    local output = {}
    if type(source) ~= "table" then return output end
    for _, key in ipairs(keys) do
        if source[key] ~= nil then output[key] = source[key] end
    end
    return output
end

local function worldUUID()
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
        if content and not (index == #history and content == currentMessage) then
            output[#output + 1] = {
                role = message.speaker == "player" and "user" or "assistant",
                content = string.sub(content, 1, 500),
            }
        end
    end
    return output
end

local function availableTools(entry)
    local seen = { social_react = true }
    local output = {
        {
            type = "function",
            ["function"] = {
                -- OpenAI-compatible function names may only contain letters,
                -- numbers, underscores, and hyphens.
                name = "social_react",
                description = "Express a social reaction intent; gameplay decides whether it applies.",
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
    local context = {
        world_uuid = worldUUID(),
        player_uuid = playerUUID(view),
        npc_uuid = npcID,
        conversation_id = view.session and view.session.llmSessionID or nil,
        voice_binding = voiceProfile and {
            npc_uuid = npcID,
            slot = tostring(voiceProfile.prefix or "")
                .. ":" .. tostring(voiceProfile.voiceType or 0),
            pitch = tonumber(voiceProfile.pitch) or 0,
        } or nil,
        npc_name = npcName,
        player_name = playerName,
        message = string.sub(text(message, ""), 1, 4000),
        character_card = characterCard,
        relationship_snapshot = relationship,
        preferences = preferences,
        current_state = state,
        available_tools = availableTools(entry),
        recent_conversation = recentConversation(view, text(message, "")),
        session_id = view.session and view.session.llmSessionID or nil,
        metadata = {
            source = "project-hoomans",
            relationship_state = text(presentation.conversationRelationshipID, "unknown"),
            world_age_hours = tonumber(presentation.worldAgeHours) or 0,
        },
    }
    return context
end

return Context
