local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal

function Internal.ScopeVisible(entry, scope, fallback)
    if type(entry.scopes) ~= "table" or entry.scopes[scope] == nil then
        return fallback == true
    end
    return entry.scopes[scope] == true
end

function Internal.Rounded(value, digits)
    local number = tonumber(value)
    local scale
    if number == nil then return nil end
    scale = 10 ^ (digits or 2)
    return tostring(math.floor(number * scale + 0.5) / scale)
end

return Internal
