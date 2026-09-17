# Challenge

Speak fluent exit code. Make a container **die with exit code 7** — on purpose.

Run a container named **`chai-02-crash`** from the `alpine` image whose command exits with status `7`, and leave the corpse in place for the verifier to autopsy.

Then read its cause of death yourself two ways: in the `STATUS` column of `docker ps -a`, and precisely via `docker inspect` (the exit code lives at `.State.ExitCode`).

**You pass when:** `chai-02-crash` exists, was created from `alpine`, is exited, and its exit code is exactly `7`.

*Hint direction: a shell can end itself with any code it likes.*
