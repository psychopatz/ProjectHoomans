-- Text-payload resolution shared by conversation projections and execution.

local Payload = {}

function Payload.resolve(value)
    if type(value) ~= "table" then return tostring(value or "") end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.Resolve) == "function" then
        local ok, resolved = pcall(text.Resolve, value)
        if ok and type(resolved) == "string" and resolved ~= "" then
            return resolved
        end
    end
    return tostring(value.text or value.fallback or "")
end

return Payload
