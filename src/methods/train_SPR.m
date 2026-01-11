%% Smartphone Placement Recognition – Ensemble Training Script
% This script trains and evaluates an ensemble classifier for smartphone
% placement recognition during gait using subject-independent splits.
%
% Author: Paolo Tasca
% -------------------------------------------------------------------------

clear; close all; clc;
addpath(fullfile("..","utils"))
%% -------------------- Configuration -------------------------------------
numSubjectsCS = 10;          % Number of subjects in Construction Set
rng(42);                     % Reproducibility

resultsDir = fullfile('..','..','results','models');
dataFile   = fullfile('..','..','data','customFreeLiving.mat');

N_features_list = [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 154];
row_indices     = 6:21;      % Excel row indices for performance logging

%% -------------------- Load dataset --------------------------------------
load(dataFile);              % Loads table: finalTable
data = finalTable;

%% -------------------- Data cleaning -------------------------------------
% Remove low-motion windows (likely non-walking)
data = data(data.MeanGyr >= 10, :);

features   = data{:,1:end-2};    % Feature matrix
labels     = data.Position;      % Placement labels
subjectIDs = data.SubjectID;     % Subject identifiers

featureNames = data.Properties.VariableNames(1:size(features,2));

%% -------------------- Subject-independent split -------------------------
uniqueSubjects = unique(subjectIDs);
permSubjects   = uniqueSubjects(randperm(numel(uniqueSubjects)));

CS_subjects = permSubjects(1:numSubjectsCS);
TS_subjects = permSubjects(numSubjectsCS+1:end);

idxCS = ismember(subjectIDs, CS_subjects);
idxTS = ismember(subjectIDs, TS_subjects);

X_CS = features(idxCS,:);
Y_CS = labels(idxCS);

X_TS = features(idxTS,:);
Y_TS = labels(idxTS);

%% -------------------- Feature selection (MRMR) ---------------------------
fprintf('\nRunning MRMR feature selection...\n');
[featIdx, featScores] = fscmrmr(X_CS, Y_CS);

% Display top 10 features
fprintf('\nTop 10 MRMR-ranked features:\n');
for i = 1:10
    fprintf('%2d. %-30s  Score: %.4f\n', ...
        i, featureNames{featIdx(i)}, featScores(featIdx(i)));
end

%% -------------------- Loop over feature set sizes ------------------------
for ii = 1:numel(N_features_list)

    N      = N_features_list(ii);
    rowID = row_indices(ii);

    fprintf('\n=== Training with top %d features ===\n', N);

    selectedIdx      = featIdx(1:N);
    selectedFeatures = featureNames(selectedIdx);

    Xtrain = X_CS(:,selectedIdx);
    Ytrain = Y_CS;

    Xtest  = X_TS(:,selectedIdx);
    Ytest  = Y_TS;

    %% -------------------- Save feature selection -------------------------
    outDir = fullfile(resultsDir, sprintf('best%d_features',N));
    if ~exist(outDir, 'dir'); mkdir(outDir); end

    save(fullfile(outDir,'FeatSel_Results.mat'), ...
        'selectedFeatures','selectedIdx','featIdx','featScores','N');

    %% -------------------- Train ensemble model --------------------------
    fprintf('Training ensemble classifier (AdaBoost)...\n');
    rng(1);

    ensModel = fitcensemble( ...
        Xtrain, Ytrain, ...
        'Method','AdaBoostM2', ...
        'OptimizeHyperparameters',{'NumLearningCycles','LearnRate','MaxNumSplits'}, ...
        'HyperparameterOptimizationOptions',struct( ...
            'Optimizer','bayesopt', ...
            'MaxObjectiveEvaluations',50, ...
            'AcquisitionFunctionName','expected-improvement-plus', ...
            'ShowPlots',true, ...
            'Verbose',1));

    %% -------------------- Evaluation: 6 classes --------------------------
    Ypred = predict(ensModel, Xtest);

    fprintf('\n--- 6-class evaluation ---\n');
    metrics6 = computeModelMetrics(Ypred, Ytest, 'Ensemble (6 classes)');

    %% -------------------- Save model and figures -------------------------
    save(fullfile(outDir,'ensModel.mat'),'ensModel');

    f1 = figure(1);
    saveas(f1, fullfile(outDir,'ConfusionMatrix.fig'));

    %% -------------------- Reduced class problems -------------------------
    Ytest5 = reduceLabels(Ytest, 5);
    Ypred5 = reduceLabels(Ypred, 5);

    Ytest4 = reduceLabels(Ytest, 4);
    Ypred4 = reduceLabels(Ypred, 4);

    fprintf('\n--- 5-class evaluation ---\n');
    metrics5 = computeModelMetrics(Ypred5, Ytest5, 'Ensemble (5 classes)');

    fprintf('\n--- 4-class evaluation ---\n');
    metrics4 = computeModelMetrics(Ypred4, Ytest4, 'Ensemble (4 classes)');

    %% -------------------- Save performance metrics -----------------------
    perfFile = fullfile('..', 'results', 'models', 'performance_FS.xlsx');

    writematrix(metrics6, perfFile, 'Sheet','ENS_6classes', ...
        'Range',sprintf('F%d',rowID));

    writematrix(metrics5, perfFile, 'Sheet','ENS_5classes', ...
        'Range',sprintf('F%d',rowID));

    writematrix(metrics4, perfFile, 'Sheet','ENS_4classes', ...
        'Range',sprintf('F%d',rowID));

end

fprintf('\nTraining and evaluation completed successfully.\n');
