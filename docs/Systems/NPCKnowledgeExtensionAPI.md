# NPC Knowledge Extension API

Trusted bootstrap Lua can extend NPC knowledge without changing central persistence, networking, dossier UI, or the laboratory layout.

```lua
PNC.KnowledgeProviders.Register("my_mod_profile", {
    GetValue = function(npcRecord, descriptor)
        return npcRecord.myMod and npcRecord.myMod.favoriteColor
    end,
})

PNC.KnowledgeDescriptors.Register({
    id = "my_mod.favorite_color",
    category = "preferences",
    providerID = "my_mod_profile",
    resolverID = "categorical_votes",
    valueType = "categorical",
    privacy = "personal",
    discovery = {
        allowObservation = true,
        allowDisclosure = true,
        suspectedThreshold = .30,
        knownThreshold = .70,
    },
    capabilities = { observable = true, disclosable = true },
    presentation = { nameKey = "UI_MyMod_FavoriteColor" },
})
```

Providers must return serialization-safe primitives or small primitive tables. Never return Java objects, NPC records, trait objects, inventory objects, or live bodies.

To add gameplay evidence, call the server-only API from an adapter:

```lua
PNC.NPCKnowledge.RecordEvidence({
    characterUUID = characterUUID,
    npcID = npcID,
    descriptorID = "my_mod.favorite_color",
    sourceType = "observed_behavior",
    strength = .55,
    direction = 1,
    payload = { observedValue = "blue" },
    sourceEventID = eventID,
    worldAgeHours = worldAgeHours,
})
```

Resolvers are registered as `{ Resolve = function(descriptor, evidence, familiarity) ... end }` and return `{ value, confidence, status }` or `nil`. Built-ins include `signed_evidence`, `categorical_votes`, `direct_fact`, `threshold_boolean`, and `competence_band`.

Use namespaced IDs. Removed descriptors are left as orphaned persisted evidence and ignored by normal UI; the laboratory reports them safely. Aliases may be supplied on descriptor registration for a controlled rename.
