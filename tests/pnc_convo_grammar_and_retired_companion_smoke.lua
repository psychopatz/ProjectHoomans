local T = require "tests/support/test"
T.addPackagePaths()

local function resetAll()
    PNC = nil
    PsychopatzCore = nil
    for _, name in ipairs({
        "PNC/ConvoEngine/TokenFormatter_Grammar",
        "PNC/Core/Persistence/PNC_Persistence_CoreProvider",
        "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Ensure",
        "PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Grant",
        "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Tick",
    }) do
        package.loaded[name] = nil
    end
end

-- 1. TokenFormatter_Grammar.CleanPunctuation under Kahlua2 1-capture string.gsub semantics
do
    resetAll()
    local Formatter = require("PNC/ConvoEngine/TokenFormatter_Grammar")

    local origGsub = string.gsub
    string.gsub = function(str, pat, repl, n)
        if type(repl) == "function" then
            return origGsub(str, pat, function(firstCapture)
                return repl(firstCapture)
            end, n)
        end
        return origGsub(str, pat, repl, n)
    end

    local ok, out1 = pcall(
        Formatter.CleanPunctuation,
        "Thank god, Carmela... don't let me bleed out here."
    )
    local ok2, out2 = pcall(
        Formatter.CleanPunctuation,
        "Hold still! i am tying it off. stay awake? yes."
    )
    string.gsub = origGsub

    assert(ok, "CleanPunctuation must not crash under Kahlua2 1-capture gsub: " .. tostring(out1))
    assert(out1 == "Thank god, Carmela... Don't let me bleed out here.",
        "unexpected out1: " .. tostring(out1))
    assert(ok2, "CleanPunctuation must handle ! . ? under Kahlua2 gsub: " .. tostring(out2))
    assert(out2 == "Hold still! I am tying it off. Stay awake? Yes.",
        "unexpected out2: " .. tostring(out2))
end

-- 2. Retired/tombstoned starting companions must not be respawned
do
    resetAll()
    local spawnCalls = 0
    local retiredID = "npcTodpatz_21MI"
    local tombstones = { [retiredID] = { actorId = retiredID, reason = "dead" } }

    PsychopatzCore = {
        RuntimeRole = { AllowsServerCode = function() return true end },
        Actors = {
            DefaultRegistry = {
                HasActiveActor = function(_, id) return false end,
                GetTombstone = function(_, id) return tombstones[id] end,
            },
        },
    }

    local CoreProvider = require("PNC/Core/Persistence/PNC_Persistence_CoreProvider")
    assert(CoreProvider.IsRetiredCoreActor(retiredID, PsychopatzCore) == true,
        "tombstoned actor must be detected as retired")
    assert(CoreProvider.IsRetiredCoreActor("npcOther_1", PsychopatzCore) == false,
        "unknown actor must not be detected as retired")

    PNC.StartingCompanionTraits = {
        DEFINITIONS = {
            { id = "sibling", relationshipKind = "sibling" },
        },
    }
    PNC.Identity = {}
    PNC.Registry = {
        Get = function() return nil end,
    }
    PNC.Persistence = { CoreProvider = CoreProvider }
    PNC.StartingCompanions = {
        ENRICHMENT_VERSION = 2,
        RELATIONSHIP_KEY_VERSION = 1,
        RETRY_DELAY_MS = 2000,
        NextRetryAt = {},
    }
    PNC.StartingCompanionServiceInternal = {
        NowMs = function() return 1000 end,
        HasCanonicalAssignment = function() return false end,
    }
    PNC.PlayerCharacters = {
        GetRegistryRecord = function()
            return {
                uuid = "char_test",
                startingCompanions = {
                    resolved = true,
                    grants = {
                        sibling = {
                            status = "granted",
                            traitID = "sibling",
                            relationshipKind = "sibling",
                            npcID = retiredID,
                            enrichmentVersion = 2,
                        },
                    },
                },
            }
        end,
    }
    PNC.PlayerCharacterTypes = {
        NormalizeStartingCompanionState = function(s) return s end,
    }
    PNC.API = {
        Spawn = function()
            spawnCalls = spawnCalls + 1
            return nil, "should_not_spawn"
        end,
    }

    local Starting = require("PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Ensure")
    require("PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Grant")

    local ok, reason = Starting.Ensure({ id = "player1" }, "char_test", 1000, {})
    assert(ok == false and reason == "granted",
        "Ensure should report no work needed for retired companion, got: " .. tostring(ok) .. "," .. tostring(reason))
    assert(spawnCalls == 0, "Ensure must not attempt to respawn a retired companion")

    local state = PNC.PlayerCharacters.GetRegistryRecord("char_test").startingCompanions
    local oneOk, oneReason = PNC.StartingCompanionServiceInternal.EnsureOne(
        { id = "player1" },
        { uuid = "char_test" },
        state,
        { id = "sibling", relationshipKind = "sibling" },
        1,
        1000,
        {}
    )
    assert(oneOk == true and oneReason == "companion_retired",
        "EnsureOne must return true, companion_retired for retired companion, got: "
        .. tostring(oneOk) .. "," .. tostring(oneReason))
    assert(spawnCalls == 0, "EnsureOne must not attempt to respawn a retired companion")
end

-- 3. RoamingSeat_Tick must preempt when NPC is incapacitated
do
    resetAll()
    local stoppedReason = nil
    PsychopatzCore = {
        RuntimeRole = { AllowsServerCode = function() return true end },
    }
    PNC = {
        ActorControl = { IsPuppetOwned = function() return false end },
        Health = { IsIncapacitated = function(rec) return rec.health and rec.health.incapacitated == true end },
        AutonomyExecutors = {
            RoamingSeat = {
                Internal = {
                    facilityJobs = function() return {} end,
                    currentTime = function(v) return v or 1000 end,
                    distanceTo = function() return 5 end,
                    isSeatOrder = function() return true end,
                    stop = function(_, _, reason) stoppedReason = reason end,
                },
            },
        },
    }
    require("PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat_Tick")
    local RoamingSeat = PNC.AutonomyExecutors.RoamingSeat
    local rec = {
        id = "npc_incap",
        alive = true,
        health = { incapacitated = true },
        runtime = { roamingSeat = { seatUntil = 99999 } },
    }
    local zombie = { isOnFire = function() return false end }
    local handled = RoamingSeat.Tick(rec, zombie, 1000)
    assert(handled == true, "RoamingSeat.Tick should preempt incapacitated NPC")
    assert(stoppedReason == "roaming_seat_preempted",
        "expected roaming_seat_preempted, got: " .. tostring(stoppedReason))
end

print("pnc_convo_grammar_and_retired_companion_smoke OK")
