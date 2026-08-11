# Справочник module metadata

`fxmanifest.lua` — единственный обязательный machine-readable descriptor модуля.
Contract v1 намеренно не вводит обязательный второй `module.json`.

| Поле | Количество | Контракт |
| --- | ---: | --- |
| `name` | 1 | Совпадает с именем папки resource. |
| `author` | 1 | Непустое имя автора/издателя. |
| `description` | 1 | Непустое фактическое описание. |
| `version` | 1 | SemVer resource version. |
| `gcore_module` | 1 | Ровно `yes`; это marker discovery. |
| `gcore_contract` | 1 | Положительное целое; v0.1 поддерживает `1`. |
| `gcore_type` | 1 | Разрешённый тип Module Standard. |
| `gcore_requires_core_api` | 1 | Минимальная положительная версия Core API. |
| `gcore_api` | 0..1 | Public API version; отсутствует без Public API. |
| `gcore_capability` | 0..n | Catalog label, не permission. |
| `gcore_requires` | 0..n | Обязательная module/API dependency. |
| `gcore_optional` | 0..n | Optional module/API integration. |
| `gcore_repository` | 0..1 | Информационный repository URL. |
| `gcore_license` | 0..1 | Информационный SPDX-style identifier. |

Grammar:

```text
module-name  = lowercase letter/digit + lowercase letters, digits, _ или -
api-version  = положительное десятичное целое
dependency   = module-name ":api>=" api-version
capability   = lowercase letter/digit + lowercase letters, digits или -
```

Примеры: `gc_identity:api>=1`, `vendor_weather:api>=2`.

Capabilities описывают модуль для docs и diagnostics. Они не дают trust,
permissions, ownership и не выбирают provider автоматически в security-sensitive flow.
