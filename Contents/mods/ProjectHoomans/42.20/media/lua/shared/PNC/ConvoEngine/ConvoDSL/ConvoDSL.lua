-- Project Hoomans thin adopter facade binding Hoomans' ResponseCatalog, Lexicon,
-- FlowRegistry, and Offer stores to PsychopatzCore's shared runtime ConvoDSL engine.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local CoreDSL = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL"
require "PNC/ConvoEngine/ConvoDSL/ConvoDSL_Schema"
local Lexicon = PNC.ConvoEngine.Lexicon or require "PNC/ConvoEngine/Lexicon"

local function resolveFlowRegistry()
    if type(PNC.ConvoEngine.DialogueFlowRegistry) == "table" then
        return PNC.ConvoEngine.DialogueFlowRegistry
    end
    if type(require) == "function" then
        local ok, loaded = pcall(require, "PNC/ConvoEngine/Dialogue/FlowRegistry")
        if ok and type(loaded) == "table" then
            PNC.ConvoEngine.DialogueFlowRegistry = loaded
            return loaded
        end
    end
    return nil
end

local function bindHoomansTargets()
    local targets = CoreDSL.Loader and CoreDSL.Loader._targets or nil
    if type(targets) == "table"
        and targets.Catalog == PNC.ConvoEngine.ResponseCatalog
        and targets.Catalog ~= nil
        and targets.FlowRegistry ~= nil
        and targets.Lexicon == Lexicon
        and targets.OfferBlueprints == PNC.ConvoEngine.OfferBlueprints
        and targets.GeneratedOffers == PNC.ConvoEngine.GeneratedOffers
        and targets.GeneratedOfferUses == PNC.ConvoEngine.GeneratedOfferUses
        and CoreDSL.Loader.PRIMARY_MOD_ID == "ProjectHoomans"
    then
        return
    end
    PNC.ConvoEngine.OfferBlueprints = PNC.ConvoEngine.OfferBlueprints or {}
    PNC.ConvoEngine.GeneratedOffers = PNC.ConvoEngine.GeneratedOffers or {}
    PNC.ConvoEngine.GeneratedOfferUses = PNC.ConvoEngine.GeneratedOfferUses or {}
    CoreDSL.Loader.PRIMARY_MOD_ID = "ProjectHoomans"
    CoreDSL.Loader.BASE_MOD_ID = "ProjectHoomans"
    CoreDSL.BindTargets({
        Catalog = PNC.ConvoEngine.ResponseCatalog,
        FlowRegistry = resolveFlowRegistry(),
        Lexicon = Lexicon,
        OfferBlueprints = PNC.ConvoEngine.OfferBlueprints,
        GeneratedOffers = PNC.ConvoEngine.GeneratedOffers,
        GeneratedOfferUses = PNC.ConvoEngine.GeneratedOfferUses,
    })
end

bindHoomansTargets()

local ConvoDSL = PNC.ConvoEngine.ConvoDSL or {}
PNC.ConvoEngine.ConvoDSL = ConvoDSL

ConvoDSL.VERSION = CoreDSL.VERSION
ConvoDSL.Schema = CoreDSL.Schema
ConvoDSL.Parser = CoreDSL.Parser
ConvoDSL.StoryCompiler = CoreDSL.StoryCompiler
ConvoDSL.StoryMetadata = CoreDSL.StoryMetadata
ConvoDSL.Loader = CoreDSL.Loader
ConvoDSL.BASE_ROOT = CoreDSL.BASE_ROOT
ConvoDSL.PACK_SUBDIR = CoreDSL.PACK_SUBDIR

function ConvoDSL.NewStream(sourcePath, defaultLang)
    return CoreDSL.NewStream(sourcePath, defaultLang)
end

function ConvoDSL.ParseText(text, sourcePath, defaultLang)
    return CoreDSL.ParseText(text, sourcePath, defaultLang)
end

function ConvoDSL.ApplyScripts(scripts, langOverride)
    bindHoomansTargets()
    return CoreDSL.ApplyScripts(scripts, langOverride)
end

function ConvoDSL.RegisterModSource(modID, packSubdir)
    return CoreDSL.RegisterModSource(modID, packSubdir)
end

function ConvoDSL.ActiveLanguage()
    return CoreDSL.ActiveLanguage()
end

function ConvoDSL.LoadLanguage(language, opts)
    bindHoomansTargets()
    return CoreDSL.LoadLanguage(language, opts)
end

function ConvoDSL.EnsureActiveLanguage()
    bindHoomansTargets()
    return CoreDSL.EnsureActiveLanguage()
end

function ConvoDSL.EnsurePoolLoaded(poolID)
    bindHoomansTargets()
    return CoreDSL.EnsurePoolLoaded(poolID)
end

function ConvoDSL.StepStream(maxFiles, budgetMs)
    bindHoomansTargets()
    return CoreDSL.StepStream(maxFiles, budgetMs)
end

function ConvoDSL.FlushStream()
    bindHoomansTargets()
    return CoreDSL.FlushStream()
end

function ConvoDSL.PendingCount()
    return CoreDSL.PendingCount()
end

function ConvoDSL.Reload(language, opts)
    bindHoomansTargets()
    return CoreDSL.Reload(language, opts)
end

function ConvoDSL.GetDiagnostics()
    return CoreDSL.GetDiagnostics()
end

function ConvoDSL.GetStory(storyID)
    return CoreDSL.GetStory(storyID)
end

function ConvoDSL.ResolveReaction(storyID, nodeID, context, opts)
    return CoreDSL.ResolveReaction(storyID, nodeID, context, opts)
end

function ConvoDSL.ApplyReactionEffects(actorID, targetKey, reaction, opts)
    return CoreDSL.ApplyReactionEffects(actorID, targetKey, reaction, opts)
end

function ConvoDSL.ProjectPersonalityContext(personality, outCtx)
    return CoreDSL.ProjectPersonalityContext(personality, outCtx)
end

return ConvoDSL
