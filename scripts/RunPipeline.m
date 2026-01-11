%% RunPipeline.m
% Example reproducible pipeline entry point.
% - Locates project root (robust to MATLAB current folder)
% - Runs setup.m (paths + folders)
% - Generates synthetic demo data
% - Runs a core method (src/)
% - Saves outputs + configuration under results/

clear; clc; close all;

% --- Minimal bootstrap: locate project root and run setup.m
thisFile    = mfilename("fullpath");
projectRoot = fileparts(fileparts(thisFile)); % scripts -> project root
addpath(projectRoot);
run(fullfile(projectRoot, "setup.m"));

% -------------------------
% Configuration (save this)
% -------------------------
cfg = struct();
cfg.runDateTime = string(datetime("now"));
cfg.fs          = 100;   % Hz
cfg.cutoffHz    = 5;     % demo parameter
cfg.seed        = 42;    % reproducibility

rng(cfg.seed);

% -------------------------
% Generate demo data
% -------------------------
t = (0:1/cfg.fs:10)';
x = sin(2*pi*1*t) + 0.1*randn(size(t));

% -------------------------
% Run method (lives in src/)
% -------------------------
y = exampleMethod(x, cfg.fs, cfg.cutoffHz);

% -------------------------
% Save outputs
% -------------------------
out = struct();
out.time = t;
out.x    = x;
out.y    = y;

runTag  = string(datetime("now","Format","yyyyMMdd_HHmmss"));
outFile = fullfile(RESULTS_DIR, "pipeline_output_" + runTag + ".mat");
save(outFile, "out", "cfg", "-v7.3");

fprintf("[Pipeline] Saved: %s\n", outFile);

% -------------------------
% Quick plot (optional)
% -------------------------
figure("Name","Pipeline output");
plot(t, x, "LineWidth", 1.5); hold on;
plot(t, y, "LineWidth", 1.5);
grid on;
xlabel("Time (s)");
ylabel("Signal");
legend("Input x", "Processed y");
