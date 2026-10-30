-- Resolve policy-free assembly entries so tests still observe actual providers.
return function(root, layer, name)
    local candidate = layer .. '/' .. name .. '.lua'
    local handle = io.open(root .. candidate, 'r')
    if not handle then return nil end
    local first = handle:read('*l') or ''
    handle:close()
    if first:find('^%-%- Domain registration: ') then return candidate end
    return nil
end
