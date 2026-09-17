#!/bin/sh
# chai-09-tool's one job: greet. Whatever arguments arrive — from CMD's
# defaults or from `docker run` — land in $* and get printed.
echo "chai says: $*"
