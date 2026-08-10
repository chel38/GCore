# Runtime identity data

`identities.json` is legacy migration input from `gc_identity 0.1.x`. Production
storage is MariaDB through oxmysql; this directory is never a runtime fallback.
The file contains private identifiers, must not be served or committed, and is
ignored by the repository root `.gitignore`. Back it up before the first import.
