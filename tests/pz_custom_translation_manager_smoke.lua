local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local activeLanguage = "TL"
local readersClosed = 0
local virtualFiles = {}

Translator = {
    getLanguage = function()
        return { toString = function() return activeLanguage end }
    end,
}

Events = {
    OnGameBoot = {
        listeners = {},
        Add = function(callback)
            Events.OnGameBoot.listeners[#Events.OnGameBoot.listeners + 1] = callback
        end,
    },
}

local function splitLines(text)
    local lines = {}
    for line in string.gmatch(text, "([^\n]*)\n?") do
        lines[#lines + 1] = line
        if string.sub(text, -1) ~= "\n"
            and lines[#lines] == ""
            and #lines > 1
        then
            lines[#lines] = nil
            break
        end
    end
    return lines
end

local function packagedSource(modID, path)
    local key = tostring(modID) .. "|" .. tostring(path)
    if virtualFiles[key] then return virtualFiles[key] end
    if modID == "ProjectHoomans" then
        local ok, source = pcall(T.read, "ProjectHoomans", "common_mod", path)
        return ok and source or nil
    end
    if modID == "PsychopatzCore" then
        local ok, source = pcall(T.read, "PsychopatzCore", "common_mod", path)
        return ok and source or nil
    end
    return nil
end

getText = function(key)
    if key == "ContextMenu_WalkTo" then return "Walk to" end
    return key
end

getModFileReader = function(modID, path)
    local text = packagedSource(modID, path)
    if not text then return nil end
    local lines = splitLines(text)
    local index = 0
    local reader = {}
    function reader:readLine()
        index = index + 1
        return lines[index]
    end
    function reader:close()
        readersClosed = readersClosed + 1
    end
    return reader
end

local Manager = T.load(
    "PsychopatzCore", "common",
    "PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua")
local Translation = T.load(
    "ProjectHoomans", "shared",
    "PNC/Translation/PNC_TranslationBootstrap.lua")

T.truthy(Translation, "Hoomans translation facade loads")
T.truthy(Translation.Systems.Character,
    "Hoomans character catalog registers a handle")
T.equal(Translation.Systems.Character.modID, "ProjectHoomans",
    "character catalog keeps its mod namespace")
T.equal(Translation.Systems.Character.systemName, "Character",
    "character catalog keeps its system namespace")
T.equal(Translation.Traits, Translation.Systems.Character,
    "old trait handle aliases the character catalog")

for _, callback in ipairs(Events.OnGameBoot.listeners) do callback() end

T.equal(Manager.getLanguage(), "TL", "active language is read from Translator")
T.equal(Translation.Get("Character", "UI_PNC_Trait_Friendly"), "Palakaibigan",
    "localized catalog overrides the English value")
T.equal(Translation.GetKey("UI_PNC_Trait_Brawler"), "Palaban",
    "localized catalog resolves the Tagalog value")
T.equal(Translation.GetKey("UI_PNC_DebugHub_NPCMonitor_Title"), "Monitor ng NPC",
    "Debug Hub title resolves through the localized catalog")
T.equal(Translation.GetKey("UI_PNC_DebugHub_NPCMonitor_Description"),
    "Siyasatin ang lifecycle, awtoridad, presensya, labanan, at runtime body ng mga NPC.",
    "Debug Hub subtitle resolves through the localized catalog")
T.equal(Translation.Get("Character", "missing.key", "Visible fallback"),
    "Visible fallback",
    "missing key uses the caller fallback")
T.truthy(Manager.Data.ProjectHoomans.Character,
    "only the resolved Hoomans catalog is exposed in Data")
T.truthy(readersClosed >= 2, "English and localized readers are closed")
T.equal(Translation.GetKey("ContextMenu_WalkTo"), "Walk to",
    "genuine native keys still use the engine translation API")
T.equal(Translation.TrFormat("UI_PNC_VehicleSeatOccupied", "Seat occupied by %1",
    "Alex"), "Ang upuan ay inookupahan ni Alex",
    "indexed Project Zomboid placeholders are formatted")

local CoreTranslation = PsychopatzCore and PsychopatzCore.Translation
T.truthy(CoreTranslation and CoreTranslation.GetKey,
    "Core translation provider facade loads")
T.equal(CoreTranslation.GetKey("UI_PNC_CommandHub_Category_Work", "Work",
    "ProjectHoomans"), "Trabaho",
    "Core resolves a source-owned Hoomans key")
T.equal(CoreTranslation.GetKey("UI_PNC_CommandHub_WorkHelp",
    "Authorize colonists for automatic work", "ProjectHoomans"),
    "Pahintulutan ang mga kolonista para sa awtomatikong trabaho",
    "Core resolves a source-owned Hoomans tooltip key")

local Tooltip = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubTooltip.lua")
local commandDefinition = {
    source = "ProjectHoomans",
    titleKey = "UI_PNC_CommandHub_Category_Work",
    titleFallback = "Work",
    tooltipKey = "UI_PNC_CommandHub_WorkHelp",
    tooltipFallback = "Authorize colonists for automatic work",
}
T.equal(Tooltip.TitleFor(commandDefinition), "Trabaho",
    "shared Core command-hub title uses the owning provider")
T.equal(Tooltip.For(commandDefinition, nil, true),
    "Pahintulutan ang mga kolonista para sa awtomatikong trabaho",
    "shared Core command-hub tooltip uses the owning provider")

local ConversationText = T.load("PsychopatzCore", "common_client",
    "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua")
T.equal(ConversationText.Resolve({
    key = "UI_PsychopatzConversation_Goodbye",
}), "Paalam.", "Core conversation text formats without a nil helper")

local DebugSettings = T.load("PsychopatzCore", "common",
    "PsychopatzCore/Debug/PsychopatzDebugSettings.lua")
local TranslationDiagnostics = T.load("PsychopatzCore", "common",
    "PsychopatzCore/Translation/PsychopatzCoreTranslationDiagnostics.lua")
local auditDefinition = DebugSettings.GetDefinition(
    "PsychopatzCore.TranslationAudit")
T.truthy(auditDefinition, "translation audit is a central debug setting")
T.equal(auditDefinition.title, "Audit ng fallback sa pagsasalin",
    "translation audit setting is localized")
T.falsy(TranslationDiagnostics.IsEnabled(),
    "translation audit defaults off")
T.truthy(DebugSettings.Set("PsychopatzCore.TranslationAudit", true, false),
    "translation audit can be staged")
T.truthy(DebugSettings.ApplyConfigured(),
    "translation audit can be applied at runtime")
T.truthy(TranslationDiagnostics.IsEnabled(),
    "translation audit becomes active after apply")

local DiscoveryPresentation = T.load(
    "ProjectHoomans", "shared",
    "PNC/WorldDiscovery/PNC_WorldDiscoveryPresentation.lua")
T.equal(DiscoveryPresentation.Phase("LOCATED"), "Natukoy ang lokasyon",
    "world discovery phase uses the localized catalog")
T.equal(DiscoveryPresentation.Kind("mobile_group"),
    "Palipat-lipat na grupo",
    "world discovery kind resolves through the catalog")
T.equal(DiscoveryPresentation.SignalName({
    nameKey = "UI_PNC_UnknownSignal",
}), "Hindi kilalang signal",
    "world discovery fallback name uses the localized catalog")
T.equal(DiscoveryPresentation.Faction({
    factionKnown = false,
}), "Hindi ibinunyag ang pangkat",
    "world discovery faction fallback uses the localized catalog")
T.equal(DiscoveryPresentation.Population(4), "Populasyon: 4",
    "world discovery formatted values preserve arguments")

local ToolReplies = T.load(
    "ProjectHoomans", "shared",
    "PNC/Conversation/PNC_ConversationToolReplies.lua")
local localizedNameReply = ToolReplies.Build({
    { name = "ask_name", accepted = true, reason = "dispatched" },
}, { request_id = "translation-name-1", npc_name = "Harley" })
T.truthy(localizedNameReply and string.find(localizedNameReply, "Harley", 1, true),
    "tool reply keeps the authoritative NPC name")
T.falsy(string.find(localizedNameReply or "", "I am ", 1, true),
    "ask-name tool reply uses the localized catalog")
local localizedSocialReply = ToolReplies.Build({
    {
        name = "social_react", reaction = "admire", subtype = "admire",
        accepted = true, authoritative = true, reason = "applied",
    },
}, { request_id = "translation-social-1", npc_name = "Harley" })
T.falsy(string.find(localizedSocialReply or "", "I ", 1, true),
    "social tool reply uses the localized catalog")
local localizedOrderReply = ToolReplies.Build({
    {
        name = "order_follow", commandID = "follow", accepted = true,
        reason = "submitted",
    },
}, { request_id = "translation-order-1", npc_name = "Harley" })
T.falsy(string.find(localizedOrderReply or "", "I ", 1, true),
    "order tool reply uses the localized catalog")

local Loader = T.load(
    "ProjectHoomans", "shared",
    "PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua")
for _, systemName in ipairs({
    "Character", "CommandHub", "Conversation", "Debug", "Discovery",
    "Factions", "Health", "Inventory", "Needs", "Provision", "Research",
    "Scavenge", "Settlement", "Tasks", "Workshop",
}) do
    local path = "media/translation/TL/" .. systemName .. "/"
        .. systemName .. ".json"
    local catalog = Loader.Decode(T.read("ProjectHoomans", "common_mod", path))
    for key, value in pairs(catalog) do
        T.equal(Translation.GetKey(key), value,
            "every modular key resolves through " .. systemName)
    end
end

virtualFiles["OtherMod|media/translation/EN/Partial/Partial.json"] =
    '{"present":"English present","missing":"English fallback"}'
virtualFiles["OtherMod|media/translation/TL/Partial/Partial.json"] =
    '{"present":"Tagalog present","extra":"Only in active language"}'
local partial = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Partial",
    basePath = "media/translation",
})
T.equal(partial:get("present"), "Tagalog present",
    "localized partial catalog resolves its available key")
T.equal(partial:get("missing"), "English fallback",
    "missing localized key falls back to English")
local audit = Manager.GetTranslationAuditSnapshot()
T.equal(audit.counts.english_key_fallback, 1,
    "translation audit identifies a missing localized key")
local warningCountBeforeRepeat = audit.warningCount
T.truthy(warningCountBeforeRepeat >= 1,
    "translation audit emits a warning")
partial:get("missing")
T.equal(Manager.GetTranslationAuditSnapshot().warningCount,
    warningCountBeforeRepeat,
    "translation audit deduplicates repeated warnings")

-- A localized entry can exist yet still be an untouched English sentence.
-- Reset the per-session counters so this assertion isolates that signal.
Manager.SetTranslationAuditEnabled(false)
Manager.SetTranslationAuditEnabled(true)
virtualFiles["OtherMod|media/translation/EN/Equal/Equal.json"] =
    '{"sentence":"This English sentence was not translated"}'
virtualFiles["OtherMod|media/translation/TL/Equal/Equal.json"] =
    '{"sentence":"This English sentence was not translated"}'
local equal = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Equal",
    basePath = "media/translation",
})
T.equal(equal:get("sentence"), "This English sentence was not translated",
    "identical localized prose remains available as a safe fallback")
local equalAudit = Manager.GetTranslationAuditSnapshot()
T.equal(equalAudit.counts.english_value_fallback, 1,
    "translation audit identifies an untranslated localized sentence")
T.equal(equalAudit.warningCount, 1,
    "translation audit warns once for an untranslated localized sentence")

virtualFiles["OtherMod|media/translation/EN/NoLocale/NoLocale.json"] =
    '{"line":"English-only line"}'
local noLocale = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "NoLocale",
    basePath = "media/translation",
})
T.truthy(noLocale, "missing localized catalog fixture registers")

local coverage = Manager.GetTranslationCoverageSnapshot()
T.equal(coverage.language, "TL", "coverage follows the active language")
local partialCoverage
local equalCoverage
local noLocaleCoverage
for _, entry in ipairs(coverage.entries or {}) do
    if entry.modID == "OtherMod" and entry.systemName == "Partial" then
        partialCoverage = partialCoverage or {}
        partialCoverage[entry.key] = entry.status
    elseif entry.modID == "OtherMod" and entry.systemName == "Equal" then
        equalCoverage = entry.status
    elseif entry.modID == "OtherMod" and entry.systemName == "NoLocale" then
        noLocaleCoverage = entry.status
    end
end
T.equal(partialCoverage.present, "translated",
    "coverage marks a localized key as translated")
T.equal(partialCoverage.missing, "missing_key",
    "coverage marks a missing localized key")
T.equal(partialCoverage.extra, "extra_key",
    "coverage marks an extra localized key")
T.equal(equalCoverage, "same_as_english",
    "coverage marks identical English prose for review")
T.equal(noLocaleCoverage, "missing_catalog",
    "coverage marks a missing localized catalog")
local noLocaleSummary
for _, summary in ipairs(coverage.systems or {}) do
    if summary.id == "OtherMod:NoLocale" then
        noLocaleSummary = summary
    end
end
T.equal(noLocaleSummary.state, "missing_catalog",
    "coverage system summary identifies the missing localized catalog")
T.falsy(Manager.Data.OtherMod and Manager.Data.OtherMod.NoLocale,
    "coverage scanning does not populate the normal lazy translation cache")

local ConversationText = T.load("PsychopatzCore", "common_client",
    "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua")
ConversationText.RegisterTable("test.untranslated", "EN", {
    line = "This English conversation line was not translated",
})
ConversationText.RegisterTable("test.untranslated", "TL", {
    line = "This English conversation line was not translated",
})
local beforeConversationAudit = Manager.GetTranslationAuditSnapshot()
T.equal(ConversationText.Resolve({
    key = "line", domain = "test.untranslated",
}), "This English conversation line was not translated",
    "conversation text keeps an identical localized line as a safe fallback")
local afterConversationAudit = Manager.GetTranslationAuditSnapshot()
T.equal(
    (afterConversationAudit.counts.english_value_fallback or 0)
        - (beforeConversationAudit.counts.english_value_fallback or 0),
    1,
    "conversation text reports an identical localized line to Core audit"
)

activeLanguage = "FR"
virtualFiles["OtherMod|media/translation/EN/Radio.json"] =
    '{"radio.test.line":"English radio line"}'
local radio = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Radio",
    basePath = "media/translation",
})
T.equal(radio:get("radio.test.line"), "English radio line",
    "unsupported language falls back to English file")

local duplicate = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Radio",
    basePath = "media/translation",
})
T.equal(duplicate, radio, "duplicate registration is idempotent")
local conflict = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Radio",
    basePath = "media/other-translation",
})
T.falsy(conflict, "conflicting registration is rejected")

virtualFiles["BadMod|media/translation/EN/Bad.json"] =
    '{"bad":null}'
local bad = Manager.registerSystem({
    modID = "BadMod",
    systemName = "Bad",
    basePath = "media/translation",
})
T.equal(bad:get("bad", "Safe fallback"), "Safe fallback",
    "non-string catalog values fail closed")
T.equal(Manager.Diagnostics["BadMod:Bad"].state, "error",
    "invalid catalog is recorded as an error")
T.equal(Manager.GetTranslationAuditSnapshot().counts.missing_english_catalog, 1,
    "translation audit identifies a missing English catalog")

T.finish("pz_custom_translation_manager_smoke")
