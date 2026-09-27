# Exercise data attribution

The FitYaar exercise catalog (migration `V19__Import_Exercise_Library.sql`) is generated
from **free-exercise-db**:

- Source: https://github.com/yuhonas/free-exercise-db
- License: **The Unlicense** (public domain — free for any use, including commercial, no
  attribution required). Credit is given here as good practice.

`free-exercise-db.json` is the vendored snapshot used by `gen.mjs`. Muscle vocabulary,
equipment and category were mapped to FitYaar's enums, and `exercise_type` (how a set is
logged) was derived by rule since the source does not carry it. Regenerate with:

```
node tools/exercise-import/gen.mjs
```
