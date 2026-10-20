# Build-time corpus notices

Project Hoomans uses two reviewed English utterance records from the following
build-time sources. The raw corpora, archives, and remote URLs are not read by
Project Zomboid and are not shipped in runtime media.

## MASSIVE 1.0

- Source: <https://github.com/alexa/massive>
- License: Creative Commons Attribution 4.0 International (CC BY 4.0)
- License text: <https://raw.githubusercontent.com/alexa/massive/main/LICENSE.txt>
- Additional source notice: <https://github.com/alexa/massive/blob/main/NOTICE.md>
- Imported record: English `en-US`, train, record `98`, intent `weather_query`
- Source SHA-256: `c70f75c6a543a26e249ec383df67733ad9b1066f6c0406c2e04a3f03356e407e`

## Schema-Guided Dialogue (DSTC8 / SGD)

- Source: <https://github.com/google-research-datasets/dstc8-schema-guided-dialogue>
- License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
- License text: <https://raw.githubusercontent.com/google-research-datasets/dstc8-schema-guided-dialogue/master/LICENSE.txt>
- Imported record: `train/dialogues_090.json`, dialogue `90_00031`, turn `6`, service `Weather_1`, intent `GetWeather`
- Source SHA-256 (reviewed dialogue file): `78310f5e8e4c5a48cb600d36ba762448d13ebdd91f30ef09831251f5345fa836`

The selected utterances are authored into the reviewed canonical interaction
source with source references, mappings, collision checks, EN/TL generation,
and real production Lua-worker verification. They are derived interaction
patterns, not a runtime copy of either corpus.
