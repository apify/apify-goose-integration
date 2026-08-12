# CLAUDE.md

## Project Purpose

goose is a local, extensible, open source AI agent that automates engineering tasks. It runs on-machine, works with any LLM provider, integrates with MCP servers, and ships as both a CLI (`goose`) and an Electron desktop app backed by a Rust server (`goosed`).

This repository (`apify/apify-goose-integration`) is a fork of [`block/goose`](https://github.com/block/goose) used for Apify integration work. Upstream conventions and docs still apply; keep changes mergeable with upstream.

## Repository Structure

```
crates/
├── goose               # core logic: agents, providers, recipes, sessions, scheduler, security, MCP utils
├── goose-bench         # benchmarking harness
├── goose-cli           # CLI entry point (binary: goose)
├── goose-mcp           # built-in MCP extensions (developer, computercontroller, memory, tutorial, autovisualiser)
├── goose-server        # HTTP/WS backend for the desktop app (binary: goosed)
└── goose-test          # shared test utilities

temporal-service/       # Go service wrapping Temporal for scheduled recipes
ui/desktop/             # Electron + React + TypeScript desktop app
documentation/          # Docusaurus site (docs, blog)
scripts/                # clippy-lint.sh, check-openapi-schema.sh, benchmark helpers
recipe-scanner/         # recipe security scanning (Docker + shell)
bin/                    # hermit-managed toolchain shims (cargo, node, just, protoc, temporal)
Justfile                # task runner for all common workflows
```

Entry points:
- CLI: `crates/goose-cli/src/main.rs`
- Server: `crates/goose-server/src/main.rs`, routes in `crates/goose-server/src/routes/`
- Agent core: `crates/goose/src/agents/agent.rs`
- LLM providers: `crates/goose/src/providers/` (implement the `Provider` trait in `providers/base.rs`)
- Desktop main process: `ui/desktop/src/main.ts`
- OpenAPI generator: `crates/goose-server/src/bin/generate_schema.rs`

## Technology Stack

- **Rust** (toolchain pinned to 1.88.0 via `rust-toolchain.toml`, edition 2021, workspace version in root `Cargo.toml`). Key deps: `tokio`, `axum` 0.8, `rmcp` 0.7 (MCP), `reqwest`, `serde`, `utoipa` (OpenAPI), `sqlx` (SQLite), `anyhow`, `clap`/`cliclack` (CLI).
- **TypeScript / React 19 / Electron** with Vite, electron-forge, Tailwind, Radix UI; tests via Vitest and Playwright.
- **Go 1.23** for `temporal-service`.
- **Docusaurus** (yarn) for `documentation/`.
- **hermit** manages the local toolchain; **just** is the task runner.

## Build, Test & Run

```bash
source bin/activate-hermit        # activate pinned toolchain first

cargo build                       # debug build -> ./target/debug/goose
cargo build --release
just release-binary               # release build + copy binaries + regenerate OpenAPI

cargo test                        # all Rust tests
cargo test -p goose               # single crate
just record-mcp-tests             # re-record MCP integration replays

cargo fmt                         # required before committing
./scripts/clippy-lint.sh          # strict clippy + baseline rules (CI gate)

just run-ui                       # build release Rust + start desktop app
just run-server                   # cargo run -p goose-server --bin goosed agent (port 3000)
just debug-ui                     # UI against an externally-run server (for breakpoints)
just generate-openapi             # regenerate ui/desktop/openapi.json + TS client
just check-openapi-schema         # CI check that the schema is current
just run-docs                     # Docusaurus dev server
just install-deps                 # npm/yarn deps after a fresh clone

cd ui/desktop && npm run lint:check   # typecheck + eslint (CI gate)
cd ui/desktop && npm run test:run     # vitest
cd ui/desktop && npm run test-e2e     # playwright
```

Debugging the server requires `export GOOSE_SERVER__SECRET_KEY=test`; override the port with `GOOSE_PORT`. Provider selection can be overridden on the fly with `GOOSE_PROVIDER` plus the provider's key env var (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DATABRICKS_HOST`).

## Conventions

- **Commits/PRs**: PR titles follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). All commits require a DCO sign-off (`git commit --signoff`).
- **Branching**: feature branches off `main`; releases are cut on `release/<semver>` branches (`just prepare-release <version>`, `just tag-push`).
- **Layering**: implement non-trivial features in the `goose` crate, then call them from `goose-cli` for the CLI and expose them as `goose-server` routes for the desktop app.
- **Errors**: use `anyhow::Result` in application code.
- **Tests**: prefer a crate's `tests/` directory (e.g. `crates/goose/tests/`).
- **Dependencies**: add Rust deps with `cargo add`, not by hand-editing `Cargo.toml`.
- **Pre-commit**: husky runs `lint-staged` in `ui/desktop` when desktop TS files are staged.

## Key Notes for AI Assistants

- Always `source bin/activate-hermit` before running cargo/node/just so the pinned toolchain is used.
- Development loop: change code → `cargo fmt` → `cargo build` → `cargo test -p <crate>` → `./scripts/clippy-lint.sh` → `just generate-openapi` if the server API changed.
- **Never** edit `ui/desktop/openapi.json` or `ui/desktop/src/api/` by hand — they are generated. Change the Rust source under `crates/goose-server/src/` and run `just generate-openapi`.
- CI (`.github/workflows/ci.yml`) gates on `cargo fmt --check`, build + test, `./scripts/clippy-lint.sh`, an up-to-date OpenAPI schema, and `npm run lint:check` / `npm run test:run` in `ui/desktop`. Run these locally before pushing.
- MCP support comes from the external `rmcp` crate; there are no in-repo `mcp-client`/`mcp-core`/`mcp-server` crates. Built-in extensions live in `crates/goose-mcp/`.
- `AGENTS.md` and `.goosehints` hold overlapping agent guidance; keep them consistent with this file when workflows change.
- `.github/workflows/claude-md-maintenance.yml` is distributed centrally from `apify/integrations-team` and calls the reusable workflow in `apify/workflows` — do not edit it locally; it regenerates this file on pushes to `main`.
