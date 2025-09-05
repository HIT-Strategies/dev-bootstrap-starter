#!/usr/bin/env bash
set -euo pipefail

# Execute the common personal configuration script with macOS platform prefix
bash "$(dirname "$0")/common.sh" "macOS Personal"