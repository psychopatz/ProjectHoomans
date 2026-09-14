PNC = PNC or {}
PNC.FlavorAddress = PNC.FlavorAddress or {}

local Names = {}

function Names.Clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

function Names.Call(object, method)
    local objectType = type(object)
    if (objectType ~= "table" and objectType ~= "userdata")
        or type(object[method]) ~= "function"
    then
        return nil
    end
    local ok, value = pcall(object[method], object)
    return ok and value or nil
end

local function firstNonEmpty(...)
    local count = select("#", ...)
    for index = 1, count do
        local value = Names.Clean(select(index, ...), nil)
        if value then return value end
    end
    return nil
end

function Names.Read(options)
    options = type(options) == "table" and options or {}
    local player = options.player
    local context = type(options.playerContext) == "table"
        and options.playerContext or {}
    local authoritative = type(options.authoritative) == "table"
        and options.authoritative or {}
    local descriptor = player and Names.Call(player, "getDescriptor") or nil
    local firstName = firstNonEmpty(
        authoritative.firstName, authoritative.forename,
        options.playerFirstName, options.playerForename,
        context.firstName, context.forename,
        descriptor and Names.Call(descriptor, "getForename"),
        player and Names.Call(player, "getForename")
    )
    local lastName = firstNonEmpty(
        authoritative.lastName, authoritative.surname,
        options.playerLastName, options.playerSurname,
        context.lastName, context.surname,
        descriptor and Names.Call(descriptor, "getSurname"),
        player and Names.Call(player, "getSurname")
    )
    local fullName = firstNonEmpty(
        authoritative.fullName, authoritative.displayName,
        options.playerFullName,
        context.fullName, context.displayName,
        player and Names.Call(player, "getDisplayName"),
        player and Names.Call(player, "getFullName"),
        player and Names.Call(player, "getUsername")
    )
    if not fullName and (firstName or lastName) then
        fullName = Names.Clean(table.concat({ firstName or "", lastName or "" }, " "), nil)
    end
    if not firstName and fullName then
        firstName = string.match(fullName, "^(%S+)")
    end
    if not lastName and fullName then
        lastName = string.match(fullName, "^%S+%s+(.+)$")
    end
    return fullName, firstName, lastName
end

return Names
