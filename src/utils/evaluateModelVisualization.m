function evaluateModelVisualization(YPred, YTrue, modelName)
% evaluateModel_v2
% Quick evaluation function for visual inspection.
% Computes global and per-class metrics, prints results to the command
% window, and generates confusion matrix and summary bar plots.
%
% INPUTS:
%   YPred     - Predicted labels (categorical)
%   YTrue     - Ground-truth labels (categorical)
%   modelName - String with model name (for titles/logs)

    classes = unique(YTrue);
    confMat = confusionmat(YTrue, YPred);
    numClasses = numel(classes);

    % --- Global (micro) accuracy ---
    globalAccuracy = sum(diag(confMat)) / sum(confMat(:));

    % --- Per-class metrics ---
    precision = zeros(numClasses,1);
    recall    = zeros(numClasses,1);
    specificity = zeros(numClasses,1);
    balancedAccuracy = zeros(numClasses,1);

    for i = 1:numClasses
        TP = confMat(i,i);
        FP = sum(confMat(:,i)) - TP;
        FN = sum(confMat(i,:)) - TP;
        TN = sum(confMat(:)) - TP - FP - FN;

        precision(i) = TP / (TP + FP + eps);
        recall(i)    = TP / (TP + FN + eps);
        specificity(i) = TN / (TN + FP + eps);
        balancedAccuracy(i) = (recall(i) + specificity(i)) / 2;
    end

    % --- Macro metrics ---
    macroPrecision = mean(precision);
    macroRecall    = mean(recall);

    % --- Command window output ---
    fprintf('\n=== MODEL: %s ===\n', modelName);
    fprintf('Global Accuracy : %.4f\n', globalAccuracy);
    fprintf('Macro Precision : %.4f\n', macroPrecision);
    fprintf('Macro Recall    : %.4f\n', macroRecall);

    fprintf('--- Per-class metrics ---\n');
    for i = 1:numClasses
        fprintf('Class: %-12s | Precision: %.3f | Recall: %.3f\n', ...
            string(classes(i)), precision(i), recall(i));
    end

    % --- Confusion matrix ---
    figure;
    cm = confusionchart(YTrue, YPred);
    cm.Title = ['Confusion Matrix - ', modelName];
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';

    % --- Summary bar plot ---
    figure;
    bar([globalAccuracy; macroPrecision; macroRecall]);
    set(gca, 'XTickLabel', {'Accuracy', 'Macro Precision', 'Macro Recall'});
    ylabel('Score');
    title(['Performance Summary - ', modelName]);
    grid on;
end
