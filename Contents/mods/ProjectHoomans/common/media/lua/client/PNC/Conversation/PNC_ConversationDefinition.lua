PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Time = Conversation.Time
local Content = Conversation.Content
local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local Palette = PNC.NPCTypePalette

local function roleLabel(value)
    value = tostring(value or "")
    local output = {}
    local capitalize = true
    local index
    for index = 1, #value do
        local character = string.sub(value, index, index)
        if character == "_" then
            output[#output + 1] = " "
            capitalize = true
        else
            if capitalize then
                character = string.upper(character)
                capitalize = false
            end
            output[#output + 1] = character
        end
    end
    -- Build 42.20's Kahlua string.gsub callback does not reliably pass
    -- every capture. Role IDs are normalized lowercase identifiers, so a
    -- small deterministic loop is safer than callback-based title casing.
    return table.concat(output)
end

Conversation.FormatRoleLabel = roleLabel

local function isAggressive(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local hostility = snapshot.hostility or record.hostility or {}
    return tostring(snapshot.faction or record.faction or "")
        == "hostile"
        and hostility.attackPlayers ~= false
end

function Conversation.RequestCeasefire(context)
    return Lifecycle and Lifecycle.RequestCeasefire
        and Lifecycle.RequestCeasefire(context)
        or false
end

function Conversation.HandleCeasefireResult(args)
    args = type(args) == "table" and args or {}
    Conversation.lastCeasefireResult = args
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(
            player,
            getText(args.ok == true
                and "UI_PNC_Conversation_CeasefireAccepted"
                or "UI_PNC_Conversation_CeasefireRejected")
        )
    end
    return args.ok == true, args.reason
end

local function factionPresentation(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local faction = snapshot.organizationalFaction
        or record.organizationalFaction
    if type(faction) ~= "table" then return nil end
    local name = tostring(faction.name or "")
    local role = roleLabel(
        faction.role or faction.rank
    )
    if name == "" or role == "" then return nil end
    return {
        name = name,
        role = role,
        id = faction.id,
        emblem = faction.emblem,
    }
end

local function portraitSpec(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    return {
        id = entry and entry.id,
        key = table.concat({
            tostring(entry and entry.id or ""),
            tostring(snapshot.identitySeed or record.identitySeed or 1),
            tostring(snapshot.presenceRevision or 0),
        }, "|"),
        identitySeed = snapshot.identitySeed or record.identitySeed or 1,
        isFemale = snapshot.isFemale == true or record.isFemale == true,
        preferDescriptor = entry and entry.zombie == nil,
        faceOnly = true,
        appearance = snapshot.appearance or record.appearance or {},
        equipment = snapshot.equipmentSummary or record.equipment or { worn = {} },
    }
end

function Conversation.BuildDefinition(entry, player, forcedTime)
    local timeID = forcedTime or Time.Resolve()
    local relationshipID = Relationship.Resolve(entry, player)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local name = tostring(entry and entry.name or "NPC")
    local day = PsychopatzCore.Conversation.History.GetDay()
    local greeting = Content.GetGreeting(
        relationshipID,
        timeID,
        npcID,
        day
    )
    local faction = factionPresentation(entry)
    local aggressive = isAggressive(entry)
    local relationshipPresentation = Relationship.GetPresentation(npcID)
    local greetingChoices
    local debugStandingChoices = {}
    local debugEventChoices = {}
    local debugMenuChoices = {}
    if aggressive then
        greetingChoices = {
            {
                id = "ceasefire",
                textKey = "UI_PNC_Conversation_ChoiceCeasefire",
                response = {
                    key = "UI_PNC_Conversation_ResponseCeasefire",
                },
                action = function(context)
                    Conversation.RequestCeasefire(context)
                end,
                next = "ceasefire",
            },
            {
                id = "goodbye",
                textKey = "UI_PNC_Conversation_ChoiceGoodbye",
                response = {
                    key = "UI_PNC_Conversation_ResponseGoodbye",
                },
                close = true,
            },
        }
    else
        greetingChoices = {
            {
                id = "condition",
                textKey = "UI_PNC_Conversation_ChoiceCondition",
                response = {
                    key = "UI_PNC_Conversation_ResponseCondition",
                },
                next = "followup",
            },
            {
                id = "situation",
                textKey = "UI_PNC_Conversation_ChoiceSituation",
                response = {
                    key = "UI_PNC_Conversation_ResponseSituation",
                },
                next = "followup",
            },
            {
                id = "goodbye",
                textKey = "UI_PNC_Conversation_ChoiceGoodbye",
                response = {
                    key = "UI_PNC_Conversation_ResponseGoodbye",
                },
                close = true,
            },
        }
    end
    if PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug()
    then
        local standingOrder = {
            "admire", "pity", "fear", "despise", "indifferent",
        }
        greetingChoices[#greetingChoices + 1] = {
            id = "debug_relationship",
            text = "DEBUG: Relationship tools",
            next = "debug_relationship",
        }
        debugMenuChoices[#debugMenuChoices + 1] = {
            id = "debug_open_laboratory",
            text = "Open relationship laboratory",
            response = {
                fallback = "Opened the relationship laboratory for this NPC.",
            },
            action = function()
                Relationship.OpenLaboratory(npcID)
            end,
            next = "debug_relationship",
        }
        debugMenuChoices[#debugMenuChoices + 1] = {
            id = "debug_synthetic_baseline",
            text = "Set synthetic relationship baseline",
            next = "debug_synthetic_baseline",
        }
        debugMenuChoices[#debugMenuChoices + 1] = {
            id = "debug_social_event",
            text = "Trigger real social event",
            next = "debug_social_events",
        }
        debugMenuChoices[#debugMenuChoices + 1] = {
            id = "debug_toggle_relation_card",
            text = "Toggle current-relation graph",
            response = {
                fallback = "Toggled the current-relation graph.",
            },
            action = function()
                Relationship.SetPresentationVisible(
                    not Relationship.IsPresentationVisible()
                )
            end,
            next = "debug_relationship",
        }
        for _, standingID in ipairs(standingOrder) do
            local preset = PNC.RelationshipPresentation
                and PNC.RelationshipPresentation.GetDebugStandingPreset
                and PNC.RelationshipPresentation.GetDebugStandingPreset(
                    standingID
                ) or nil
            if preset then
                local selectedID = standingID
                debugStandingChoices[#debugStandingChoices + 1] = {
                    id = "debug_standing_" .. selectedID,
                    text = "DEBUG: " .. tostring(preset.label),
                    response = {
                        fallback = "Debug relationship standing updated.",
                    },
                    action = function()
                        Relationship.ApplyDebugStanding(npcID, selectedID)
                    end,
                    next = "debug_synthetic_baseline",
                }
            end
        end
        debugStandingChoices[#debugStandingChoices + 1] = {
            id = "debug_synthetic_back",
            text = "Back",
            next = "debug_relationship",
        }
        local socialEvents = {
            { id = "treated_wound", label = "Treat wound" },
            { id = "saved_from_incapacitation", label = "Save from incapacitation" },
            { id = "protected_from_attacker", label = "Protect from attacker" },
            { id = "survived_combat_together", label = "Survive combat together" },
            { id = "abandoned_in_combat", label = "Abandon in combat" },
        }
        for _, event in ipairs(socialEvents) do
            local eventID = event.id
            debugEventChoices[#debugEventChoices + 1] = {
                id = "debug_event_" .. eventID,
                text = "DEBUG: " .. event.label,
                response = {
                    fallback = "Debug social event sent through the relationship pipeline.",
                },
                action = function()
                    Relationship.TriggerDebugEvent(npcID, eventID)
                end,
                next = "debug_social_events",
            }
        end
        debugEventChoices[#debugEventChoices + 1] = {
            id = "debug_events_back",
            text = "Back",
            next = "debug_relationship",
        }
        debugMenuChoices[#debugMenuChoices + 1] = {
            id = "debug_relationship_back",
            text = "Back",
            next = "followup",
        }
    end
    greetingChoices[#greetingChoices + 1] = {
        id = "view_dossier",
        text = "View dossier",
        response = { fallback = "Opening your notes about this survivor." },
        action = function() Relationship.OpenDossier(npcID) end,
        next = "greeting",
    }
    return {
        namespace = "ProjectHoomans",
        npcID = npcID,
        character = entry and entry.zombie or nil,
        portrait = portraitSpec(entry),
        backgroundID = Content.GetBackground(timeID),
        theme = Palette.BuildConversationTheme(entry),
        context = {
            entry = entry,
            player = player,
            npcName = name,
            -- PsychopatzCore currently renders these two context fields as
            -- the portrait subtitle. Preserve the semantic IDs separately
            -- while showing faction identity when the server supplied it.
            timeID = faction and faction.role or timeID,
            relationshipID =
                faction and faction.name or relationshipID,
            conversationTimeID = timeID,
            conversationRelationshipID = relationshipID,
            factionID = faction and faction.id or nil,
            factionName = faction and faction.name or nil,
            factionRole = faction and faction.role or nil,
            factionEmblem = faction and faction.emblem or nil,
            npcType = Palette.ResolveType(entry),
            allowHostileParley = aggressive,
        },
        extensionParts = {
            {
                partID = "relationship",
                factory = Conversation.CreateRelationshipPanel,
                relationship = relationshipPresentation,
                visible = Relationship.IsPresentationVisible(),
                title = { fallback = "CURRENT RELATION" },
                editLabel = { fallback = "Current relation" },
            },
        },
        lifecycle = Lifecycle.Create(),
        start = "greeting",
        nodes = {
            greeting = {
                npc = greeting,
                choices = greetingChoices,
            },
            ceasefire = {
                npc = { key = "UI_PNC_Conversation_ResponseCeasefire" },
                choices = {
                    {
                        id = "goodbye",
                        textKey = "UI_PNC_Conversation_ChoiceGoodbye",
                        response = {
                            key = "UI_PNC_Conversation_ResponseGoodbye",
                        },
                        close = true,
                    },
                },
            },
            followup = {
                choices = {
                    {
                        id = "anything_else",
                        textKey = "UI_PNC_Conversation_ChoiceAnythingElse",
                        response = {
                            key = "UI_PNC_Conversation_ResponseAnythingElse",
                        },
                        next = "followup",
                    },
                    {
                        id = "view_dossier",
                        text = "View dossier",
                        response = { fallback = "Opening your notes about this survivor." },
                        action = function() Relationship.OpenDossier(npcID) end,
                        next = "followup",
                    },
                    {
                        id = "goodbye",
                        textKey = "UI_PNC_Conversation_ChoiceGoodbye",
                        response = {
                            key = "UI_PNC_Conversation_ResponseGoodbye",
                        },
                        close = true,
                    },
                },
            },
            debug_relationship = {
                npc = {
                    fallback = "Debug relationship tools for the current player.",
                },
                choices = debugMenuChoices,
            },
            debug_synthetic_baseline = {
                npc = {
                    fallback = "Debug: set a synthetic relationship baseline. This preserves memories and other relationship history.",
                },
                choices = debugStandingChoices,
            },
            debug_social_events = {
                npc = {
                    fallback = "Debug: trigger a real social event through the authoritative relationship pipeline.",
                },
                choices = debugEventChoices,
            },
        },
    }
end

function Conversation.Open(entry, player, forcedTime)
    local definition = Conversation.BuildDefinition(entry, player, forcedTime)
    local view = PsychopatzCore.Conversation.Open(
        definition
    )
    Relationship.RequestPresentation(definition.npcID)
    return view
end

return Conversation
