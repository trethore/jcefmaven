# Repository Guidelines

## Project Structure & Module Organization

`jcefmaven/` hosts the only Maven module: production code sits in `src/main/java/me/tytoo/jcefmaven`, resources (such as
`jcefmaven_build_meta.json`) stay in `src/main/resources`, and tests should mirror those packages under `src/test/java`.
Shell helpers inside `scripts/` drive Docker and metadata edits, while `templates/` stores the proto-POMs for
platform-specific bundles. Anything inside `out/` or extracted from `libs/` is generated and stays untracked.

## Build, Test, and Development Commands

- `mvn -f jcefmaven/pom.xml clean verify` builds the jar, runs Surefire, and validates resources; add `-DskipTests` when
  iterating on well-covered code.
- `./generate_artifacts.sh <build_meta_url> <mvn_version>` clears `out/`, exports the environment variables, and invokes
  `docker compose -f docker-compose.yml up --build` to regenerate all native bundles.
- For focused refreshes (API only, natives only, etc.), call the relevant helper such as
  `bash scripts/generate_jcef_api.sh` and conclude with `bash scripts/organize_out.sh out`.

## Coding Style & Naming Conventions

Target Java 17, use four-space indentation, and keep braces on the same line as declarations (see `CefAppBuilder`).
Classes and enums are PascalCase (`EnumPlatform`), members are camelCase, and constants stay SCREAMING_SNAKE_CASE. Guard
inputs with `Objects.requireNonNull`, expose copies when returning lists or maps, keep new internal logic in the
existing impl hierarchy (`impl/step`, `impl/progress`, etc.), and leave resource keys kebab-case to match the template
JSON.

## Testing Guidelines

Surefire auto-discovers `*Test.java` and `*IT.java` under `jcefmaven/src/test/java`. Mock downloader/extractor
components (e.g., `PackageClasspathStreamer`, `TarGzExtractor`) to avoid network work, use temp directories when
asserting filesystem behavior, and run `mvn -f jcefmaven/pom.xml test` before pushing. Changes that affect installation
or platform detection need either a targeted unit test or a clearly documented manual scenario in the PR.

## Commit & Pull Request Guidelines

Commits use short, imperative summaries (`Refactor Docker user handling...`). Group script, template, and metadata edits
so reviewers can trace how a bundle was produced. Each PR must outline the motivation, the commands run, linked issues,
and any outputs (logs or screenshots) relevant to README or artifact changes. Call out required secrets or environment
variables so reviewers can reproduce the run.

## Security & Configuration Tips

Never commit `GITHUB_USERNAME`, `GITHUB_TOKEN`, `BUILD_META_URL`, or similar secrets; load them from your shell or CI
settings. Treat every `build_meta.json` change as release-critical and note the origin URL/tag inside the PR
description. Use the Docker Compose stack for artifact work whenever possible so downloads and unpacking stay consistent
across machines.
