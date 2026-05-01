---
name: agents-md-generator
description: Create, generate, update, repair, trim, or split minimal AGENTS.md files for repository roots and confirmed nested modules using progressive disclosure. Use for missing, bloated, contradictory, or outdated agent instructions, monorepos, services, packages, module context, and portable agent guidance without assuming any fixed agent folder structure.
compatibility: Filesystem-based coding agents with read/write access. Script execution optional.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "2.0"
---

# AGENTS.md Generator (Root + Nested, Portable)

## Goal
Maintain small, high-signal AGENTS.md files:

- Root AGENTS.md — purpose of repository, navigation, universal toolchain, canonical commands, links to docs and skills.
- Nested AGENTS.md — module/package purpose, local commands, module references.

Use **progressive disclosure**: keep AGENTS.md concise; push details to docs or skills.

---

## Skill location (agent-specific)
- **Do NOT assume `.agents/` or any fixed directory exists.**
- Skills may live:
  - inside the repository (embedded),
  - or in an external/global skill library (external).
- If referencing local skills, use only an existing skill root already used by
  the project or an existing project path already mentioned by repo docs.
- If no local skill directory exists — **reference skills by name only (external)**.
- **Never create hidden agent directories** just to store skills.

---

## Resource Routing

Use templates as skeletons, not literal output:

- Read `references/AGENTS_TEMPLATE_ROOT.md` only when creating or updating the
  root `AGENTS.md`.
- Read `references/AGENTS_TEMPLATE_MODULE.md` only after a directory is
  confirmed as a nested module that needs its own `AGENTS.md`.
- Replace or remove every placeholder. Final `AGENTS.md` files must not contain
  unresolved `<...>` template markers.

---

## When to run
Run this skill when:

- AGENTS.md is missing, bloated, contradictory, or outdated.
- AGENTS.md needs to be generated, repaired, trimmed, split, or updated.
- A new package/service/module appears.
- Repository structure changes (monorepo growth or split).
- Teams want consistent agent context across diverse stacks.

---

## Workflow (Deterministic)

### 1. Discover repository shape
- Identify repository root (git root if available).
- Detect language/tool markers:
  - `package.json`, `pnpm-workspace.yaml`
  - `go.mod`, `go.work`
  - `pyproject.toml`
  - `Cargo.toml`
  - `pubspec.yaml`
  - `pom.xml`, `build.gradle`
- Locate `docs/`, `README.md`, existing `AGENTS.md`.

---

### 2. Detect module boundaries
Create nested AGENTS.md if directory:

- Contains independent build/package manifest
- OR represents deployable/service unit (`apps/`, `services/`, `packages/`)
- AND adds distinct commands, docs, ownership, deployment notes, or toolchain
  guidance compared with parent scope.

Do not create a nested `AGENTS.md` that only repeats the root instructions.

---

### 3. Generate/Update Root AGENTS.md
Constraints:

- Ideal size: ≤ 60 lines
- Must include:
  - One-sentence repository purpose
  - Primary toolchain/package manager
  - Canonical commands (if non-standard)
  - Links to docs
  - Instruction to read nested AGENTS.md when inside modules
  - Optional skill references (adaptive: local or external)
- Preserve verified commands, docs, security/secrets/deployment warnings, and
  important local rules from any existing root `AGENTS.md`.

---

### 4. Generate/Update Nested AGENTS.md
Constraints:

- Ideal size: ≤ 40 lines
- Must include:
  - One-sentence module purpose
  - Module-specific commands
  - Local documentation references
  - Optional skill references (adaptive)
- Preserve verified module warnings, ownership, deployment notes, and local
  rules from any existing nested `AGENTS.md`.

---

### 5. Progressive Disclosure Rules
- Do not embed style guides, CI policies, or architecture details.
- Prefer links to existing docs and external or local skills.
- Include only links that exist or are explicitly cited as the source for
  commands or policy.
- Replace stale long-form sections with links when an authoritative doc exists.
- Avoid “always/never” rules unless critical for correctness/security.

---

### 6. Safety / Correctness Gates
- Never invent commands.
- Infer commands from:
  - package scripts
  - Makefile
  - CI configuration
  - README
- If uncertain → write:
  “Known commands: see <existing file>”
- Preserve critical warnings (security, secrets, deployment).

---

## Output Contract
Create or update only:

- `<repo_root>/AGENTS.md`
- `<module_dir>/AGENTS.md`

**Do not create agent configuration folders.**

---

## Skill Referencing Strategy

When adding skill references inside AGENTS.md:

1. **If local skill directory detected**
   ```
   See: <detected-skill-root>/<skill-name>/SKILL.md
   ```

2. **If no local directory exists**
   ```
   Skill: agents-md-generator (external)
   ```

Never assume filesystem paths.

---

## Validation

Before finishing, verify:

- Only root/module `AGENTS.md` files were created or updated.
- Final `AGENTS.md` files contain no unresolved `<...>` placeholders.
- Relative documentation links exist or clearly point to a source file for
  commands/policy.
- Commands are supported by package scripts, Makefile, CI configuration, or
  README. If no command is verified, use `Known commands: see <existing file>`.
- Line budgets are respected: root ≤ 60 lines, nested module ≤ 40 lines.
- Nested files exist only for confirmed module boundaries.
- Critical warnings from existing `AGENTS.md` files are preserved.
