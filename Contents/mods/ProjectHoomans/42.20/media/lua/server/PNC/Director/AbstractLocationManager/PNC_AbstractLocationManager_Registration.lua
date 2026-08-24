if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractLocations = PNC.AbstractLocations or {}
PNC.AbstractLocationManagerInternal =
    PNC.AbstractLocationManagerInternal or {}

local Locations = PNC.AbstractLocations
local H = PNC.AbstractLocationManagerInternal
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core

function Locations.Register(spec)
    if not H.Authority() then return nil, "not_authority" end
    Store.EnsureLoaded()
    spec = type(spec) == "table" and spec or {}
    local normalized = Types.NormalizeLocation(spec, spec.id)
    if not normalized then return nil, "invalid_location" end
    local existing = Store.Registry.locationsByID[normalized.id]
    if existing then return existing, "existing" end
    Store.Registry.locationsByID[normalized.id] = normalized
    H.Index(normalized)
    Store.Touch("location_registered")
    Store.Emit("LOCATION_REGISTERED", { locationId = normalized.id })
    return normalized, "registered"
end

function H.SiteLocationID(site)
    local raw = tostring(site and site.id or "")
    raw = string.gsub(raw, "[^%w_%-%.:]", "_")
    return raw ~= "" and ("aloc_" .. raw) or nil
end

function Locations.RegisterSite(site, spec)
    if type(site) ~= "table" or type(site.home) ~= "table" then
        return nil, "invalid_site"
    end
    spec = type(spec) == "table" and spec or {}
    local tags = type(spec.tags) == "table" and spec.tags or {}
    tags.SHELTER = tags.SHELTER ~= false
    if site.kind == "building" then tags.BUILDING = true end
    return Locations.Register({
        id = H.SiteLocationID(site),
        type = spec.type or (site.occupantCommunityID
            and "SETTLEMENT" or "BUILDING"),
        x = site.home.x, y = site.home.y, z = site.home.z,
        tags = tags,
        resourcePotential = spec.resourcePotential or {},
        danger = spec.danger or 0,
        sourceSite = Core.DeepCopy(site),
    })
end

-- Only loaded buildings are considered here. This is deliberately bounded and
-- never walks the world meta-grid.

return Locations

