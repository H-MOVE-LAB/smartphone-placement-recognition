function newLabels = reduceLabels(oldLabels, numClasses)
    oldLabels = string(oldLabels);
    newLabels = oldLabels;

    switch numClasses
        case 5
            % Unisce 'FP' e 'BP' → 'TP'
            newLabels(ismember(oldLabels, {'FP', 'BP'})) = 'TP';
        case 4
            % Nuova mappatura:
            % 'BP', 'FP', 'CP' → 'P' (tasche)
            % 'H', 'LB', 'SB' restano invariate
            newLabels(ismember(oldLabels, {'BP', 'FP', 'CP'})) = 'P';
        otherwise
            error('Supporto solo per 5 o 4 classi.');
    end

    newLabels = categorical(newLabels);
end
