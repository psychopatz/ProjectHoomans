-- Project Hoomans-only nameplate presentation settings.
--
-- This adapter owns Hoomans-specific nameplate presentation. The Command
-- Hub's shared opacity, theme, and title-bar settings stay in PsychopatzCore
-- so other mods can use them without inheriting Hoomans data.
PNC = PNC or {}
PNC.NameplateDisplaySettings = PNC.NameplateDisplaySettings or {}

local DisplaySettings = PNC.NameplateDisplaySettings

DisplaySettings.RelationshipFeedbackKey = "relationshipFeedbackScale"
DisplaySettings.DefaultRelationshipFeedbackScale = 1.0
DisplaySettings.MinRelationshipFeedbackScale = 0.5
DisplaySettings.MaxRelationshipFeedbackScale = 1.5
DisplaySettings.NameplateTextScaleKey = "nameplateTextScale"
DisplaySettings.DefaultNameplateTextScale = 1.0
DisplaySettings.MinNameplateTextScale = 0.5
DisplaySettings.MaxNameplateTextScale = 1.5
DisplaySettings.NameplateBarScaleKey = "nameplateBarScale"
DisplaySettings.DefaultNameplateBarScale = 1.0
DisplaySettings.MinNameplateBarScale = 0.5
DisplaySettings.MaxNameplateBarScale = 1.5

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function normalize(value)
    value = tonumber(value)
        or DisplaySettings.DefaultRelationshipFeedbackScale
    return clamp(value,
        DisplaySettings.MinRelationshipFeedbackScale,
        DisplaySettings.MaxRelationshipFeedbackScale)
end

local function values()
    local nameplates = PNC.Nameplates
    return nameplates and nameplates.Settings or nil
end

function DisplaySettings.GetRelationshipFeedbackScale()
    local settings = values()
    return normalize(settings and settings[DisplaySettings.RelationshipFeedbackKey])
end

function DisplaySettings.SetRelationshipFeedbackScale(value, save)
    value = normalize(value)
    local settings = values()
    if settings then
        settings[DisplaySettings.RelationshipFeedbackKey] = value
    end
    local store = PNC.SettingsStore
    if store and store.Set and settings then
        store:Set(DisplaySettings.RelationshipFeedbackKey, value, save ~= false)
    end
    return value
end

function DisplaySettings.ResetRelationshipFeedbackScale(save)
    return DisplaySettings.SetRelationshipFeedbackScale(
        DisplaySettings.DefaultRelationshipFeedbackScale,
        save)
end

function DisplaySettings.GetNameplateTextScale()
    local settings = values()
    local value = settings and settings[DisplaySettings.NameplateTextScaleKey]
        or DisplaySettings.DefaultNameplateTextScale
    return clamp(tonumber(value) or DisplaySettings.DefaultNameplateTextScale,
        DisplaySettings.MinNameplateTextScale,
        DisplaySettings.MaxNameplateTextScale)
end

function DisplaySettings.SetNameplateTextScale(value, save)
    value = clamp(tonumber(value) or DisplaySettings.DefaultNameplateTextScale,
        DisplaySettings.MinNameplateTextScale,
        DisplaySettings.MaxNameplateTextScale)
    local settings = values()
    if settings then
        settings[DisplaySettings.NameplateTextScaleKey] = value
    end
    local store = PNC.SettingsStore
    if store and store.Set and settings then
        store:Set(DisplaySettings.NameplateTextScaleKey, value, save ~= false)
    end
    return value
end

function DisplaySettings.ResetNameplateTextScale(save)
    return DisplaySettings.SetNameplateTextScale(
        DisplaySettings.DefaultNameplateTextScale,
        save)
end

function DisplaySettings.GetNameplateBarScale()
    local settings = values()
    local value = settings and settings[DisplaySettings.NameplateBarScaleKey]
        or DisplaySettings.DefaultNameplateBarScale
    return clamp(tonumber(value) or DisplaySettings.DefaultNameplateBarScale,
        DisplaySettings.MinNameplateBarScale,
        DisplaySettings.MaxNameplateBarScale)
end

function DisplaySettings.SetNameplateBarScale(value, save)
    value = clamp(tonumber(value) or DisplaySettings.DefaultNameplateBarScale,
        DisplaySettings.MinNameplateBarScale,
        DisplaySettings.MaxNameplateBarScale)
    local settings = values()
    if settings then
        settings[DisplaySettings.NameplateBarScaleKey] = value
    end
    local store = PNC.SettingsStore
    if store and store.Set and settings then
        store:Set(DisplaySettings.NameplateBarScaleKey, value, save ~= false)
    end
    return value
end

function DisplaySettings.ResetNameplateBarScale(save)
    return DisplaySettings.SetNameplateBarScale(
        DisplaySettings.DefaultNameplateBarScale,
        save)
end

local function fontForScale(scale, fallback)
    if scale >= 1.5 and UIFont and UIFont.Large then
        return UIFont.Large
    end
    if scale >= 1.25 and UIFont and UIFont.Medium then
        return UIFont.Medium
    end
    return fallback or (UIFont and UIFont.Small) or nil
end

function DisplaySettings.GetNameplateFont()
    local presentation = PNC.NameplatePresentation
    local fallback = presentation and presentation.Fonts
        and presentation.Fonts.name or nil
    return fontForScale(DisplaySettings.GetNameplateTextScale(), fallback)
end

function DisplaySettings.GetRelationshipFeedbackFont()
    local presentation = PNC.NameplatePresentation
    local fallback = presentation and presentation.Fonts
        and presentation.Fonts.name or nil
    return fontForScale(
        DisplaySettings.GetRelationshipFeedbackScale(), fallback)
end

return DisplaySettings
