#!/bin/bash
# ============================================================================
# run_batch.sh — Wrapper for a single Monte Carlo simulation job
# ============================================================================
# Called by HTCondor via run_batch.sub. Each job gets a unique seed
# number passed as the first argument (0–49 from $(Process)).
#
# Usage:
#   ./must/run_batch.sh <seed>
#
# Output:
#   output/sim_<seed>.csv
# ============================================================================
set -euo pipefail

SEED="${1:?Usage: run_batch.sh <seed>}"

# Navigate to the project root (one level up from must/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "Starting simulation with seed ${SEED} ..."
echo "Working directory: $(pwd)"
echo "R_LIBS_USER: ${R_LIBS_USER:-not set}"

Rscript must/run_simulation.R "$SEED"

echo "Simulation seed ${SEED} complete."
