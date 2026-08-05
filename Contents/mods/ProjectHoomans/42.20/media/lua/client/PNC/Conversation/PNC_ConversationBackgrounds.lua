PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Backgrounds = PNC.Conversation.Backgrounds or { definitions = {} }
PNC.Conversation.Backgrounds = Backgrounds

function Backgrounds.Register(timeID, definition)
    Backgrounds.definitions[tostring(timeID)] = definition
    return definition
end

function Backgrounds.Get(timeID)
    local definition = Backgrounds.definitions[tostring(timeID)]
        or Backgrounds.definitions.twilight
    return definition and definition.id or tostring(timeID or "twilight")
end

return Backgrounds
