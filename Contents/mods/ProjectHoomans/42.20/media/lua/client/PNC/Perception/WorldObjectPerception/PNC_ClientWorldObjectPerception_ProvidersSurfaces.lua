-- Sitting and sleeping surface providers for client perception.
-- Exact seating is preferred when the engine exposes SeatingManager. The
-- fallback is diagnostic-only and is never used by gameplay or the server.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal
local Catalog = Internal.Catalog
local SquareRules = Internal.SquareRules

local function call(object, method, ...)
    return Internal.Call(object, method, ...)
end

local function number(value)
    return Internal.Number(value)
end

local function containsToken(values, token)
    token = string.lower(tostring(token or ""))
    if token == "" then return false end
    for index = 1, #(values or {}) do
        local value = string.lower(tostring(values[index] or ""))
        if string.find(value, token, 1, true) then return true end
    end
    return false
end

local function sleepProvider(object, square, record)
    local surface
    if SquareRules
        and type(SquareRules.ClassifySleepSurface) == "function"
    then
        local result = SquareRules.ClassifySleepSurface(object)
        if result == "bed" or result == "sofa" then
            surface = result
        end
    end
    if not surface then
        local metadata = record and record.metadata or {}
        local labels = metadata.labels or {}
        local bed = false
        if Catalog and type(Catalog.Matches) == "function" then
            bed = Catalog.Matches("bed", metadata) == true
        end
        local sofa = containsToken(labels, "sofa")
            or containsToken(labels, "couch")
        if bed == true or containsToken(labels, "bed")
            or containsToken(labels, "cot")
            or containsToken(labels, "bunk")
        then
            surface = "bed"
        elseif sofa then
            surface = "sofa"
        end
        if not surface then return nil end
        return {
            validSleeping = true,
            sleepingSurface = surface,
            sleepingApproximate = true,
            sleepingValidation = "client_metadata_approximation",
            usage = { "Sleeping (" .. surface .. ")" },
            jobs = { "sleep" },
            capabilities = { "sleep" },
            role = "sleep." .. surface,
        }
    end
    return {
        validSleeping = true,
        sleepingSurface = surface,
        sleepingApproximate = false,
        sleepingValidation = "square_rules",
        usage = { "Sleeping (" .. surface .. ")" },
        jobs = { "sleep" },
        capabilities = { "sleep" },
        role = "sleep." .. surface,
    }
end

local function approximateSitting(object, record)
    local metadata = record and record.metadata or {}
    local labels = metadata.labels or {}
    local matchedChair = false
    if Catalog and type(Catalog.Matches) == "function" then
        matchedChair = Catalog.Matches("chair", metadata) == true
    end
    local sofa = false
    if SquareRules and type(SquareRules.ClassifySleepSurface) == "function" then
        local surface = SquareRules.ClassifySleepSurface(object)
        sofa = surface == "sofa"
    end
    local namedSeat = containsToken(labels, "chair")
        or containsToken(labels, "seat")
        or containsToken(labels, "bench")
        or containsToken(labels, "stool")
        or containsToken(labels, "furniture_seating")
        or containsToken(labels, "sofa")
        or containsToken(labels, "couch")
    if not matchedChair and not sofa and not namedSeat then return nil end
    return {
        validSitting = true,
        sittingCount = 1,
        sittingApproximate = true,
        sittingValidation = "client_metadata_approximation",
        usage = { "Sitting" },
        jobs = { "living", "recreation" },
        capabilities = { "living", "recreation" },
        role = sofa and "living.sofa" or "living.chair",
    }
end

local function surfaceCandidate(object, square, metadata)
    metadata = type(metadata) == "table" and metadata or {}
    if SquareRules
        and type(SquareRules.ClassifySleepSurface) == "function"
    then
        local surface = SquareRules.ClassifySleepSurface(object)
        if surface == "bed" or surface == "sofa" then
            return true
        end
    end
    if Catalog and type(Catalog.Matches) == "function" then
        local bed = Catalog.Matches("bed", metadata)
        local chair = Catalog.Matches("chair", metadata)
        if bed == true or chair == true then
            return true
        end
    end
    local labels = metadata.labels or {}
    return containsToken(labels, "bed")
        or containsToken(labels, "cot")
        or containsToken(labels, "bunk")
        or containsToken(labels, "chair")
        or containsToken(labels, "seat")
        or containsToken(labels, "bench")
        or containsToken(labels, "stool")
        or containsToken(labels, "furniture_seating")
        or containsToken(labels, "sofa")
        or containsToken(labels, "couch")
end

local function sittingProvider(object, square, record)
    if SeatingManager and type(SeatingManager.getInstance) == "function" then
        local manager = SeatingManager.getInstance()
        if manager
            and type(manager.getTilePositionCount) == "function"
        then
            local countOk, count = pcall(manager.getTilePositionCount,
                manager, object)
            count = countOk and number(count) or nil
            if count and count > 0 then
                return {
                    validSitting = true,
                    sittingCount = count,
                    sittingApproximate = false,
                    sittingValidation = "seating_manager",
                    usage = { "Sitting" },
                    jobs = { "living", "recreation" },
                    capabilities = { "living", "recreation" },
                    role = "living.chair",
                }
            end
        end
    end
    return approximateSitting(object, record)
end

Perception.RegisterProvider("sleep", {
    order = 30,
    labelKey = "UI_PNC_PerceptionDebug_ProviderSleeping",
    candidate = surfaceCandidate,
    describe = sleepProvider,
})
Perception.RegisterProvider("sitting", {
    order = 40,
    labelKey = "UI_PNC_PerceptionDebug_ProviderSitting",
    candidate = surfaceCandidate,
    describe = sittingProvider,
})

return Perception
