-- Register response pools emitted by the canonical Conversation compiler.

return function(Catalog, responsePools)
    if type(responsePools) ~= "table" then
        error("Conversation registry requires response pools")
    end
    local index
    local pool
    local registered
    local reason
    for index = 1, #responsePools do
        pool = responsePools[index]
        if type(pool) ~= "table" then
            error("Conversation registry contains an invalid response pool")
        end
        if Catalog.Get(pool.id) then
            registered, reason = Catalog.Extend(pool.id, pool)
        else
            registered, reason = Catalog.Register(pool.id, pool)
        end
        if registered ~= true then
            error("Conversation response pool could not register "
                .. tostring(pool.id) .. " (" .. tostring(reason) .. ")")
        end
    end
end
