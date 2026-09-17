-- Project Hoomans custom catalogs.
-- The loader belongs to PsychopatzCore; Hoomans only declares its catalog
-- ownership and provides a small key-aware facade for its UI code.
require "CustomTranslationManager"

local CoreTranslation
if type(require) == "function" then
    local ok, value = pcall(require,
        "PsychopatzCore/Translation/PsychopatzCoreTranslation")
    if ok then CoreTranslation = value end
end

PNC = PNC or {}
PNC.Translation = PNC.Translation or {}

local Translation = PNC.Translation
local Scope = CustomTranslationManager.forMod("ProjectHoomans")
local BASE_PATH = "media/translation"

local SYSTEMS = {
    "Character", "CommandHub", "Conversation", "Debug", "Discovery",
    "Factions", "Health", "Inventory", "Needs", "Provision", "Research",
    "Scavenge", "Settlement", "Tasks", "Workshop",
}

local SEGMENT_SYSTEMS = {
    AIOverlayDisabled = "Debug",
    AIOverlayEnabled = "Debug",
    Action = "Tasks",
    Activities = "Needs",
    Activity = "Needs",
    AudioDebug = "Debug",
    PlayerAnimation = "Debug",
    Bandage = "Health",
    Bandages = "Health",
    Base = "Settlement",
    Building = "Settlement",
    BuildingPlacement = "Settlement",
    Buildings = "Settlement",
    CampOverlayDisabled = "Settlement",
    CampOverlayEnabled = "Settlement",
    Close = "Debug",
    Cancel = "Debug",
    ChangeBandage = "Health",
    Character = "Character",
    ClosestCompanionCommands = "Character",
    ClosestCompanionCommandsPending = "Character",
    Colonist = "Debug",
    Colony = "Settlement",
    ColonyContext = "Debug",
    ColonyDebug = "Debug",
    ColonyJournal = "Debug",
    ColonyManagement = "Settlement",
    ColonyNamePrompt = "Settlement",
    ColonySettings = "Debug",
    CombatOverlayDisabled = "Debug",
    CombatOverlayEnabled = "Debug",
    CommandAttackAuto = "CommandHub",
    CommandAttackMelee = "CommandHub",
    CommandAttackNone = "CommandHub",
    CommandAttackRanged = "CommandHub",
    CommandAttackType = "CommandHub",
    CommandCamp = "CommandHub",
    CommandCorpseHaul = "CommandHub",
    CommandDrink = "Needs",
    CommandEat = "Needs",
    CommandFollow = "CommandHub",
    CommandHub = "CommandHub",
    CommandManualActivity = "Tasks",
    CommandProvision = "Provision",
    CommandRefillWater = "Needs",
    CommandReturnHome = "CommandHub",
    CommandScavengeNearby = "CommandHub",
    CommandSleep = "Needs",
    CommandStay = "CommandHub",
    CommandStopActivity = "CommandHub",
    Context = "Character",
    CommunityAddSupply = "Debug",
    CommunityArchive = "Debug",
    CommunityAssignNPC = "Debug",
    CommunityAuthorization = "Debug",
    CommunityCapacity = "Debug",
    CommunityClaimSite = "Debug",
    CommunityContainment = "Debug",
    CommunityCreateCamp = "Debug",
    CommunityCreateSettlement = "Debug",
    CommunityDestroy = "Debug",
    CommunityFaction = "Debug",
    CommunityHome = "Debug",
    CommunityID = "Debug",
    CommunityInspectorTitle = "Debug",
    CommunityLastAction = "Debug",
    CommunityLeader = "Debug",
    CommunityMapAllied = "Debug",
    CommunityMapAtWar = "Debug",
    CommunityMapClaimed = "Debug",
    CommunityMapCollapsed = "Debug",
    CommunityMapLeader = "Debug",
    CommunityMapOwnFaction = "Debug",
    CommunityMapPopulation = "Debug",
    CommunityMapRelation = "Debug",
    CommunityMapUnoccupied = "Debug",
    CommunityMapVacant = "Debug",
    CommunityModeStatus = "Debug",
    CommunityMorale = "Debug",
    CommunityMoraleDown = "Debug",
    CommunityMoraleUp = "Debug",
    CommunityNPCAffiliation = "Debug",
    CommunityNPCLocation = "Debug",
    CommunityNPCRevisions = "Debug",
    CommunityName = "Debug",
    CommunityNextRole = "Debug",
    CommunityNextSupply = "Debug",
    CommunityNone = "Debug",
    CommunityOverlayDisabled = "Debug",
    CommunityOverlayEnabled = "Debug",
    CommunityPopulation = "Debug",
    CommunityRegistry = "Debug",
    CommunityRemoveNPC = "Debug",
    CommunityRemoveSupply = "Debug",
    CommunityRepair = "Debug",
    CommunityRevisions = "Debug",
    CommunitySectionCommunities = "Debug",
    CommunitySectionDetails = "Debug",
    CommunitySectionFactions = "Debug",
    CommunitySectionNPCs = "Debug",
    CommunitySecurity = "Debug",
    CommunitySecurityDown = "Debug",
    CommunitySecurityUp = "Debug",
    CommunitySelectedNPC = "Debug",
    CommunitySelection = "Debug",
    CommunitySetHome = "Debug",
    CommunitySetLeader = "Debug",
    CommunitySite = "Debug",
    CommunitySiteClaim = "Debug",
    CommunitySupply = "Debug",
    CommunityToggleOverlay = "Debug",
    CommunityTransferNPC = "Debug",
    CommunityValidate = "Debug",
    CommunityValidation = "Debug",
    CompanionCommands = "Character",
    Conversation = "Conversation",
    Contacts = "Discovery",
    CurrentRelationship = "Character",
    Debug = "Debug",
    DebugBandage = "Debug",
    DebugBandageAll = "Debug",
    DebugBandageAlmostDirty = "Debug",
    DebugBandageState = "Debug",
    DebugDamage = "Debug",
    DebugDamageRandom = "Debug",
    DebugDamageSelected = "Debug",
    DebugDamageSpecific = "Debug",
    DebugDiscoveryAllGroups = "Discovery",
    DebugDiscoveryAllSettlements = "Discovery",
    DebugDiscoveryAllSignals = "Discovery",
    DebugDiscoveryButton = "Discovery",
    DebugDiscoveryButtonHelp = "Discovery",
    DebugDiscoveryDiscover = "Debug",
    DebugDiscoveryHideRaw = "Discovery",
    DebugDiscoveryHint = "Discovery",
    DebugDiscoveryReset = "Discovery",
    DebugDiscoveryShowRaw = "Discovery",
    DebugDiscoveryTitle = "Discovery",
    DebugInfection = "Debug",
    DebugInfectionClear = "Debug",
    DebugInfectionFatal = "Debug",
    DebugInfectionFever = "Debug",
    DebugInfectionForce = "Debug",
    DebugInfectionTerminal = "Debug",
    DebugRevive = "Debug",
    DebugHub = "Debug",
    Discovery = "Discovery",
    DiscoveryCall = "Discovery",
    DiscoveryFoundLooters = "Debug",
    DiscoveryFoundMobileGroup = "Debug",
    DiscoveryFoundRefugees = "Debug",
    DiscoveryFoundSettlement = "Debug",
    DiscoveryFoundTraders = "Debug",
    DiscoveryFactionLearned = "Discovery",
    DiscoveryLocatedMobileGroup = "Debug",
    DiscoveryLocatedSettlement = "Debug",
    DiscoveryRefresh = "Discovery",
    DiscoveryScan = "Debug",
    Emblem = "Factions",
    EstablishedRelationship = "Character",
    Facilities = "Settlement",
    Facility = "Settlement",
    FactionArchive = "Factions",
    FactionAssignNPC = "Factions",
    FactionBreakAlliance = "Factions",
    FactionCheckRegistry = "Factions",
    FactionCheckRelation = "Factions",
    FactionClearTelemetry = "Factions",
    FactionCreateAmbientLooterGroup = "Factions",
    FactionCreateLooter = "Factions",
    FactionCreateLooterGroup = "Factions",
    FactionCreateMobileAIRouteGroup = "Factions",
    FactionCreateMobileEnRouteGroup = "Factions",
    FactionCreateMobilePlayerRouteGroup = "Factions",
    FactionCreateMobileRoadGroup = "Factions",
    FactionCreatePlayer = "Factions",
    FactionCreateRefugee = "Factions",
    FactionCreateSettler = "Factions",
    FactionCreateStrategicLooterGroup = "Factions",
    FactionCreateTrader = "Factions",
    FactionDeclareWar = "Factions",
    FactionDisableTelemetry = "Factions",
    FactionEditEmblem = "Factions",
    FactionEnableTelemetry = "Factions",
    FactionExportSnapshot = "Factions",
    FactionForceMobileArrival = "Factions",
    FactionForceMobileDeparture = "Factions",
    FactionForceMobileRoad = "Factions",
    FactionFormAlliance = "Factions",
    FactionGenerateGroup = "Factions",
    FactionGroupSize = "Factions",
    FactionGroupSizeTooltip = "Factions",
    FactionInspectorTitle = "Factions",
    FactionMakePeace = "Factions",
    FactionManageMembers = "Factions",
    FactionMemberAdd = "Factions",
    FactionMemberAddTitle = "Factions",
    FactionMemberAvailable = "Factions",
    FactionMemberBanish = "Factions",
    FactionMemberBanishTitle = "Factions",
    FactionMemberKilled = "Factions",
    FactionMemberNPCs = "Factions",
    FactionMemberNoFaction = "Factions",
    FactionMemberPlayers = "Factions",
    FactionMemberRescued = "Factions",
    FactionMemberTransfer = "Factions",
    FactionMemberTransferTitle = "Factions",
    FactionMemberWindowTitle = "Factions",
    FactionMinorAttack = "Factions",
    FactionMobileControlMode = "Factions",
    FactionMobileFilterAI = "Factions",
    FactionMobileFilterAll = "Factions",
    FactionMobileFilterPlayer = "Factions",
    FactionMobileFilterStaging = "Factions",
    FactionMobileFilterStreet = "Factions",
    FactionMobilePathMode = "Factions",
    FactionMobileRefresh = "Factions",
    FactionMobileRelocate = "Factions",
    FactionNextRank = "Factions",
    FactionNextRole = "Factions",
    FactionNextScenario = "Factions",
    FactionOverlayAffiliation = "Factions",
    FactionOverlayAllied = "Factions",
    FactionOverlayDiagnostics = "Factions",
    FactionOverlayDiplomacy = "Factions",
    FactionOverlayDisabled = "Factions",
    FactionOverlayEnabled = "Factions",
    FactionOverlayEpisodes = "Factions",
    FactionOverlayFear = "Factions",
    FactionOverlayGrievance = "Factions",
    FactionOverlayInvariant = "Factions",
    FactionOverlayNPC = "Factions",
    FactionOverlayNoNPC = "Factions",
    FactionOverlayNoTarget = "Factions",
    FactionOverlayNoTelemetry = "Factions",
    FactionOverlayNotRun = "Factions",
    FactionOverlayReadOnly = "Factions",
    FactionOverlayReconcile = "Factions",
    FactionOverlayResolvedIntent = "Factions",
    FactionOverlayRule = "Factions",
    FactionOverlaySelected = "Factions",
    FactionOverlayStanding = "Factions",
    FactionOverlayTelemetry = "Factions",
    FactionOverlayTitle = "Factions",
    FactionOverlayTruce = "Factions",
    FactionOverlayTrust = "Factions",
    FactionOverlayVersus = "Factions",
    FactionOverlayWaiting = "Factions",
    FactionOverlayWar = "Factions",
    FactionPresenceMode = "Factions",
    FactionRecalculate = "Factions",
    FactionReconcileTreaty = "Factions",
    FactionRemoveNPC = "Factions",
    FactionRepairIndexes = "Factions",
    FactionRepairMobileTravel = "Factions",
    FactionRollMobileDepartures = "Factions",
    FactionRunScenario = "Factions",
    FactionSection = "Factions",
    FactionSectionDiagnostics = "Factions",
    FactionSectionDiplomacy = "Factions",
    FactionSectionMembers = "Factions",
    FactionSectionMobile = "Factions",
    FactionSectionMobileDetails = "Factions",
    FactionSectionNPC = "Factions",
    FactionSectionOverview = "Factions",
    FactionSectionPersistent = "Factions",
    FactionSectionTarget = "Factions",
    FactionSetLeader = "Factions",
    FactionSevereAttack = "Factions",
    FactionStartTruce = "Factions",
    FactionToggleOverlay = "Factions",
    FactionTransferNPC = "Factions",
    FactionViewDiagnostics = "Factions",
    FactionViewDiplomacy = "Factions",
    FactionViewMembers = "Factions",
    FactionViewMobile = "Factions",
    FactionViewOverview = "Factions",
    Farming = "Settlement",
    Fishing = "Settlement",
    FishingScene = "Settlement",
    Flavor = "Conversation",
    FlavorAddress = "Conversation",
    FrequencyScanChannel = "Discovery",
    GroupCompanionCommands = "Character",
    Health = "Health",
    HoomansLLM = "Conversation",
    Interaction = "Character",
    InteractionHistoryHint = "Character",
    KnowledgeCategory = "Research",
    KnowledgeJournal = "Research",
    Inventory = "Inventory",
    Job = "Tasks",
    JobRequirement = "Tasks",
    Jobs = "Tasks",
    Journal = "Conversation",
    KnowledgeLearned = "Research",
    KnownBeforeOutbreak = "Debug",
    LumberScene = "Settlement",
    MapCommand = "Discovery",
    MapHoomans = "Discovery",
    MapNamesOff = "Discovery",
    MapNamesOffHelp = "Discovery",
    MapNamesOn = "Discovery",
    MapNamesOnHelp = "Discovery",
    MapPlayerSettlement = "Settlement",
    MapTrack = "Discovery",
    MapWorldOff = "Discovery",
    MapWorldOffHelp = "Discovery",
    MapWorldOn = "Discovery",
    MapWorldOnHelp = "Discovery",
    Medical = "Health",
    MobileGroup = "Debug",
    MonitorActive = "Debug",
    MonitorAuditBodies = "Debug",
    MonitorCommandMap = "Debug",
    MonitorDamage = "Debug",
    MonitorEquipment = "Debug",
    MonitorFocus = "Debug",
    MonitorForceAbstract = "Debug",
    MonitorForceLive = "Debug",
    MonitorHeal = "Debug",
    MonitorMapMarker = "Debug",
    MonitorManualActivities = "Debug",
    MonitorOff = "Debug",
    MonitorOn = "Debug",
    MonitorProvisionStats = "Debug",
    MonitorRecordDebug = "Debug",
    MonitorRefresh = "Debug",
    MonitorRelationships = "Debug",
    MonitorSelectActivityNPC = "Debug",
    MonitorSelectNPC = "Debug",
    MonitorStopRecordDebug = "Debug",
    MonitorTabActivities = "Debug",
    MonitorTabRoster = "Debug",
    MonitorTeleport = "Debug",
    MonitorTitle = "Debug",
    MonitorToggleAnimation = "Debug",
    MonitorToggleCombat = "Debug",
    MonitorToggleOverlay = "Debug",
    MonitorTogglePaths = "Debug",
    MonitorTrack = "Debug",
    MonitorUnauthorized = "Debug",
    Morale = "Needs",
    NPCPresentationLab = "Debug",
    NPCTraitDebug = "Debug",
    NameplateDebug = "Debug",
    NameplateDebugDisabled = "Debug",
    NameplateDebugEnabled = "Debug",
    Need = "Needs",
    Needs = "Needs",
    NoPlayerInteractions = "Character",
    Nutrition = "Needs",
    OrderRoamNearby = "Tasks",
    Orders = "Tasks",
    Overlay = "Settlement",
    PathOverlayDisabled = "Debug",
    PathOverlayEnabled = "Debug",
    PlayerNPCInteractions = "Character",
    Point = "Debug",
    Provision = "Provision",
    ProvisionDebug = "Debug",
    Recovery = "Health",
    RelationshipApproval = "Character",
    RelationshipChange = "Character",
    RelationshipFamiliarity = "Character",
    RelationshipRespect = "Character",
    Research = "Research",
    Revive = "Debug",
    Roster = "Debug",
    Scavenge = "Scavenge",
    Settings = "CommandHub",
    SettlementReason = "Settlement",
    Sink = "Needs",
    Spawn = "Debug",
    SpawnCompanion = "Debug",
    SpawnEquipmentBoth = "Debug",
    SpawnEquipmentChances = "Debug",
    SpawnEquipmentMelee = "Debug",
    SpawnEquipmentRanged = "Debug",
    SpawnHostile = "Debug",
    SpawnNeutral = "Debug",
    Stat = "Health",
    Stockpile = "Provision",
    Storage = "Inventory",
    Task = "Tasks",
    TaskBrain = "Tasks",
    Tasks = "Tasks",
    TollDeferred = "Debug",
    TollDemand = "Debug",
    TollDepartureIgnored = "Debug",
    TollExpired = "Debug",
    TollInsufficient = "Debug",
    TollLeave = "Debug",
    TollPaid = "Debug",
    TollPay = "Debug",
    TollRefuse = "Debug",
    TollTitle = "Debug",
    TollWar = "Debug",
    ToolFeedback = "Tasks",
    Trait = "Character",
    UniqueNPCDebug = "Debug",
    UniqueNPCEditor = "Character",
    UnknownSignal = "Discovery",
    Utilities = "Debug",
    VehicleSeatOccupied = "Character",
    Work = "Tasks",
    WorkScene = "Tasks",
    Workshop = "Workshop",
    WorldSignalScanner = "Debug",
    Wound = "Health",
}

Translation.Systems = Translation.Systems or {}
for _, systemName in ipairs(SYSTEMS) do
    if not Translation.Systems[systemName] then
        Translation.Systems[systemName] = Scope.registerSystem(systemName, BASE_PATH)
    end
end

-- Compatibility for code that used the old trait handle. The catalog itself
-- now lives at media/translation/<LANG>/Character/Character.json.
Translation.Traits = Translation.Systems.Character

local function systemForKey(key)
    if type(key) ~= "string" then return nil end
    local segment = string.match(key, "^UI_PNC_([^_]+)")
    return segment and SEGMENT_SYSTEMS[segment] or nil
end

function Translation.Get(systemName, key, fallback)
    local handle = Translation.Systems[systemName]
    if handle and type(handle.get) == "function" then
        return handle:get(key, fallback)
    end
    return fallback or key or ""
end

function Translation.GetKey(key, fallback)
    if type(key) ~= "string" or key == "" then
        return fallback or ""
    end
    local systemName = systemForKey(key)
    if systemName then
        return Translation.Get(systemName, key, fallback)
    end
    -- Only genuine PZ-native keys reach getText. Hoomans UI_PNC_* keys are
    -- always resolved through the Core-backed custom catalogs above.
    if type(getText) == "function" then
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then
            return value
        end
    end
    return fallback or key
end

if CoreTranslation and type(CoreTranslation.RegisterProvider) == "function" then
    CoreTranslation.RegisterProvider("ProjectHoomans", {
        getKey = function(key, fallback)
            return Translation.GetKey(key, fallback)
        end,
    })
end

function Translation.Tr(first, second, third)
    if third ~= nil and Translation.Systems[first] then
        return Translation.Get(first, second, third)
    end
    return Translation.GetKey(first, second)
end

local function formatText(value, args)
    value = string.gsub(value, "%%(%d+)", function(index)
        local position = tonumber(index)
        local replacement = position and args[position] or nil
        return replacement ~= nil and tostring(replacement) or "%%" .. index
    end)
    local ok, formatted = pcall(string.format, value,
        args[1], args[2], args[3], args[4])
    return ok and formatted or value
end

function Translation.TrFormat(key, fallback, ...)
    local value = Translation.GetKey(key, fallback)
    return formatText(value, { ... })
end

function Translation.Format(systemName, key, fallback, ...)
    local value = Translation.Get(systemName, key, fallback)
    return formatText(value, { ... })
end

return Translation
