#!/bin/bash
# ============================================================================
# setup_r.sh — One-time R environment setup for MUST cluster
# ============================================================================
# Run this script ONCE on a MUST UI server (lappui7, lappui9, or lappusmb7)
# to install R packages on shared storage so worker nodes can use them.
#
# Usage:
#   bash must/setup_r.sh
# ============================================================================
set -euo pipefail

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║        VeggieFuel — MUST Cluster R Environment Setup            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Check if R is available ─────────────────────────────────────────

if ! command -v R &> /dev/null; then
  echo "ERROR: R is not in your PATH."
  echo ""
  echo "Try one of these options:"
  echo ""
  echo "  Option A — CVMFS (available on all MUST nodes):"
  echo "    source /cvmfs/sft.cern.ch/lcg/views/LCG_105/x86_64-el9-gcc12-opt/setup.sh"
  echo ""
  echo "  Option B — Conda (if you have conda installed):"
  echo "    conda create -n veggiefuel r-base r-essentials -c conda-forge"
  echo "    conda activate veggiefuel"
  echo ""
  echo "After setting up R, re-run this script:"
  echo "    bash must/setup_r.sh"
  exit 1
fi

R_VERSION=$(R --version | head -1 | grep -oP '\d+\.\d+' | head -1)
echo "Found R version: ${R_VERSION}"

# ── Step 2: Detect LAPP vs USMB ────────────────────────────────────────────

HOSTNAME=$(hostname -f)

if echo "$HOSTNAME" | grep -qi "lapp"; then
  STORAGE_BASE="/lapp_data"
  SITE="LAPP"
  echo "Detected site: LAPP (hostname: ${HOSTNAME})"
elif echo "$HOSTNAME" | grep -qi "usmb"; then
  STORAGE_BASE="/uds_data"
  SITE="USMB"
  echo "Detected site: USMB (hostname: ${HOSTNAME})"
else
  echo "WARNING: Could not auto-detect site from hostname: ${HOSTNAME}"
  echo "Please choose your site:"
  echo "  1) LAPP  — storage at /lapp_data/<group>/"
  echo "  2) USMB  — storage at /uds_data/<lab>/"
  read -rp "Enter 1 or 2: " SITE_CHOICE
  case "$SITE_CHOICE" in
    1) STORAGE_BASE="/lapp_data"; SITE="LAPP" ;;
    2) STORAGE_BASE="/uds_data";  SITE="USMB" ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
  esac
fi

# ── Step 3: Ask for group/lab name ──────────────────────────────────────────

echo ""
if [ "$SITE" = "LAPP" ]; then
  read -rp "Your LAPP group name (e.g. atlas, lapp_phys, lapth): " GROUP_NAME
else
  read -rp "Your USMB lab name (e.g. listic, locie, symme): " GROUP_NAME
fi

if [ -z "$GROUP_NAME" ]; then
  echo "ERROR: Group/lab name cannot be empty."
  exit 1
fi

# ── Step 4: Create R library on shared storage ──────────────────────────────

R_LIB_PATH="${STORAGE_BASE}/${GROUP_NAME}/R_libs/${R_VERSION}"

echo ""
echo "Creating R library directory:"
echo "  ${R_LIB_PATH}"

mkdir -p "$R_LIB_PATH"

# ── Step 5: Add R_LIBS_USER to ~/.bashrc ────────────────────────────────────

EXPORT_LINE="export R_LIBS_USER=\"${R_LIB_PATH}\""

if grep -qF "R_LIBS_USER" ~/.bashrc 2>/dev/null; then
  echo ""
  echo "NOTE: R_LIBS_USER is already set in your ~/.bashrc"
  echo "Current line:"
  grep "R_LIBS_USER" ~/.bashrc
  echo ""
  echo "If you want to update it, edit ~/.bashrc manually."
else
  echo "" >> ~/.bashrc
  echo "# VeggieFuel: R library on shared storage (added by must/setup_r.sh)" >> ~/.bashrc
  echo "${EXPORT_LINE}" >> ~/.bashrc
  echo ""
  echo "Added to ~/.bashrc:"
  echo "  ${EXPORT_LINE}"
fi

# Set for the current session
export R_LIBS_USER="${R_LIB_PATH}"

# ── Step 6: Install R packages ──────────────────────────────────────────────

echo ""
echo "Installing R packages to ${R_LIB_PATH} ..."
echo "This may take a few minutes on the first run."
echo ""

# Use the project's own setup script to install everything
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"
Rscript R/00_setup.R

# ── Done! ───────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════════════════════════"
echo "  Setup complete!"
echo ""
echo "  R library path:  ${R_LIB_PATH}"
echo "  Site:            ${SITE}"
echo "  Group/Lab:       ${GROUP_NAME}"
echo ""
echo "  Next steps:"
echo "    1. Test locally:   Rscript tests/test_amino.R"
echo "    2. Submit a job:   condor_submit must/run_single.sub"
echo "══════════════════════════════════════════════════════════════════"
