-- Dynamic template-variable scanner & suggestion-frame resolution smoke test.
-- Dynamically scans all EN .convo scripts and EN Conversation translation JSONs
-- across ProjectHoomans and PsychopatzCore, verifying that every {variable}
-- placeholder is well-formed and resolves/collapses cleanly without leaking
-- raw braces, and that suggestion frames (e.g. identity.choice.real_name)
-- never leak "{speaker.name}" into player messages.

local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueState.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueRouter.lua")
local TokenFormatter = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/TokenFormatter.lua"
)
T.load("ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCatalog.lua")
local Suggestions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/Dialogue/Suggestions.lua"
)

-- 1) Dynamically enumerate all EN .convo scripts and EN Conversation JSONs.
local function listFiles(root, ext)
    local out = {}
    local cmd = string.format('find "%s" -type f -name "*.%s" 2>/dev/null | sort', root, ext)
    local pipe = io.popen(cmd)
    if not pipe then return out end
    for line in pipe:lines() do
        if line ~= "" then out[#out + 1] = line end
    end
    pipe:close()
    return out
end

local convoFiles = listFiles("Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks", "convo")
local hoomansJsonFiles = listFiles("Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation", "json")
local coreJsonFiles = listFiles("../psychopatzCore/Contents/mods/PsychopatzCore/common/media/translation/EN/Conversation", "json")

T.truthy(#convoFiles > 0, "dynamic scan found EN .convo files")
T.truthy(#hoomansJsonFiles > 0, "dynamic scan found ProjectHoomans EN Conversation JSON files")
T.truthy(#coreJsonFiles > 0, "dynamic scan found PsychopatzCore EN Conversation JSON files")

-- Grounded token map for dynamic resolution testing.
local groundedTokens = {
    ["speaker.name"] = "Psycho",
    ["speaker.alias"] = "Alex",
    ["addressee.name"] = "Jordan",
    ["addressee.pos"] = "your",
    ["addressee.obj"] = "you",
    ["player.name"] = "Psycho",
    ["npc.name"] = "Jordan",
    ["claimed.name"] = "Psycho",
    ["target.name"] = "bandit",
    ["term.address"] = "partner",
    ["scene.location"] = "the alley",
    ["scene.clock"] = "two o'clock",
    ["scene.relative"] = "ahead",
    ["location.phrase"] = "in the kitchen",
    ["opener.casual"] = "Hey",
    ["victim.name"] = "Mara",
    ["victim.subj"] = "she",
    ["lost.name"] = "Sam",
    ["thief.obj"] = "him",
    ["end"] = ".",
    ["value"] = "clear",
    ["content"] = "supplies",
    ["role"] = "scout",
    ["reason"] = "storm",
    ["giftItemSummary"] = "a bandage",
    ["giftItemName"] = "Bandage",
    ["state.job"] = "guard",
    ["floor.speaker_name"] = "Jordan",
    ["noun.zombie"] = "walker",
    ["noun.road"] = "road",
    ["noun.dark"] = "the dark",
    ["clause.wary_tail"] = "Keep your distance.",
    ["clause.stay_sharp"] = "Stay sharp.",
    ["clause.thanks_backup"] = "Thanks for the backup.",
    ["clause.gossip_closure"] = "We'll see how it plays out.",
    ["clause.banter_closure"] = "Anyway, stay alert.",
    ["slot.wound.part"] = "left arm",
    ["slot.wound.label"] = "deep wound",
    ["slot.item"] = "water",
    ["slot.item.name"] = "Water Bottle",
    ["slot.loot.name"] = "canned beans",
    ["slot.weapon"] = "crowbar",
    ["slot.weapon.name"] = "Crowbar",
    ["slot.skill.name"] = "Carpentry",
    ["slot.killer.name"] = "raider",
    ["slot.injured.name"] = "Mara",
    ["slot.faction.name"] = "Wardens",
    ["slot.broadcast.channel"] = "Knox News",
    ["slot.broadcast.topic"] = "the outbreak",
    ["slot.broadcast.episode"] = "broadcast",
    ["slot.show.name"] = "Life and Living",
    ["slot.source"] = "radio",
    ["slot.gossip_time"] = "earlier",
    ["slot.gossip_location"] = "downtown",
    ["slot.giver_address"] = "friend",
    ["slot.known_value"] = "clear",
    ["slot.time_estimate"] = "afternoon",
    ["slot.toll.amount"] = "10",
    ["slot.identity_claim.name"] = "Psycho",
    ["sleep.observe"] = "You look tired",
    ["sleep.suggest"] = "get some rest",
    ["sleep.request_need"] = "I need sleep",
    ["sleep.request_ask"] = "can we rest",
}

local function extractQuotedTemplates(path, isJson)
    local templates = {}
    local fh = io.open(path, "r")
    if not fh then return templates end
    for line in fh:lines() do
        if string.find(line, "{", 1, true) then
            if isJson then
                local val = string.match(line, ':%s*"(.+)"%s*,?%s*$')
                if val and string.find(val, "{", 1, true) then
                    templates[#templates + 1] = val
                end
            else
                local trimmed = line:gsub("^%s+", "")
                if string.sub(trimmed, 1, 1) ~= "#" then
                    local val = string.match(trimmed, '"(.+)"')
                    if val and string.find(val, "{", 1, true) then
                        templates[#templates + 1] = val
                    end
                end
            end
        end
    end
    fh:close()
    return templates
end

local scannedFiles = 0
local scannedTemplates = 0
local uniqueVars = {}
local uniqueVarCount = 0
local failures = {}

local function scanFileSet(files, isJson)
    for _, path in ipairs(files) do
        scannedFiles = scannedFiles + 1
        local templates = extractQuotedTemplates(path, isJson)
        for _, tmpl in ipairs(templates) do
            scannedTemplates = scannedTemplates + 1
            for var in string.gmatch(tmpl, "{([^}]+)}") do
                if not uniqueVars[var] then
                    uniqueVars[var] = true
                    uniqueVarCount = uniqueVarCount + 1
                end
            end

            -- Must not have unbalanced braces.
            local _, opens = string.gsub(tmpl, "{", "")
            local _, closes = string.gsub(tmpl, "}", "")
            if opens ~= closes then
                failures[#failures + 1] = "unbalanced braces in " .. path .. ": " .. tmpl
            end

            -- Grounded formatting must leave zero raw {tokens}.
            local rendered = TokenFormatter.Format(tmpl, groundedTokens)
            if string.find(rendered, "{", 1, true) or string.find(rendered, "}", 1, true) then
                failures[#failures + 1] = "grounded leak in " .. path .. ": " .. tmpl .. " -> " .. rendered
            end

            -- Empty-context formatting (solo/unknown addressee) must also leave zero raw {tokens}.
            local collapsed = TokenFormatter.Format(tmpl, {})
            if string.find(collapsed, "{", 1, true) or string.find(collapsed, "}", 1, true) then
                failures[#failures + 1] = "empty-context leak in " .. path .. ": " .. tmpl .. " -> " .. collapsed
            end
        end
    end
end

scanFileSet(convoFiles, false)
scanFileSet(hoomansJsonFiles, true)
scanFileSet(coreJsonFiles, true)

T.truthy(scannedTemplates > 100, "dynamic scan verified >100 templates (got " .. tostring(scannedTemplates) .. ")")
T.truthy(uniqueVarCount > 20, "dynamic scan verified >20 unique variables (got " .. tostring(uniqueVarCount) .. ")")
if #failures > 0 then
    error("template variable scan failed (" .. tostring(#failures) .. " issues), first: " .. tostring(failures[1]))
end

-- 2) Regression: clicking identity.choice.real_name must NOT be hijacked by raw .convo
--    offer "I'm {speaker.name}." when StaticProvider_Identity already provided grounded text & slots.
local identityView = {
    spec = {
        npcID = "npc:stranger_1",
        context = {
            playerName = "Psycho",
            playerFirstName = "Psycho",
        },
    },
    lastSemanticDialogueResult = {
        decision = {
            flow = {
                flowId = "identity",
                nodeId = "await_player_name",
                branchOffers = {
                    {
                        id = "identity.choice.real_name",
                        labelFallback = "Say your real name",
                        utteranceFallback = "I'm {speaker.name}.",
                        frame = { intent = "INFORM", subject = "IDENTITY" },
                    },
                },
            },
        },
    },
    semanticSuggestions = {
        candidates = {
            {
                id = "identity.choice.real_name",
                providerID = "projecthoomans.static",
                frame = {
                    schemaVersion = Suggestions.VERSION,
                    kind = "semantic_click_frame",
                    candidateID = "identity.choice.real_name",
                    providerID = "projecthoomans.static",
                    intent = "INFORM",
                    speechAct = "INFORM",
                    subject = "IDENTITY",
                    slots = {
                        identityClaim = { mode = "canonical", name = "Psycho" },
                    },
                    textFallback = "I'm Psycho.",
                    utteranceFallback = "I'm Psycho.",
                    requestRevision = 1,
                },
            },
        },
    },
}

local clickedFrame = identityView.semanticSuggestions.candidates[1].frame
local ir, err = Suggestions.FrameToIR(clickedFrame, identityView)
T.truthy(ir ~= nil, "provider identity frame converts to IR (err=" .. tostring(err) .. ")")
T.equal(ir.rawText, "I'm Psycho.", "provider identity frame preserves realized name instead of {speaker.name}")
T.falsy(string.find(ir.rawText, "{", 1, true), "provider identity IR contains no raw braces")
T.equal(ir.slots and ir.slots.identityClaim and ir.slots.identityClaim.name, "Psycho",
    "provider identity IR preserves slots.identityClaim.name")

-- 3) Regression: even a direct raw .convo branch offer with {speaker.name} / {addressee.name}
--    must resolve tokens cleanly when converted via FrameToIR or ResolveFrameText.
local rawBranchView = {
    spec = {
        npcID = "npc:jordan",
        context = {
            playerFirstName = "Psycho",
            identityKnown = true,
            npcFirstName = "Jordan",
        },
    },
    lastSemanticDialogueResult = {
        decision = {
            flow = {
                flowId = "identity",
                nodeId = "await_player_name",
                branchOffers = {
                    {
                        id = "test.raw_branch_offer",
                        labelFallback = "Introduce yourself to {addressee.name}",
                        utteranceFallback = "I'm {speaker.name}, nice to meet you, {addressee.name}.",
                        frame = { intent = "INFORM", subject = "IDENTITY" },
                    },
                },
            },
        },
    },
}
local rawFrame = {
    schemaVersion = Suggestions.VERSION,
    kind = "semantic_click_frame",
    candidateID = "test.raw_branch_offer",
    requestRevision = 1,
}
local branchIR, branchErr = Suggestions.FrameToIR(rawFrame, rawBranchView)
T.truthy(branchIR ~= nil, "raw branch offer converts to IR (err=" .. tostring(branchErr) .. ")")
T.equal(branchIR.rawText, "I'm Psycho, nice to meet you, Jordan.",
    "raw branch offer resolves both {speaker.name} and {addressee.name}")
T.falsy(string.find(branchIR.rawText, "{", 1, true), "raw branch offer IR leaks no braces")

T.finish("pnc_template_variable_scan_smoke")
