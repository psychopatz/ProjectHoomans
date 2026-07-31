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
    value = string.gsub(value, "_", " ")
    return string.gsub(
        value,
        "(%a)([%w']*)",
        function(first, rest)
            -- Build 42.20's Kahlua string library does not expose
            -- string.lower() reliably. Faction role IDs are normalized to
            -- lowercase at the persistence boundary, so title-casing only
            -- the first character is both sufficient and runtime-safe.
            return string.upper(first)
                .. rest
        end
    )
end

Conversation.FormatRoleLabel = roleLabel

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
        },
        lifecycle = Lifecycle.Create(),
        start = "greeting",
        nodes = {
            greeting = {
                npc = greeting,
                choices = {
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
                        id = "goodbye",
                        textKey = "UI_PNC_Conversation_ChoiceGoodbye",
                        response = {
                            key = "UI_PNC_Conversation_ResponseGoodbye",
                        },
                        close = true,
                    },
                },
            },
        },
    }
end

function Conversation.Open(entry, player, forcedTime)
    return PsychopatzCore.Conversation.Open(
        Conversation.BuildDefinition(entry, player, forcedTime)
    )
end

return Conversation
