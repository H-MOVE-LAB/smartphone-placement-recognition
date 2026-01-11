%% setup.m
% Project setup: add src/ to MATLAB path and define key directories.
% NOTE: setup.m must configure paths only (no computations).

PROJECT_ROOT = fileparts(mfilename('fullpath'));  % robust: path of setup.m itself
addpath(genpath(fullfile(PROJECT_ROOT, "src")));

DATA_DIR    = fullfile(PROJECT_ROOT, "data");
RESULTS_DIR = fullfile(PROJECT_ROOT, "results");
SCRIPTS_DIR = fullfile(PROJECT_ROOT, "scripts"); %#ok<NASGU>

if ~exist(DATA_DIR, "dir"),    mkdir(DATA_DIR);    end
if ~exist(RESULTS_DIR, "dir"), mkdir(RESULTS_DIR); end
