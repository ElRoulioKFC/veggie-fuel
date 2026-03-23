#!/bin/bash
# ============================================================================
# collect_results.sh — Wrapper to run collect_results.R on HTCondor
# ============================================================================
# Used by DAGMan as the CHILD job after all simulations finish.
#
# Usage:
#   ./must/collect_results.sh
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "Collecting simulation results ..."
echo "Working directory: $(pwd)"

Rscript must/collect_results.R

echo "Collection complete."
