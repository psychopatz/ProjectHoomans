# Orders

## Colonist Orders
- `follow`
- `guard`
- `patrol`

## Shared Orders
- `roam`: faction-neutral area roaming with configurable center, radius, target radius, and movement mode
- colonist roamers engage hostile NPCs and zombies according to their hostility configuration
- hostile roamers engage players, non-hostile NPCs, and zombies according to their hostility configuration

## Hostile Orders
- `hostile_hunt`
- `hostile_roam` is accepted as a legacy alias and normalized to `roam`

## Ownership
- orders are normalized in `PNC_OrderSystem`
- `PNC_JobSystem` derives active job from order
- `PNC_BehaviorSystem` executes the job
- behavior modules can register order normalizers, order-to-job mappings, and job handlers without expanding the central dispatcher
- `PNC_Behavior_Roaming` is the reference implementation for this extension path and supports independently registered roam modes

## Extension Contract
- register order payload normalization with `PNC.OrderSystem.RegisterNormalizer(orderKind, normalizer)`
- register order-to-job selection with `PNC.JobSystem.RegisterOrder(orderKind, jobName)`
- register execution with `PNC.BehaviorRegistry.Register(jobName, tickHandler)`
- roaming variants can instead register a mode with `PNC.BehaviorRoaming.RegisterMode(modeName, tickHandler)`
- a future seated-idle module can therefore own its order, animation, and cleanup without adding branches to `PNC_BehaviorSystem`
