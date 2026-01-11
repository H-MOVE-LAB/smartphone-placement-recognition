function metrics = computeModelMetrics(YPred, YTrue, modelName)
% evaluateModel_v3
% Evaluation function designed for automated analysis pipelines.
% Computes global, macro, micro and per-class metrics, enforces a fixed
% class order, and returns a numeric vector suitable for storage and
% statistical analysis.
%
% OUTPUT:
%   metrics = [global_metrics , per_class_metrics]
%
%   global_metrics = [accuracy, macroPrecision, macroRecall, microRecall]
%   per_class_metrics (per class, ordered) =
%       [balancedAccuracy, recall, precision]

    classes = unique(YTrue);
    confMat = confusionmat(YTrue, YPred);
    numClasses = numel(classes);

    % --- Global (micro) accuracy ---
    accuracy = sum(diag(confMat)) / sum(confMat(:));

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

    % --- Macro and micro metrics ---
    macroPrecision = mean(precision);
    macroRecall    = mean(recall);
    microRecall    = sum(diag(confMat)) / sum(sum(confMat, 2));

    % --- Logging ---
    fprintf('\n=== MODEL: %s ===\n', modelName);
    fprintf('Accuracy        : %.4f\n', accuracy);
    fprintf('Macro Precision : %.4f\n', macroPrecision);
    fprintf('Macro Recall    : %.4f\n', macroRecall);
    fprintf('Micro Recall    : %.4f\n\n', microRecall);

    fprintf('--- Per-class metrics ---\n');
    for i = 1:numClasses
        fprintf('Class: %-12s | BA: %.3f | Precision: %.3f | Recall: %.3f\n', ...
            string(classes(i)), balancedAccuracy(i), precision(i), recall(i));
    end

    % --- Confusion matrix ---
    figure;
    cm = confusionchart(YTrue, YPred);
    cm.Title = ['Confusion Matrix - ', modelName];
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';

    % --- Fixed class ordering (critical for comparisons) ---
    desiredOrder = ["LB","H","SB","CP","BP","FP","TP","P"];
    classStr = string(classes);

    [~, idx] = ismember(classStr, desiredOrder);
    [~, sortIdx] = sort(idx);

    balancedAccuracy = balancedAccuracy(sortIdx);
    recall           = recall(sortIdx);
    precision        = precision(sortIdx);

    % --- Output vector ---
    metrics_global = [accuracy, macroPrecision, macroRecall, microRecall];
    metrics_per_class = [ ...
        balancedAccuracy', ...
        recall', ...
        precision' ];

    metrics = [metrics_global, metrics_per_class];
end
