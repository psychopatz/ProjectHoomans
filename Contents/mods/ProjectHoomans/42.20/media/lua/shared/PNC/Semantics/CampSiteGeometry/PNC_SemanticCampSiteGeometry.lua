-- Canonical entry point for room-backed semantic camp-site geometry.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Geometry = PNC.Semantics.CampSiteGeometry or {}
PNC.Semantics.CampSiteGeometry = Geometry

local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Internal = Geometry.Internal or {}
Geometry.Internal = Internal
Internal.CampSite = CampSite

Geometry.VERSION = 1
Geometry.MAX_ROOMS = 128
Geometry.MAX_LOCAL_ROOM_CANDIDATES = 64
Geometry.MAX_ROOM_SQUARES = 512
Geometry.MAX_FALLBACK_SCAN = 4096

require "PNC/Semantics/CampSiteGeometry/PNC_SemanticCampSiteGeometry_RuntimeAccess"
require "PNC/Semantics/CampSiteGeometry/PNC_SemanticCampSiteGeometry_RoomRecords"
require "PNC/Semantics/CampSiteGeometry/PNC_SemanticCampSiteGeometry_RoomProjection"
require "PNC/Semantics/CampSiteGeometry/PNC_SemanticCampSiteGeometry_RoomEnumeration"
require "PNC/Semantics/CampSiteGeometry/PNC_SemanticCampSiteGeometry_RoomSelection"
require "PNC/Semantics/CampSiteGeometry/PNC_SemanticCampSiteGeometry_SiteMembership"

-- Retain the established internal hooks consumed by camp-zone adapters.
Geometry._Internal = Geometry._Internal or {}
Geometry._Internal.Call = Internal.Call
Geometry._Internal.Position = Internal.Position
Geometry._Internal.RoomFor = Internal.RoomFor
Geometry._Internal.RoomDefFor = Internal.RoomDefFor
Geometry._Internal.BoundsFor = Internal.BoundsFor

return Geometry
