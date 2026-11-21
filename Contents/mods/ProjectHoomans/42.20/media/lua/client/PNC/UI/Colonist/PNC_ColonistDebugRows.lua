local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"

local Rows = {}

local function facilityLabel(facility)
    local definitions = PNC and PNC.FacilityDefinitions
    local definition = definitions and definitions.Get
        and definitions.Get(facility and facility.definitionId)
    return Shared.Tr(definition and definition.displayNameKey or "",
        facility and facility.definitionId or "facility")
end

local function getComponent(window, component)
    if component then return component end
    if window and window.tabComponents then
        component = window.tabComponents.debug
    end
    return component or (window and window.debugComponent)
end

function Rows.SyncFacilities(window, snapshot, component)
    component = getComponent(window, component)
    local combo = component and component.facilityCombo
    if not combo then return end
    local previous = combo:getOptionData(combo.selected)
    local previousID = previous and previous.key
    combo:clear()
    local selected = 1
    local facilities = snapshot and snapshot.settlement
        and snapshot.settlement.facilities or {}
    local optionIndex = 0
    for _, facility in ipairs(facilities) do
        local label = facilityLabel(facility)
        local state = facility.cachedState or facility.constructionState
            or "UNKNOWN"
        local components = {}
        for _, component in ipairs(facility.components or {}) do
            components[#components + 1] = component
        end
        table.sort(components, function(left, right)
            return tostring(left.id or "") < tostring(right.id or "")
        end)
        for _, component in ipairs(components) do
            optionIndex = optionIndex + 1
            local key = tostring(facility.id or "") .. ":"
                .. tostring(component.id or "")
            local role = tostring(component.role or component.kind or "component")
            combo:addOptionWithData(label .. " • " .. role .. " • "
                .. tostring(component.id or "") .. " • " .. tostring(state), {
                    key = key,
                    facility = facility,
                    component = component,
                    facilityId = facility.id,
                    componentId = component.id,
                })
            if key == previousID then selected = optionIndex end
        end
        if #components == 0 then
            optionIndex = optionIndex + 1
            local key = tostring(facility.id or "") .. ":none"
            combo:addOptionWithData(label .. " • no live components • "
                .. tostring(state), {
                    key = key,
                    facility = facility,
                    component = nil,
                    facilityId = facility.id,
                })
            if key == previousID then selected = optionIndex end
        end
    end
    if #facilities == 0 then
        combo:addOptionWithData(Shared.Tr(
            "UI_PNC_Facility_None", "NO FACILITIES"), false)
    end
    combo.selected = selected
end

function Rows.Build(person, snapshot, window, component)
    Rows.SyncFacilities(window, snapshot, component)
    if not person then
        return {{
            key = "debug_select",
            label = Shared.Tr("UI_PNC_ColonyDebug_Select", "SELECT A COLONIST"),
            detail = Shared.Tr("UI_PNC_ColonyDebug_SelectHelp",
                "Choose a colonist to inspect storage and provisions."),
        }}
    end

    local rows = {}
    if person.facilityDebugWork then
        local work = person.facilityDebugWork
        local target = work.target or {}
        rows[#rows + 1] = {
            key = "debug_facility_work",
            label = Shared.Tr("UI_PNC_ColonyDebug_FacilityWork",
                "Facility test job"),
            detail = string.format("%s | %s | %s | %.0f, %.0f, %.0f",
                Shared.Tr(work.facilityName,
                    tostring(work.facilityId or "facility")),
                tostring(work.componentRole or work.role or "work") .. " / "
                    .. tostring(work.componentId or ""),
                tostring(work.phase or "QUEUED"),
                tonumber(target.x) or 0, tonumber(target.y) or 0,
                tonumber(target.z) or 0),
            colorName = work.phase == "WORKING" and "success" or "accent",
        }
    end

    local storage = snapshot and snapshot.provisionStorage or {}
    local foodStorage = storage.food or {}
    local hydrationStorage = storage.hydration or {}
    local medicineStorage = storage.bandage or {}
    rows[#rows + 1] = {
        key = "debug_storage_food",
        label = Shared.Tr("UI_PNC_ProvisionDebug_StorageFood",
            "Colony storage food"),
        detail = string.format("hunger utility %.3f | calories %.0f | types %d",
            tonumber(foodStorage.amount) or 0,
            tonumber(foodStorage.calories) or 0,
            tonumber(foodStorage.candidateTypes) or 0),
        colorName = (tonumber(foodStorage.amount) or 0) > 0
            and "success" or "danger",
    }
    rows[#rows + 1] = {
        key = "debug_storage_hydration",
        label = Shared.Tr("UI_PNC_ProvisionDebug_StorageHydration",
            "Colony storage hydration"),
        detail = string.format("thirst utility %.3f | types %d",
            tonumber(hydrationStorage.amount) or 0,
            tonumber(hydrationStorage.candidateTypes) or 0),
    }
    rows[#rows + 1] = {
        key = "debug_storage_medicine",
        label = Shared.Tr("UI_PNC_ProvisionDebug_StorageMedicine",
            "Colony storage medicine"),
        detail = string.format("usable bandages %.0f | types %d",
            tonumber(medicineStorage.amount) or 0,
            tonumber(medicineStorage.candidateTypes) or 0),
    }

    local evaluations = person.provision and person.provision.evaluations or {}
    local provisionLabel = Shared.Tr(
        "UI_PNC_ColonyDebug_ProvisionState", "Provision")
    for _, ruleID in ipairs({ "food", "hydration", "bandage" }) do
        local value = evaluations[ruleID]
        if value then
            rows[#rows + 1] = {
                key = "debug_provision_" .. ruleID,
                label = provisionLabel .. ": " .. string.upper(ruleID),
                detail = string.format("%.2f / %.2f  |  %s",
                    tonumber(value.onHand) or 0,
                    tonumber(value.target) or 0,
                    value.refilling and "REFILLING" or "READY"),
            }
        end
    end

    local result = snapshot and snapshot.actionResult
    if result and (result.action == "debug_need"
        or result.action == "debug_facility_work")
    then
        rows[#rows + 1] = {
            key = "debug_result",
            label = Shared.Tr("UI_PNC_ColonyDebug_LastAction", "Last action"),
            detail = tostring(result.reason or "unknown"),
            colorName = result.ok and "success" or "danger",
        }
        local grabLabel = Shared.Tr("UI_PNC_ProvisionDebug_Grab", "GRAB")
        for index, forceResult in ipairs(
            result.details and result.details.forceResults or {}) do
            rows[#rows + 1] = {
                key = "debug_force_result_" .. tostring(index),
                label = grabLabel .. " " .. string.upper(
                    tostring(forceResult.ruleId or "unknown")),
                detail = tostring(forceResult.reason or "unknown"),
                colorName = forceResult.ok and "success" or "danger",
            }
        end
    end
    local brain = type(person) == "table" and person.taskBrain or nil
    if type(brain) == "table" then
        local current = type(brain.current) == "table" and brain.current or nil
        local activeBand = tostring(brain.activeBand
            or (current and current.precedence) or "IDLE")
        rows[#rows + 1] = {
            key = "debug_ai_band",
            label = Shared.Tr("UI_PNC_ColonyDebug_AIBand", "AI Band / Decision"),
            detail = string.format("%s | %s | cause %s | task %s",
                activeBand,
                tostring(brain.decision or "NONE"),
                tostring(brain.lastCause or "-"),
                tostring(current and (current.operation or current.taskId) or "IDLE")),
            colorName = current and "accent" or "muted",
        }

        local claims = type(brain.leaseClaims) == "table" and #brain.leaseClaims > 0
            and brain.leaseClaims or brain.claims
        local claimKeys = {}
        local claimCount = type(claims) == "table" and #claims or 0
        for i = 1, math.min(4, claimCount) do
            claimKeys[#claimKeys + 1] = tostring(claims[i].key or claims[i])
        end
        rows[#rows + 1] = {
            key = "debug_ai_claims",
            label = Shared.Tr("UI_PNC_ColonyDebug_TaskClaims", "Tasking Claims"),
            detail = #claimKeys > 0
                and string.format("%d: %s", claimCount, table.concat(claimKeys, ", "))
                or "0 active",
        }

        local autonomy = type(brain.autonomyDiagnostics) == "table"
            and brain.autonomyDiagnostics or nil
        if autonomy then
            local cands = type(autonomy.candidates) == "table"
                and autonomy.candidates or {}
            for i = 1, math.min(3, #cands) do
                local cand = cands[i]
                rows[#rows + 1] = {
                    key = "debug_ai_autonomy_cand_" .. tostring(i),
                    label = Shared.Tr("UI_PNC_ColonyDebug_AutonomyCand",
                        "Autonomy Candidate") .. " #" .. tostring(i),
                    detail = string.format(
                        "%s [%s] score %.2f (trait %+.2f, mood %+.2f, dist -%.2f)",
                        tostring(cand.adId or "unknown"),
                        tostring(cand.band or "IDLE"),
                        tonumber(cand.score) or 0,
                        tonumber(cand.traitDelta) or 0,
                        tonumber(cand.moodDelta) or 0,
                        tonumber(cand.distancePenalty) or 0),
                    colorName = i == 1 and "success" or "muted",
                }
            end
            local rejs = type(autonomy.rejections) == "table"
                and autonomy.rejections or {}
            for i = 1, math.min(4, #rejs) do
                local rej = rejs[i]
                rows[#rows + 1] = {
                    key = "debug_ai_autonomy_rej_" .. tostring(i),
                    label = Shared.Tr("UI_PNC_ColonyDebug_AutonomyRej",
                        "Autonomy Rejected") .. " #" .. tostring(i),
                    detail = string.format("%s: %s",
                        tostring(rej.adId or "unknown"),
                        tostring(rej.reason or "REJECTED")),
                    colorName = "danger",
                }
            end
            local co = type(autonomy.coPresence) == "table"
                and autonomy.coPresence or nil
            if co then
                rows[#rows + 1] = {
                    key = "debug_ai_copresence",
                    label = Shared.Tr("UI_PNC_ColonyDebug_CoPresence", "Co-Presence"),
                    detail = string.format("%s | %s | reason %s | peers %d",
                        tostring(co.situationId or "-"),
                        co.triggered == true and "TRIGGERED" or "IDLE",
                        tostring(co.reason or "-"),
                        type(co.participants) == "table" and #co.participants or 0),
                    colorName = co.triggered == true and "success" or "muted",
                }
            end
        end
    end

    return rows
end

return Rows
