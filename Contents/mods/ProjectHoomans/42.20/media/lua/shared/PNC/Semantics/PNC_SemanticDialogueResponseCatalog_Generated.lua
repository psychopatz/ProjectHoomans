-- Generated and authored response-pool bootstrap.

return function(Catalog, generatedSources, GeneratedDefinitions)
    local generatedSourceIndex
    local generatedPools
    local generatedIndex
    local generatedPool
    local extended
    local reason
    for generatedSourceIndex = 1, #generatedSources do
        generatedPools = generatedSources[generatedSourceIndex]
            and generatedSources[generatedSourceIndex].responsePools
        if type(generatedPools) ~= "table" then
            error("generated dialogue dataset requires responsePools")
        end
        for generatedIndex = 1, #generatedPools do
            generatedPool = generatedPools[generatedIndex]
            if type(generatedPool) ~= "table" then
                error("generated dialogue dataset contains an invalid response pool")
            end
            if Catalog.Get(generatedPool.id) then
                extended, reason = Catalog.Extend(generatedPool.id, generatedPool)
            else
                extended, reason = Catalog.Register(generatedPool.id, generatedPool)
            end
            if extended ~= true then
                error("generated dialogue responses could not register "
                    .. tostring(generatedPool.id) .. " (" .. tostring(reason) .. ")")
            end
        end
    end

    local authoredPools = GeneratedDefinitions
        and GeneratedDefinitions.responsePools
    if type(authoredPools) ~= "table" then
        error("generated semantic definitions require responsePools")
    end
    for generatedIndex = 1, #authoredPools do
        generatedPool = authoredPools[generatedIndex]
        if type(generatedPool) ~= "table" then
            error("generated semantic definitions contain an invalid response pool")
        end
        if Catalog.Get(generatedPool.id) then
            extended, reason = Catalog.Extend(generatedPool.id, generatedPool)
        else
            extended, reason = Catalog.Register(generatedPool.id, generatedPool)
        end
        if extended ~= true then
            error("generated semantic responses could not register "
                .. tostring(generatedPool.id) .. " (" .. tostring(reason) .. ")")
        end
    end
end
