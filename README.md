# rtl-to-camodel skill

`rtl-to-camodel` is a Codex skill for migrating RTL design modules into cycle-accurate C++ CModel/CAModel implementations and verifying them against RTL timing.

The skill focuses on:

- RTL timing analysis with hardware semantics.
- Valid/ready handshake and backpressure correctness.
- FIFO, arbiter, register, ID, and pipeline timing mapping.
- Reset-start RTL trace replay into CModel.
- Cycle-by-cycle valid/ready/payload comparison.
- Clear result labels such as `strict-timing`, `functional-pass`, `subset`, and `not-proven`.

This repository contains only the skill instructions and references. It does not include RTL source code, CModel source code, simulation waveforms, logs, licenses, or project-private data.

## Install

Copy the skill directory into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
cp -r rtl-to-camodel ~/.codex/skills/
```

After installation, the skill should be available at:

```text
~/.codex/skills/rtl-to-camodel/SKILL.md
```

## Use

Ask Codex to use the skill when migrating or verifying RTL against CModel:

```text
Use $rtl-to-camodel to migrate this RTL module into a cycle-accurate CModel implementation.
```

Example requests:

```text
Compare this RTL module and CModel module cycle by cycle.
```

```text
Replay the RTL waveform trace into the CModel and tell me whether valid/ready and payload match.
```

## Repository layout

```text
rtl-to-camodel/
├── SKILL.md
├── agents/
│   └── openai.yaml
└── references/
    └── rtl-camodel-timing-checklist.md
```

## Contributing

Useful contributions include:

- Better timing checklists for specific hardware patterns.
- Replay-driver best practices.
- Clearer result-label definitions.
- Additional public examples that do not include proprietary RTL, waveforms, logs, or private paths.

Please avoid adding generated build outputs, waveforms, test logs, license files from EDA tools, or project-private data.
