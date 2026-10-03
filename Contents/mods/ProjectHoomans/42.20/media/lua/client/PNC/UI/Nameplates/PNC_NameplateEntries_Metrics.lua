local Entries = PNC.NameplateEntries
local Debug = PNC.NameplateDebug
local Presentation = PNC.NameplatePresentation
local Identity = PNC.NPCIdentityPresentation
local Speech = PNC.NameplateSpeech
local Scopes = PNC.NameplateScopes
local ToolFeedback = PNC.NameplateToolFeedback
local nameplateFont = Entries._NameplateFont
local factionDebugLines = Entries.BuildFactionDebugLines
local communityDebugLines = Entries.BuildCommunityDebugLines

local function buildDebugTexts(snapshot, zombie, settings, showDebug)
    local debugText = showDebug
        and Debug.BuildText(snapshot, zombie ~= nil, settings) or ""
    if showDebug and settings.debugShowAnimation ~= false then
        local animationText = Debug.AnimationText(zombie, snapshot)
        debugText = debugText ~= "" and (debugText .. " | " .. animationText) or animationText
    end
    local animationDebugText = settings
        and settings.showAnimationDebug == true
        and Debug.AnimationTrackText(zombie)
        or ""
    local sceneDebugText = ""
    local sceneTrackDebugText = ""
    if settings
        and settings.showAnimationSceneDebug == true
        and Debug.AnimationSceneText
    then
        sceneDebugText, sceneTrackDebugText =
            Debug.AnimationSceneText(zombie, snapshot)
    end
    local infectionDebugText = showDebug
        and Debug.InfectionText(snapshot, settings) or ""
    return debugText, animationDebugText, sceneDebugText, sceneTrackDebugText, infectionDebugText
end

local function buildFeedbackTexts(snapshot, speech)
    local actionText, actionColor = Presentation.ActionStatus(snapshot)
    local recoveryText, recoveryColor, recoveryActive =
        Presentation.RecoveryStatus(snapshot)
    speech = speech or (Speech and Speech.Get(snapshot and snapshot.id) or nil)
    local speechText = Speech and Speech.GetDisplayText(speech) or ""
    local toolFeedback = ToolFeedback and ToolFeedback.Get
        and ToolFeedback.Get(snapshot and snapshot.id) or nil
    local toolFeedbackText = ToolFeedback and ToolFeedback.GetDisplayText
        and ToolFeedback.GetDisplayText(toolFeedback) or ""
    return actionText, actionColor, recoveryText, recoveryColor, recoveryActive, speechText, toolFeedback, toolFeedbackText
end

local function populateFactionDebug(entry, snapshot, settings)
    local factionLine1
    local factionLine2
    local factionLine3
    local relationshipDebugLine
    local relationshipChangeLine
    local communityDebugLine1
    local communityDebugLine2
    factionLine1,
    factionLine2,
    factionLine3,
    relationshipDebugLine,
    relationshipChangeLine,
    entry.factionDebugTone,
    entry.relationshipDebugTone,
    entry.relationshipChangeTone =
        factionDebugLines(snapshot, settings)
    communityDebugLine1,
    communityDebugLine2,
    entry.communityDebugTone =
        communityDebugLines(snapshot, settings)
    return factionLine1, factionLine2, factionLine3, relationshipDebugLine, relationshipChangeLine, communityDebugLine1, communityDebugLine2
end

local function cachePrimaryMetrics(entry, nameFont, fonts, name, debugText, animationDebugText, sceneDebugText, sceneTrackDebugText, infectionDebugText, actionText, recoveryText)
    Presentation.CacheTextMetric(entry, "name", name, nameFont)
    Presentation.CacheTextMetric(entry, "debugText", debugText, fonts.debug)
    Presentation.CacheTextMetric(
        entry,
        "animationDebugText",
        animationDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "sceneDebugText",
        sceneDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "sceneTrackDebugText",
        sceneTrackDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "infectionDebugText",
        infectionDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "actionText",
        actionText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "recoveryText",
        recoveryText,
        fonts.debug
    )
end

local function cacheSecondaryMetrics(entry, fonts, speechText, toolFeedbackText, factionLine1, factionLine2, factionLine3, relationshipDebugLine, relationshipChangeLine, communityDebugLine1, communityDebugLine2)
    Presentation.CacheTextMetric(
        entry,
        "speechText",
        speechText,
        fonts.speech or fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "toolFeedbackText",
        toolFeedbackText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "factionDebugLine1",
        factionLine1,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "factionDebugLine2",
        factionLine2,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "factionDebugLine3",
        factionLine3,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "relationshipDebugLine",
        relationshipDebugLine,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "relationshipChangeLine",
        relationshipChangeLine,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "communityDebugLine1",
        communityDebugLine1,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "communityDebugLine2",
        communityDebugLine2,
        fonts.debug
    )
end

local function cacheMetrics(entry, snapshot, zombie, settings, speech, scopes)
    local fonts = Presentation.Fonts
    local nameFont = nameplateFont()
    local showNameplateDebug = settings and (
        settings.showNameplateDebug == true
            or settings.showAIDebug == true
    )
    local showDebug = settings and (
        showNameplateDebug or settings.showCampDebug == true
    )
    local name = Identity.GetName(snapshot)
    local debugText, animationDebugText, sceneDebugText, sceneTrackDebugText, infectionDebugText =
        buildDebugTexts(snapshot, zombie, settings, showDebug)
    local actionText, actionColor, recoveryText, recoveryColor, recoveryActive, speechText, toolFeedback, toolFeedbackText =
        buildFeedbackTexts(snapshot, speech)
    local factionLine1, factionLine2, factionLine3, relationshipDebugLine, relationshipChangeLine, communityDebugLine1, communityDebugLine2 =
        populateFactionDebug(entry, snapshot, settings)
    entry.actionColor = actionColor
    entry.recoveryColor = recoveryColor
    entry.scopes = scopes or {}
    entry.identityVisible = entry.scopes[Scopes.IDENTITY] == true
    entry.debugVisible = entry.scopes[Scopes.DEBUG] == true
    entry.conversationVisible = entry.scopes[Scopes.CONVERSATION] == true
    entry.toolFeedback = toolFeedback
    entry.toolFeedbackVisible = entry.scopes[Scopes.TOOL_FEEDBACK] == true
        and toolFeedbackText ~= ""
    entry.actionVisible = entry.identityVisible and actionText ~= ""
    entry.recoveryVisible = entry.identityVisible and recoveryActive
    entry.speech = speech
    entry.speechVisible = entry.conversationVisible and speechText ~= ""
    cachePrimaryMetrics(entry, nameFont, fonts, name, debugText, animationDebugText, sceneDebugText, sceneTrackDebugText, infectionDebugText, actionText, recoveryText)
    cacheSecondaryMetrics(entry, fonts, speechText, toolFeedbackText, factionLine1, factionLine2, factionLine3, relationshipDebugLine, relationshipChangeLine, communityDebugLine1, communityDebugLine2)
end
Entries._CacheMetrics = cacheMetrics
