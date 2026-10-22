#!/bin/bash
# Runs MATLAB code in GNU Octave from the repository root, e.g.
#   octave/run_octave.sh "baseline_PEPP"   or   octave/run_octave.sh "spread_run_batch('GQ', 1, 1)"
# Optional: the code is written for MATLAB; this runs it in Octave instead.
# Needs Octave >= 8 with the optim, statistics, io and financial packages.
# octave/compat/ supplies MATLAB behaviour Octave lacks (mvregress, xlsread date
# columns, fmincon with fixed bounds, optimizer iteration limits);
# octave/noplot/ turns plotting into no-ops on machines without a display
# (charts are then only written as CSV; draw them in MATLAB or with octave/charts/).
cd "$(dirname "$0")/.."
octave-cli -q --no-gui --eval "pkg load optim statistics io financial; addpath(fullfile(pwd, 'octave', 'compat')); addpath(fullfile(pwd, 'octave', 'noplot')); addpath(fullfile(pwd, 'model')); warning('off','all'); more off; save_default_options('-v7'); $1" 2>&1 \
  | grep -vE "JAVA_TOOL_OPTIONS|shadows a (core|built-in)|called from|PKG_ADD|load_packages|pkg at line"
