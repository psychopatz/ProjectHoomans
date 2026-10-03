if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC and PNC.MobileGroupDirectorInternal
if not H then
    return
end

local Internal = H.Internal
local Deps = Internal and Internal.AmbientOrders
if not Deps then
    return
end

local Constants = PNC.FactionConstants
local finite = Deps.finite
local shelterTargetIsLocal = Deps.shelterTargetIsLocal
local beginDiagnosticTiming = Deps.beginDiagnosticTiming
local endDiagnosticTiming = Deps.endDiagnosticTiming
local Const = Deps.Const
local memberRecords = Internal.memberRecords

local function sameTarget(left, right)
    if not left or not right then return left == right end
    return left.kind == right.kind
        and left.siteID == right.siteID
        and left.baseID == right.baseID
        and math.abs(finite(left.x, 0) - finite(right.x, 0)) < 0.1
        and math.abs(finite(left.y, 0) - finite(right.y, 0)) < 0.1
        and math.abs(finite(left.z, 0) - finite(right.z, 0)) < 0.1
end

local function sameOrder(left, right)
    if not left or not right then return left == right end
    if left.kind ~= right.kind or left.roamMode ~= right.roamMode then
        return false
    end
    return math.abs(finite(left.x, 0) - finite(right.x, 0)) < 0.1
        and math.abs(finite(left.y, 0) - finite(right.y, 0)) < 0.1
        and math.abs(finite(left.z, 0) - finite(right.z, 0)) < 0.1
        and left.shelterSiteID == right.shelterSiteID
end

local function shouldHoldForNoShelter(mobile)
    if not mobile
        or mobile.controlMode ~= Constants.MOBILE_CONTROL_AMBIENT
        or not mobile.ambient
        or mobile.ambient.holdForNoShelter ~= true
        or mobile.activity
            == Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
    then
        return false
    end
    if H.IsPlayerRoamArea and H.IsPlayerRoamArea(mobile) then
        return false
    end
    if H.IsPlayerRoamStreetPool
        and H.IsPlayerRoamStreetPool(mobile)
    then
        return false
    end
    return true
end

function H.AmbientOrder(faction, mobile, site)
    local ambient = mobile and mobile.ambient or nil
    local target = ambient and ambient.target or nil
    if mobile and mobile.controlMode == Constants.MOBILE_CONTROL_STRATEGIC
        and mobile.strategicTarget
    then
        target = mobile.strategicTarget
    end
    if shouldHoldForNoShelter(mobile) then
        return { kind = Const.ORDER_GUARD }
    end
    if not target then return nil end
    local home = site and site.home or {}
    if mobile.controlMode == Constants.MOBILE_CONTROL_AMBIENT
        and ambient.objective == Constants.MOBILE_AMBIENT_ROAD
    then
        local order = {
            kind = faction.archetypeID == "looter"
                and Const.ORDER_HOSTILE_ROAM or Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_ROAD,
            x = target.x,
            y = target.y,
            z = target.z,
            radius = target.radius,
            targetRadius = Const.ROAM_TARGET_RADIUS,
            roadBounds = target.bounds,
            ambientMobile = true,
            ambientObjective = Constants.MOBILE_AMBIENT_ROAD,
            ambientSourceID = tostring(faction.id or "") .. ":"
                .. tostring(ambient.revision or 0),
        }
        return order
    end
    if mobile.controlMode == Constants.MOBILE_CONTROL_AMBIENT
        and ambient.objective == Constants.MOBILE_AMBIENT_SHELTER
    then
        return {
            kind = faction.archetypeID == "looter"
                and Const.ORDER_HOSTILE_ROAM or Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_SHELTER,
            x = target.x,
            y = target.y,
            z = target.z,
            radius = target.radius,
            shelterSiteID = target.siteID,
            shelterBounds = target.bounds,
            targetRadius = Const.ROAM_TARGET_RADIUS,
            reachedDistance = 3,
            ambientMobile = true,
            ambientObjective = Constants.MOBILE_AMBIENT_SHELTER,
            ambientSourceID = tostring(faction.id or "") .. ":"
                .. tostring(ambient.revision or 0),
        }
    end
    if faction.archetypeID == "looter" then
        if mobile.pathMode == Constants.MOBILE_PATH_PLAYER then
            return {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = target.x or home.x,
                y = target.y or home.y,
                z = target.z or home.z,
            }
        end
        return {
            kind = Const.ORDER_HOSTILE_ROAM,
            roamMode = Const.ROAM_MODE_AREA,
            x = home.x,
            y = home.y,
            z = home.z,
            radius = home.radius,
            targetRadius = Const.ROAM_TARGET_RADIUS,
        }
    end
    return {
        kind = Const.ORDER_ROAM,
        roamMode = mobile.pathMode == Constants.MOBILE_PATH_PLAYER
            and Const.ROAM_MODE_PLAYER or Const.ROAM_MODE_AREA,
        x = home.x,
        y = home.y,
        z = home.z,
        radius = home.radius,
    }
end

function H.RepairMobileOrders(faction)
    local timingName, timingStart = beginDiagnosticTiming(
        "MobileAmbient.RepairMobileOrders"
    )
    local mobile = faction and faction.mobile or nil
    local holdForNoShelter = shouldHoldForNoShelter(mobile)
    local expected = H.MobileOrder(
        faction,
        mobile,
        mobile and mobile.site
    )
    if not expected then
        endDiagnosticTiming(timingName, timingStart, "no_expected_order")
        return 0
    end
    local repaired = 0
    for _, record in ipairs(memberRecords(faction)) do
        local jobSystem = PNC.JobSystem
        local facilityActive = jobSystem
            and jobSystem.IsFacilityActivityActive
            and jobSystem.IsFacilityActivityActive(record)
        local ambientVisit = PNC.AmbientVisitService
            and PNC.AmbientVisitService.IsOrderProtected
            and PNC.AmbientVisitService.IsOrderProtected(record)
        local memberExpected = expected
        if holdForNoShelter then
            local current = record.orderSpec
            local preserveHoldPosition = record.runtime
                and record.runtime.mobileNoShelterHold == true
                and current
                and current.kind == expected.kind
            local fallbackX = finite(record.x, finite(record.anchorX, 0))
            local fallbackY = finite(record.y, finite(record.anchorY, 0))
            local fallbackZ = finite(record.z, finite(record.anchorZ, 0))
            memberExpected = {
                kind = expected.kind,
                x = preserveHoldPosition
                    and finite(current.x, fallbackX) or fallbackX,
                y = preserveHoldPosition
                    and finite(current.y, fallbackY) or fallbackY,
                z = preserveHoldPosition
                    and finite(current.z, fallbackZ) or fallbackZ,
            }
            record.runtime = record.runtime or {}
            record.runtime.mobileNoShelterHold = true
        elseif record.runtime then
            record.runtime.mobileNoShelterHold = nil
        end
        if not facilityActive and not ambientVisit
            and not sameOrder(record.orderSpec, memberExpected)
        then
            if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
                PNC.OrderSystem.SetOrder(record, H.Copy(memberExpected))
            else
                record.orderSpec = H.Copy(memberExpected)
            end
            repaired = repaired + 1
        end
    end
    endDiagnosticTiming(
        timingName,
        timingStart,
        repaired > 0 and "repaired" or "already_current"
    )
    return repaired
end


return H
