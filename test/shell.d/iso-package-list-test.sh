#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

other_packages="$ROOT/install/omarchy-other.packages"

if grep -Fxq 'broadcom-wl' "$other_packages"; then
  fail "ISO package lists do not request the unavailable broadcom-wl target"
fi

pass "ISO package lists do not request the unavailable broadcom-wl target"
