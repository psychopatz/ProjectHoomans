# Progress for NPC Replication Scaling

## Current state

- **P1 developer-side accepted.** The [baseline](P1_BASELINE.md) records the consumer audit and 540 headless measurements.
- **P2 developer-side accepted.** The [hydration evidence](P2_HYDRATION.md) records lean replication, bounded demand and mutation equality.
- **P3 developer-side evaluation accepted.** The [representation evidence](P3_REPRESENTATIONS.md) records exact field packing, candidate selection and costs. Catalog-dependent encodings remain off. Native multiplayer remains user-owned.

## Next Chunk

**P4 revisioned appearance patch and convergence.** Compile exact changes from one retained baseline to its adjacent revision. Gate patch support, preserve strict set/clear/default semantics, and recover with a bounded resolved reply on a gap or incompatibility. Re-run production regression and benchmark gates.
