-- Skill/progression schema, including the existing recruitment learning gate.
local Repository = {}
local Codec = require "PNC/Core/Base/PNC_RecordCodec"

function Repository.NormalizeBaseLevels(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then return output end
    for key, value in pairs(source) do
        if type(key) == "string" and tonumber(value) ~= nil then
            output[key] = math.max(0, math.min(10, math.floor(tonumber(value))))
        end
    end
    return output
end

function Repository.NormalizeProgression(rawProgression)
    local output = {
        recruited = false,
        skillLevelDeltas = {},
        skillXP = {},
    }
    local key
    local value
    local source = type(rawProgression) == "table" and rawProgression or {}
    output.recruited = source.recruited == true
    if type(source.skillLevelDeltas) == "table" then
        for key, value in pairs(source.skillLevelDeltas) do
            value = math.max(-10, math.min(10,
                math.floor(Codec.normalizeNumber(value, 0))))
            if value ~= 0 then
                output.skillLevelDeltas[tostring(key)] = value
            end
        end
    end
    if type(source.skillXP) == "table" then
        for key, value in pairs(source.skillXP) do
            value = math.max(0, Codec.normalizeNumber(value, 0))
            if value ~= 0 then output.skillXP[tostring(key)] = value end
        end
    end
    if type(source.exercise) == "table" then
        local ex = {
            stiffness = math.max(0, math.min(100, Codec.normalizeNumber(source.exercise.stiffness, 0))),
            pendingStiffness = math.max(0, math.min(100, Codec.normalizeNumber(source.exercise.pendingStiffness, 0))),
            onsetHours = math.max(0, Codec.normalizeNumber(source.exercise.onsetHours, 0)),
            regularity = {},
        }
        if type(source.exercise.regularity) == "table" then
            for key, value in pairs(source.exercise.regularity) do
                value = math.max(0, math.min(100, Codec.normalizeNumber(value, 0)))
                if value > 0 then ex.regularity[tostring(key)] = value end
            end
        end
        if ex.stiffness > 0 or ex.pendingStiffness > 0 or Codec.hasTableEntries(ex.regularity) then
            output.exercise = ex
        end
    end
    if type(source.mood) == "table" then
        local mood = {}
        local hasMood = false
        for _, field in ipairs({ "stress", "boredom", "unhappiness", "pain" }) do
            local val = math.max(0, math.min(1, Codec.normalizeNumber(source.mood[field], 0)))
            if val > 0.001 then
                mood[field] = math.floor(val * 1000 + 0.5) / 1000
                hasMood = true
            end
        end
        if hasMood then output.mood = mood end
    end
    return output
end

function Repository.SerializeRecord(record)
    local progression = Repository.NormalizeProgression(record.progression)
    progression.recruited = record.recruited == true
    if not Codec.hasTableEntries(progression.skillLevelDeltas) then
        progression.skillLevelDeltas = nil
    end
    if not Codec.hasTableEntries(progression.skillXP) then
        progression.skillXP = nil
    end
    if progression.recruited ~= true
        and progression.skillLevelDeltas == nil
        and progression.skillXP == nil
        and progression.exercise == nil
        and progression.mood == nil
    then
        return nil
    end
    return progression
end

function Repository.SerializeBaseLevels(record)
    local levels = Repository.NormalizeBaseLevels(record.skillBaseLevels)
    return Codec.hasTableEntries(levels) and levels or nil
end

function Repository.RestoreRecord(record, progression)
    record.progression = {
        skillLevelDeltas = progression.skillLevelDeltas,
        skillXP = progression.skillXP,
        exercise = progression.exercise,
        mood = progression.mood,
    }
    record.recruited = progression.recruited == true or record.recruited == true
    return record
end

return Repository
