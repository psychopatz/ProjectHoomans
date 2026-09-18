-- Tool definitions and bridge catalog projection for interactive context.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Internal = PNC.PBrainZ.Internal
local Runtime = Internal.Runtime
local Tools = Internal.ContextTools or {}
Internal.ContextTools = Tools
local ToolPolicy = PNC.ConversationLLMTools

function Tools.GetDefinitions()
    local seen = {
        social_react = true, ask_name = true, disclose_knowledge = true,
    }
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
    if ToolPolicy and ToolPolicy.BuildIdentityDefinition then
        output[#output + 1] = ToolPolicy.BuildIdentityDefinition()
    else
        output[#output + 1] = {
            type = "function",
            ["function"] = {
                name = "ask_name",
                description = "Ask the NPC to say their name through authoritative identity knowledge disclosure.",
                parameters = {
                    type = "object",
                    properties = {},
                    additionalProperties = false,
                },
            },
        }
    end
    if ToolPolicy and ToolPolicy.BuildKnowledgeDefinition then
        local knowledgeDefinition = ToolPolicy.BuildKnowledgeDefinition()
        if knowledgeDefinition then output[#output + 1] = knowledgeDefinition end
    end
    local commands = PNC.CompanionCommands
    if not commands or not commands.List then return output end
    for _, definition in ipairs(commands.List()) do
        local commandID = Runtime.Trim(definition and definition.id)
        if commandID ~= "" and definition.clientOnly ~= true and #output < 12 then
            local safeCommandID = string.gsub(commandID, "[^%w%-_]", "_")
            local toolName = "order_" .. string.sub(safeCommandID, 1, 52)
            if not seen[toolName] then
                seen[toolName] = true
                output[#output + 1] = {
                    type = "function",
                    ["function"] = {
                        name = toolName,
                        description = definition.llmDescription
                            or ("Request the Project Hoomans order '" .. commandID
                                .. "'; authority validates it."),
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

function Tools.CatalogReference(definitions)
    local bridge = PsychopatzCore and PsychopatzCore.Bridge
    if not bridge or type(bridge.GetToolCatalog) ~= "function" then
        return nil, nil
    end
    local catalog = bridge.GetToolCatalog()
    local catalogID = Runtime.Trim(catalog and catalog.catalog_id)
    local rows = catalog and catalog.tools or nil
    if catalogID == "" or type(rows) ~= "table" then return nil, nil end
    local known = {}
    for _, row in ipairs(rows) do
        local id = Runtime.Trim(row and row.id)
        if id ~= "" then known[id] = true end
    end
    local IDs = {}
    for _, tool in ipairs(definitions or {}) do
        local definition = tool and tool["function"] or nil
        local name = Runtime.Trim(definition and definition.name)
        local id = name ~= "" and "pbrainz.llm:" .. name or nil
        if not id or not known[id] then return nil, nil end
        IDs[#IDs + 1] = id
    end
    return catalogID, IDs
end

return Tools
