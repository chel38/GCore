# Module metadata reference

`fxmanifest.lua` is the only required machine-readable module descriptor.
Contract v1 deliberately does not add a mandatory `module.json`.

| Key | Cardinality | Contract |
| --- | ---: | --- |
| `name` | 1 | Must equal the resource directory name. |
| `author` | 1 | Non-empty publisher/author label. |
| `description` | 1 | Non-empty factual description. |
| `version` | 1 | SemVer resource version. |
| `gcore_module` | 1 | Exactly `yes`. This is the discovery marker. |
| `gcore_contract` | 1 | Positive integer; v0.1 supports `1`. |
| `gcore_type` | 1 | One allowed Module Standard type. |
| `gcore_requires_core_api` | 1 | Positive minimum Core API version. |
| `gcore_api` | 0..1 | Positive public API version. Omit with no public API. |
| `gcore_capability` | 0..n | Lowercase catalog label, not a permission. |
| `gcore_requires` | 0..n | Required module/API dependency. |
| `gcore_optional` | 0..n | Optional module/API integration. |
| `gcore_repository` | 0..1 | Informational repository URL. |
| `gcore_license` | 0..1 | Informational SPDX-style identifier. |

Grammar:

```text
module-name  = lowercase letter/digit followed by lowercase letters, digits, _ or -
api-version  = positive decimal integer
dependency   = module-name ":api>=" api-version
capability   = lowercase letter/digit followed by lowercase letters, digits or -
```

Examples: `gc_identity:api>=1`, `vendor_weather:api>=2`.

Capabilities describe what a module advertises for documentation and diagnostics.
They never grant trust, permissions, ownership, or automatic security-sensitive
provider selection.
