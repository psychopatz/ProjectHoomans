-- Advanced inventory, conversation, and worker-seam controls for the Semantic Lab.

local AdvancedControls = {}

function AdvancedControls.append(add)
    add("player.inventory", "player.inventory", "Inventories", "Player", "Player inventory", "structured_collection", "object", {
        collectionType = "inventory",
        itemCatalogSource = "Project Zomboid media/scripts",
    })
    add("npc.inventory", "npc.inventory", "Inventories", "NPC", "NPC inventory", "structured_collection", "object", {
        collectionType = "inventory",
        itemCatalogSource = "Project Zomboid media/scripts",
    })
    add("conversation.topic", "conversation.topic", "Advanced", "Conversation", "Topic", "text", "text")
    add("conversation.token", "conversation.token", "Advanced", "Conversation", "Token", "text", "text")
    add("runtime.commandResponses", "runtime.commandResponses", "Advanced", "Worker seams", "Command responses · Advanced JSON", "advanced_json", "object")
end

return AdvancedControls
