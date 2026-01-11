%% RunAnalysis.m
% Example analysis entry point.
% - Locates project root (robust to MATLAB current folder)
% - Runs setup.m (paths + folders)
% - Loads latest pipeline output from results/
% - Computes demo metrics
% - Saves a CSV + figure under results/

clear; clc; close all;

% --- Minimal bootstrap: locate project root and run setup.m
thisFile    = mfilename("fullpath");
projectRoot = fileparts(fileparts(thisFile)); % scripts -> project root
addpath(projectRoot);
run(fullfile(projectRoot, "setup.m"));

% -------------------------
% Find latest pipeline output
% -------------------------
files = dir(fullfile(RESULTS_DIR, "pipeline_output_*.mat"));
assert(~isempty(files), "No pipeline outputs found. Run scripts/RunPipeline.m first.");

[~, idx] = max([files.datenum]);
latestPath = fullfile(files(idx).folder, files(idx).name);

S = load(latestPath, "out", "cfg");
out = S.out;

% -------------------------
% Compute demo metrics
% -------------------------
err  = out.y - out.x;
rmse = sqrt(mean(err.^2));
mae  = mean(abs(err));

T = table(rmse, mae);

% -------------------------
% Save metrics
% -------------------------
runTag  = string(datetime("now","Format","yyyyMMdd_HHmmss"));
csvPath = fullfile(RESULTS_DIR, "metrics_" + runTag + ".csv");
writetable(T, csvPath);
fprintf("[Analysis] Metrics saved: %s\n", csvPath);

% -------------------------
% Save figure
% -------------------------
figPath = fullfile(RESULTS_DIR, "error_" + runTag + ".png");
figure("Name","Analysis error");
plot(out.time, err, "LineWidth", 1.5);
grid on;
xlabel("Time (s)");
ylabel("Error (y - x)");
yline(0, '--');
exportgraphics(gcf, figPath, "Resolution", 300);
fprintf("[Analysis] Figure saved: %s\n", figPath);
