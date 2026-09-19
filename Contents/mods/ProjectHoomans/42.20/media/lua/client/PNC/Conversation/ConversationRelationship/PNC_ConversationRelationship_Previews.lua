-- Copy and compare nested relationship preview payloads.
local Previews = {}

function Previews.CopyRecruitmentPreview(value)
    if type(value) ~= "table" then return nil end
    local function copyBreakdown(source)
        if type(source) ~= "table" then return nil end
        local output = {}
        for _, route in ipairs({ "admire", "fear" }) do
            local sourceRoute = source[route]
            if type(sourceRoute) == "table" then
                local routeCopy = {
                    scoreModifier = tonumber(sourceRoute.scoreModifier) or 0,
                    modifiers = {},
                }
                for _, item in ipairs(sourceRoute.modifiers or {}) do
                    if type(item) == "table" then
                        routeCopy.modifiers[#routeCopy.modifiers + 1] = {
                            id = tostring(item.id or ""),
                            label = tostring(item.label or ""),
                            value = tonumber(item.value) or 0,
                        }
                    end
                end
                output[route] = routeCopy
            end
        end
        return output
    end
    local graphContext = type(value.graphContext) == "table"
        and { bonus = tonumber(value.graphContext.bonus) or 0 }
        or nil
    return {
        graphContext = graphContext,
        score = tonumber(value.score) or 0,
        threshold = tonumber(value.threshold) or 0,
        margin = tonumber(value.margin) or 0,
        personalityBreakdown = copyBreakdown(value.personalityBreakdown),
        approvalMinimum = tonumber(value.approvalMinimum),
        respectMinimum = tonumber(value.respectMinimum),
        meetsMinimums = value.meetsMinimums == true,
        normalEligible = value.normalEligible == true,
        fearEligible = value.fearEligible == true,
    }
end

local function sameBreakdown(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return left == right
    end
    for _, route in ipairs({ "admire", "fear" }) do
        local leftRoute = left[route]
        local rightRoute = right[route]
        if type(leftRoute) ~= type(rightRoute) then return false end
        if type(leftRoute) == "table" then
            if (tonumber(leftRoute.scoreModifier) or 0)
                ~= (tonumber(rightRoute.scoreModifier) or 0)
            then
                return false
            end
            local leftModifiers = leftRoute.modifiers or {}
            local rightModifiers = rightRoute.modifiers or {}
            if #leftModifiers ~= #rightModifiers then return false end
            for index = 1, #leftModifiers do
                local leftItem = leftModifiers[index]
                local rightItem = rightModifiers[index]
                if tostring(leftItem.id or "")
                    ~= tostring(rightItem.id or "")
                    or tostring(leftItem.label or "")
                        ~= tostring(rightItem.label or "")
                    or (tonumber(leftItem.value) or 0)
                        ~= (tonumber(rightItem.value) or 0)
                then
                    return false
                end
            end
        end
    end
    return true
end

function Previews.CopyDeparturePreview(value)
    if type(value) ~= "table" then return nil end
    local output = {
        version = tonumber(value.version) or 0,
        approvalThreshold = tonumber(value.approvalThreshold) or -60,
        respectThreshold = tonumber(value.respectThreshold) or -60,
        recoveryApprovalThreshold =
            tonumber(value.recoveryApprovalThreshold) or -45,
        recoveryRespectThreshold =
            tonumber(value.recoveryRespectThreshold) or -45,
        bothAxesRequired = value.bothAxesRequired == true,
        confirmationChecks = math.max(
            1, math.floor(tonumber(value.confirmationChecks) or 2)
        ),
        modifiers = {},
    }
    for _, item in ipairs(value.modifiers or {}) do
        if type(item) == "table" then
            output.modifiers[#output.modifiers + 1] = {
                id = tostring(item.id or ""),
                label = tostring(item.label or ""),
                value = tonumber(item.value) or 0,
            }
        end
    end
    return output
end

function Previews.SameDeparturePreview(left, right)
    left = left and left.departurePreview or nil
    right = right and right.departurePreview or nil
    if left == nil or right == nil then return left == right end
    return (tonumber(left.approvalThreshold) or 0)
            == (tonumber(right.approvalThreshold) or 0)
        and (tonumber(left.respectThreshold) or 0)
            == (tonumber(right.respectThreshold) or 0)
        and (tonumber(left.recoveryApprovalThreshold) or 0)
            == (tonumber(right.recoveryApprovalThreshold) or 0)
        and (tonumber(left.recoveryRespectThreshold) or 0)
            == (tonumber(right.recoveryRespectThreshold) or 0)
        and (tonumber(left.confirmationChecks) or 0)
            == (tonumber(right.confirmationChecks) or 0)
        and sameBreakdown(
            { admire = { modifiers = left.modifiers or {} } },
            { admire = { modifiers = right.modifiers or {} } }
        )
end

function Previews.CopyAmbientVisitPreview(value)
    if type(value) ~= "table" then return nil end
    return {
        eligible = value.eligible == true,
        reason = value.reason,
        baseID = value.baseID and tostring(value.baseID) or nil,
        accessClass = value.accessClass,
        purpose = value.purpose,
    }
end

function Previews.SameRecruitmentPreview(left, right)
    left = left and left.recruitmentPreview or nil
    right = right and right.recruitmentPreview or nil
    if left == nil or right == nil then return left == right end
    local leftContext = left.graphContext or {}
    local rightContext = right.graphContext or {}
    return (tonumber(left.score) or 0) == (tonumber(right.score) or 0)
        and (tonumber(left.threshold) or 0)
            == (tonumber(right.threshold) or 0)
        and (tonumber(left.margin) or 0) == (tonumber(right.margin) or 0)
        and (tonumber(left.approvalMinimum) or 0)
            == (tonumber(right.approvalMinimum) or 0)
        and (tonumber(left.respectMinimum) or 0)
            == (tonumber(right.respectMinimum) or 0)
        and (tonumber(leftContext.bonus) or 0)
            == (tonumber(rightContext.bonus) or 0)
        and sameBreakdown(
            left.personalityBreakdown,
            right.personalityBreakdown
        )
        and left.meetsMinimums == right.meetsMinimums
        and left.normalEligible == right.normalEligible
        and left.fearEligible == right.fearEligible
end

function Previews.SameSettlementVisit(left, right)
    left = left and left.settlementVisit or nil
    right = right and right.settlementVisit or nil
    if left == nil or right == nil then return left == right end
    return left.active == right.active
        and tostring(left.visitID or "") == tostring(right.visitID or "")
        and (tonumber(left.expiresAt) or 0)
            == (tonumber(right.expiresAt) or 0)
        and (tonumber(left.revision) or 0)
            == (tonumber(right.revision) or 0)
end

function Previews.SameAmbientVisitPreview(left, right)
    left = left and left.ambientVisitPreview or nil
    right = right and right.ambientVisitPreview or nil
    if left == nil or right == nil then return left == right end
    return left.eligible == right.eligible
        and tostring(left.reason or "") == tostring(right.reason or "")
        and tostring(left.baseID or "") == tostring(right.baseID or "")
        and tostring(left.accessClass or "")
            == tostring(right.accessClass or "")
        and tostring(left.purpose or "") == tostring(right.purpose or "")
end

return Previews
