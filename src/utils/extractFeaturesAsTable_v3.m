function featureTable = extractFeaturesAsTable_v3(windows, windowLength)
% Extracts advanced time, frequency, and wavelet domain features from
% reshaped windowed data and returns them as a table.

numWindows = size(windows, 1);
fs = 100; % Sampling frequency

% entropy parameters
m = 2;
r_factor = 0.2;

% Preallocate arrays
features_ = []; % Will be filled row by row

for i = 1:numWindows
    % Reshape window to [windowLength x 6]
    window = reshape(windows(i, :), [6, windowLength])';
    acc = window(:, 1:3);
    gyr = window(:, 4:6);

    accNorm = sqrt(sum(acc.^2, 2));
    gyrNorm = sqrt(sum(gyr.^2, 2));

    %% --- TIME DOMAIN FEATURES --- %%
    % Statistical
    f = @(x)[iqr(x), mean(x), var(x), skewness(x), kurtosis(x), rms(x), sum(abs(x))/length(x), max(x), range(x)];
    statAcc = f(accNorm);
    statGyr = f(gyrNorm);
    
    % Jerk
    jerk_rms = @(a) sqrt(mean(diff(a).^2)); % jerk da derivata discreta
    jerkRMS   = jerk_rms(accNorm);


    % MCR: count number of sign changes in (signal > median)
    mcrAcc = sum(diff(accNorm > median(accNorm)) ~= 0) / windowLength;
    mcrGyr = sum(diff(gyrNorm > median(gyrNorm)) ~= 0) / windowLength;

    % Teager Energy Operator
    teo = @(x) x(2:end-1).^2 - x(1:end-2).*x(3:end);
    TEAcc = teo(accNorm);
    TEGyr = teo(gyrNorm);
    teFeaturesAcc = [mean(TEAcc), var(TEAcc), numel(findpeaks(TEAcc, 'MinPeakProminence',2.5))];
    teFeaturesGyr = [mean(TEGyr), var(TEGyr), numel(findpeaks(TEGyr, 'MinPeakProminence',2.5))];

    % Entropy (Approximate, Sample) - placeholder functions
    apEn = @(x) approximateEntropy(x, m, r_factor * std(x));
    multEn = @(x) multiscaleEntropy(x, m, r_factor * std(x));

    multentropyAcc = multEn(accNorm);
    multentropyGyr = multEn(gyrNorm);

    entropyAcc = [multentropyAcc, sum(multentropyAcc)];
    entropyGyr = [multentropyGyr, sum(multentropyGyr)];

    % Autocorrelation Coefficients (lags 1-10)
    [acfAcc, lagsAcc] = xcorr(accNorm, 10);
    [acfGyr, lagsGyr] = xcorr(gyrNorm, 10);
    acfAcc = acfAcc(lagsAcc>0)'; 
    acfGyr = acfGyr(lagsGyr>0)';
    % Number of Peaks
    numPeaks = [numel(findpeaks(accNorm, 'MinPeakProminence',2.5)), numel(findpeaks(gyrNorm, 'MinPeakProminence',2.5))];

    %% --- FREQUENCY DOMAIN FEATURES --- %%
    nfft = length(accNorm);
    faxis = (0:nfft-1) * (fs / nfft);

    % FFT and remove DC
    accFFT_full = abs(fft(accNorm - mean(accNorm)));
    gyrFFT_full = abs(fft(gyrNorm - mean(gyrNorm)));

    % Keep only positive frequencies (one-sided spectrum)
    half_n = floor(nfft/2) + 1;
    accFFT = accFFT_full(1:half_n);
    gyrFFT = gyrFFT_full(1:half_n);
    faxis = faxis(1:half_n);

    % Normalize
    accFFT = accFFT / sum(accFFT);
    gyrFFT = gyrFFT / sum(gyrFFT);

    % Dominant frequencies (excluding DC)
    [~, idx1] = max(accFFT(2:end));
    idx1 = idx1 + 1;
    accFFT(idx1) = 0; % remove first peak
    [~, idx2] = max(accFFT(2:end));
    idx2 = idx2 + 1;
    domFreqAcc = faxis([idx1, idx2]);

    [~, idy1] = max(gyrFFT(2:end));
    idy1 = idy1 + 1;
    gyrFFT(idy1) = 0;
    [~, idy2] = max(gyrFFT(2:end));
    idy2 = idy2 + 1;
    domFreqGyr = faxis([idy1, idy2]);

    % Mean/Median Frequency
    mf = @(X) sum(faxis' .* X) / sum(X);
    medianFreq = @(X) faxis(find(cumsum(X) > 0.5, 1));

    freqStatsAcc = [mf(accFFT), medianFreq(accFFT), abs(diff(domFreqAcc))];
    freqStatsGyr = [mf(gyrFFT), medianFreq(gyrFFT), abs(diff(domFreqGyr))];

    % Spectral entropy
    specEnt = @(X) -sum(X .* log(X + eps));
    specEntropyAcc = specEnt(accFFT);
    specEntropyGyr = specEnt(gyrFFT);

    % Dominant power
    domPowerAcc = max(accFFT);
    domPowerGyr = max(gyrFFT);


    %% --- CWT FEATURES --- %%
    % Sampling frequency
    fs = 100;

    % Continuous Wavelet Transform (CWT)
    [cfsAcc, freqAcc] = cwt(accNorm, 'amor', fs);  % accNorm: modulo dell'accelerazione
    [cfsGyr, freqGyr] = cwt(gyrNorm, 'amor', fs);  % gyrNorm: modulo della velocità angolare

    % Potenza istantanea delle CWT
    powerAccCWT = abs(cfsAcc).^2;
    powerGyrCWT = abs(cfsGyr).^2;

    % Bande di frequenza [Hz] (come nel codice originale)
    freqBands = [0.5 1; 1 2; 2 3; 3 5; 5 8; 8 12; 12 18; 18 25];
    numBands = size(freqBands, 1);

    % Preallocazione feature per ogni banda
    energyCwtAcc = zeros(1, numBands);
    meanCwtAcc   = zeros(1, numBands);
    stdCwtAcc    = zeros(1, numBands);
    entropyCwtAcc = zeros(1, numBands);

    energyCwtGyr = zeros(1, numBands);
    meanCwtGyr   = zeros(1, numBands);
    stdCwtGyr    = zeros(1, numBands);
    entropyCwtGyr = zeros(1, numBands);

    % Funzione entropia spettrale
    specEnt = @(P) -sum(P .* log(P + eps));
    
    % Simmetry
    harmRatioAcc = harmonic_ratio(accNorm, fs); 
    harmRatioGyr = harmonic_ratio(gyrNorm, fs);

    for b = 1:numBands
        % Trova gli indici delle scale CWT che corrispondono alla banda b
        idxAcc = find(freqAcc >= freqBands(b,1) & freqAcc < freqBands(b,2));
        idxGyr = find(freqGyr >= freqBands(b,1) & freqGyr < freqBands(b,2));

        % Seleziona solo le scale della banda
        bandPowerAcc = powerAccCWT(idxAcc, :);
        bandPowerGyr = powerGyrCWT(idxGyr, :);

        % ACCELEROMETRO
        energyCwtAcc(b) = sum(bandPowerAcc(:));
        meanCwtAcc(b)   = mean(bandPowerAcc(:));
        stdCwtAcc(b)    = std(bandPowerAcc(:));
        pNormAcc = bandPowerAcc(:) / sum(bandPowerAcc(:));
        entropyCwtAcc(b) = specEnt(pNormAcc);

        % GYRO
        energyCwtGyr(b) = sum(bandPowerGyr(:));
        meanCwtGyr(b)   = mean(bandPowerGyr(:));
        stdCwtGyr(b)    = std(bandPowerGyr(:));
        pNormGyr = bandPowerGyr(:) / sum(bandPowerGyr(:));
        entropyCwtGyr(b) = specEnt(pNormGyr);
    end
    cwtBandFeatures = [energyCwtAcc, meanCwtAcc, stdCwtAcc, entropyCwtAcc, ...
                       energyCwtGyr, meanCwtGyr, stdCwtGyr, entropyCwtGyr];
    %% --- CROSS CORRELATION FEATURES --- %%
    corrAcc = corr(acc);
    corrGyr = corr(gyr);
    accCorrs = [corrAcc(1,2), corrAcc(1,3), corrAcc(2,3)];
    gyrCorrs = [corrGyr(1,2), corrGyr(1,3), corrGyr(2,3)];

    %% --- ACC-GYR CROSS FEATURES --- %%
    gyroAccCorr = corr(accNorm, gyrNorm);
    gyroAccMax = max(accNorm) * max(gyrNorm);
    gyroAccStdProd = std(accNorm) * std(gyrNorm);

    %% --- COMBINE --- %%
    allFeatures = [statAcc, statGyr, jerkRMS, mcrAcc, mcrGyr, teFeaturesAcc, teFeaturesGyr, ...
        entropyAcc, entropyGyr, ...
        acfAcc, acfGyr, numPeaks, domFreqAcc, domFreqGyr, ...
        freqStatsAcc, freqStatsGyr, specEntropyAcc, specEntropyGyr, ...
        domPowerAcc, domPowerGyr, harmRatioAcc, harmRatioGyr, ...
        accCorrs, gyrCorrs, gyroAccCorr, gyroAccMax, gyroAccStdProd, ...
        cwtBandFeatures];

    features_ = [features_; allFeatures];
end
% Bande CWT
cwtBandNames = {};
bands = 1:8;
for i = bands
    cwtBandNames = [cwtBandNames, ...
        sprintf('CWT_Eng_Acc_B%d', i), sprintf('CWT_Mean_Acc_B%d', i), ...
        sprintf('CWT_Std_Acc_B%d', i), sprintf('CWT_Entropy_Acc_B%d', i), ...
        sprintf('CWT_Eng_Gyr_B%d', i), sprintf('CWT_Mean_Gyr_B%d', i), ...
        sprintf('CWT_Std_Gyr_B%d', i), sprintf('CWT_Entropy_Gyr_B%d', i)];
end

% Column names
varNames = [{'IQRAcc', 'MeanAcc', 'VarAcc', 'SkewAcc', 'KurtAcc', 'RMSAcc', 'SMAAcc', 'MaxAcc','RangeAcc',...
            'IQRGyr', 'MeanGyr', 'VarGyr', 'SkewGyr', 'KurtGyr', 'RMSGyr', 'SMAGyr', 'MaxGyr','RangeGyr', ...
            'JerkRMS', 'MedCrossRateAcc', 'MedCrossRateGyr',...
            'TEO_Mean_Acc', 'TEO_Var_Acc', 'TEO_Peaks_Acc', 'TEO_Mean_Gyr', 'TEO_Var_Gyr', 'TEO_Peaks_Gyr', ...
            'En1_Acc', 'En2_Acc', 'En3_Acc', 'En4_Acc', 'En5_Acc', 'En6_Acc', 'En7_Acc', 'En8_Acc', 'En9_Acc', 'En10_Acc', 'EnSum_Acc', ...
            'En1_Gyr', 'En2_Gyr', 'En3_Gyr', 'En4_Gyr', 'En5_Gyr', 'En6_Gyr', 'En7_Gyr', 'En8_Gyr', 'En9_Gyr', 'En10_Gyr', 'EnSum_Gyr', ...
            'ACF1_Acc', 'ACF2_Acc', 'ACF3_Acc', 'ACF4_Acc', 'ACF5_Acc', 'ACF6_Acc', 'ACF7_Acc', 'ACF8_Acc', 'ACF9_Acc', 'ACF10_Acc', ...
            'ACF1_Gyr', 'ACF2_Gyr', 'ACF3_Gyr', 'ACF4_Gyr', 'ACF5_Gyr', 'ACF6_Gyr', 'ACF7_Gyr', 'ACF8_Gyr', 'ACF9_Gyr', 'ACF10_Gyr', ...
            'NumPeaksAcc', 'NumPeaksGyr', ...
            'DomFreq1Acc', 'DomFreq2Acc', 'DomFreq1Gyr', 'DomFreq2Gyr', ...
            'MeanFreqAcc', 'MedianFreqAcc', 'F0F1DistAcc', 'MeanFreqGyr', 'MedianFreqGyr', 'F0F1DistGyr',...
            'SpecEntropyAcc', 'SpecEntropyGyr', 'DomPowerAcc', 'DomPowerGyr', ...
            'HarmonicRatioAcc', 'HarmonicRatioGyr', ...
            'CorrAccXY', 'CorrAccXZ', 'CorrAccYZ', 'CorrGyrXY', 'CorrGyrXZ', 'CorrGyrYZ', ...
            'GyroAccCorr', 'GyroAccMax', 'GyroAccStdProd'}, cwtBandNames];

featureTable = array2table(features_, 'VariableNames', varNames);
end







