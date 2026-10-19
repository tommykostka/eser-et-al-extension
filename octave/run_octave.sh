#!/bin/bash
# Runs MATLAB code in GNU Octave from the repository root, e.g.
#   ./run_octave.sh "spread_run_batch('E', 1, 1)"
# Needs Octave >= 8 with the optim, statistics, io and financial packages.
# octave_compat/ supplies MATLAB behaviour Octave lacks (mvregress, xlsread date
# columns, fmincon with fixed bounds, optimizer iteration limits);
# octave_noplot/ turns plotting into no-ops on machines without a display.
cd "$(dirname "$0")"
octave-cli -q --no-gui --eval "pkg load optim statistics io financial; addpath(fullfile(pwd, 'octave_compat')); addpath(fullfile(pwd, 'octave_noplot')); warning('off','all'); more off; save_default_options('-v7'); $1" 2>&1 \
  | grep -vE "JAVA_TOOL_OPTIONS|shadows a (core|built-in)|called from|PKG_ADD|load_packages|pkg at line"
