# Module packaging

```text
lua tools/package-module.lua path/to/module
```

The portable Lua packager performs conformance, runs the module test entry point,
checks required NUI production `dist`, copies allowed files into an isolated release
folder, creates a `.tar`, calculates SHA-256, and writes `release-manifest.json`.
Use `--output=path` to choose another release root. Existing destinations are never
overwritten.

Artifacts exclude `.env`, secret environment variants, `node_modules`, `.git`,
coverage, test-results, IDE metadata, logs, temporary files, nested build output,
and the top-level `data/` runtime-state directory. Static distributable data belongs
in an explicitly manifested module directory, not in `data/`.
An NUI artifact includes `web/dist`; dependency directories are excluded.

SHA-256 detects accidental or malicious byte changes after packaging. It is not a
digital signature and does not prove author identity, code safety, or trust. The
release manifest is distribution metadata, not runtime source of truth.
