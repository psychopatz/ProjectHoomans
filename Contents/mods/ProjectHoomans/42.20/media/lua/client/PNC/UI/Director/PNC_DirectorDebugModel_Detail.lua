-- Final detail composition for the director debug surface.
PNC = PNC or {}
PNC.DirectorDebugModel = PNC.DirectorDebugModel or {}

local Model = PNC.DirectorDebugModel
local Internal = Model.Internal or {}
local row = Internal.row
local appendDirectorRows = Internal.appendDirectorRows
local appendPopulationSummaryRows = Internal.appendPopulationSummaryRows
local appendSelectedSectorRows = Internal.appendSelectedSectorRows
local appendPopulationDetailRows = Internal.appendPopulationDetailRows
local appendGroupRows = Internal.appendGroupRows

local function appendLocationRows(rows, location)
    if not location then return end
    rows[#rows + 1] = row('LOCATION', location.id)
    rows[#rows + 1] = row('Type / position', location.type .. ' / '
        .. string.format('%.0f, %.0f, %.0f', location.x or 0,
            location.y or 0, location.z or 0))
    rows[#rows + 1] = row('Danger / scavenged',
        tostring(location.danger) .. ' / ' .. tostring(location.scavengedLevel))
    rows[#rows + 1] = row('Occupants',
        table.concat(location.occupantGroupIds or {}, ', '))
end

local function appendJobRows(rows, snapshot)
    for _, job in ipairs(snapshot and snapshot.jobs or {}) do
        rows[#rows + 1] = row('JOB ' .. job.name,
            string.format('every %.3fh / next %.3f / runs %d / errors %d',
                job.interval or 0, job.nextRun or 0, job.runs or 0, job.errors or 0),
            (job.errors or 0) > 0 and 'danger' or 'textMuted')
    end
end

local function appendEncounterRows(rows, snapshot)
    local encounters = snapshot and snapshot.recentEncounters or {}
    local first = math.max(1, #encounters - 7)
    for index = first, #encounters do
        local report = encounters[index]
        rows[#rows + 1] = row('ENCOUNTER ' .. tostring(report.id),
            tostring(report.outcome) .. ' / ' .. tostring(report.locationId)
                .. ' / seed ' .. tostring(report.seed)
                .. ' / ' .. table.concat(report.participants or {}, ' vs '),
            report.outcome == 'MATERIALIZATION_REQUIRED'
                and 'warning' or 'textMuted')
        for groupID, intent in pairs(report.intentScores or {}) do
            local scoreText = {}
            for _, name in ipairs({ 'IGNORE', 'AVOID', 'FLEE', 'NEGOTIATE',
                'EXTORT', 'ROB', 'ATTACK' }) do
                scoreText[#scoreText + 1] = name .. '='
                    .. string.format('%.1f', intent.scores and intent.scores[name] or 0)
            end
            rows[#rows + 1] = row('INTENT ' .. groupID,
                tostring(intent.selected) .. ' | ' .. table.concat(scoreText, ' '))
        end
        for _, roundReport in ipairs(report.combatResult
            and report.combatResult.roundReports or {}) do
            rows[#rows + 1] = row('COMBAT ROUND ' .. tostring(roundReport.round),
                'aggregate pressure/casualties available in report')
        end
    end
end

function Model.DetailRows(snapshot, group, location, sector, authorized, reason)
    if authorized ~= true then
        return { row('Authorization', reason, 'danger') }
    end
    local rows = {}
    local metrics = snapshot and snapshot.metrics or {}
    local population = snapshot and snapshot.population or {}
    appendDirectorRows(rows, snapshot, metrics)
    appendPopulationSummaryRows(rows, population)
    appendSelectedSectorRows(rows, sector)
    appendPopulationDetailRows(rows, population)
    if snapshot and snapshot.action then
        rows[#rows + 1] = row('Last action',
            tostring(snapshot.action.action) .. ': ' .. tostring(snapshot.action.reason),
            snapshot.action.ok and 'success' or 'danger')
    end
    if group then appendGroupRows(rows, group, snapshot) end
    appendLocationRows(rows, location)
    appendJobRows(rows, snapshot)
    appendEncounterRows(rows, snapshot)
    return rows
end

return Model
