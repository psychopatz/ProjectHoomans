-- Indoor-room identity provider for client world-object perception.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal
local CampSite = Internal.CampSite
local Geometry = Internal.Geometry

local function call(object, method, ...)
    return Internal.Call(object, method, ...)
end

local function number(value)
    return Internal.Number(value)
end

local function roomProvider(object, square, record, context)
    if not Geometry or type(Geometry.RoomIdentity) ~= "function" then
        return nil
    end
    local x = number(call(square, "getX"))
    local y = number(call(square, "getY"))
    local z = number(call(square, "getZ")) or 0
    local key = tostring(x or "?") .. ":" .. tostring(y or "?") .. ":"
        .. tostring(z)
    context.roomCache = context.roomCache or {}
    if context.roomCache[key] == nil then
        local ok, identity = pcall(Geometry.RoomIdentity, square)
        context.roomCache[key] = ok and identity or false
    end
    local identity = context.roomCache[key]
    if type(identity) ~= "table" then return nil end
    local label = CampSite.RoomLabel(identity.roomType, identity.roomName)
    return {
        indoor = true,
        validCampZone = true,
        campZoneKind = "room",
        room = Internal.CopyPrimitive(identity),
        roomLabel = label,
        usage = { "Indoor room: " .. tostring(label) },
    }
end

Perception.RegisterProvider("room", {
    order = 20,
    labelKey = "UI_PNC_PerceptionDebug_ProviderRoom",
    describe = roomProvider,
})

return Perception
