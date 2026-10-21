-- Build the extension specs included in a conversation definition.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Relationship = Conversation.Relationship
local ExtensionParts = {}

-- The suggestion panel is an ordinary Hoomans extension part on the existing
-- Core view; it does not introduce a second conversation surface.
pcall(require, "PNC/Conversation/PNC_ConversationSemanticSuggestions")

function ExtensionParts.Build(npcID, semanticFactory)
    return {
        {
            partID = "relationship",
            factory = Conversation.CreateRelationshipPanel,
            relationship = Relationship.GetPresentation(npcID),
            visible = Relationship.IsPresentationVisible(),
            title = {
                key = "panel.current_relation",
                domain = "pnc.system.shared.categories",
            },
            editLabel = {
                key = "panel.current_relation_edit",
                domain = "pnc.system.shared.categories",
            },
        },
        {
            partID = "semanticSuggestions",
            factory = Conversation.CreateSemanticSuggestionsPart,
            visible = type(Conversation.CreateSemanticSuggestionsPart)
                == "function",
            title = {
                key = "UI_PNC_Conversation_SemanticSuggestions_Title",
                fallback = "CONTEXTUAL SUGGESTIONS",
            },
        },
        {
            partID = "llmInput",
            factory = semanticFactory,
            -- If a dependency is unavailable, hide the part so no nil
            -- factory is passed to the extension presenter.
            visible = semanticFactory ~= nil,
            title = {
                key = "panel.llm_input",
                domain = "pnc.system.shared.categories",
                fallback = "TYPE TO TALK",
            },
        },
    }
end

return ExtensionParts
