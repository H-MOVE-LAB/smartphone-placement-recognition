function HR = harmonic_ratio(sig, fs)
% HARMONIC_RATIO calcola l'Harmonic Ratio di un segnale di accelerazione
%
%   HR = harmonic_ratio(sig, fs)
%
%   Input:
%       sig - segnale di accelerazione (vettore colonna o riga)
%       fs  - frequenza di campionamento [Hz]
%
%   Output:
%       HR  - valore dell'harmonic ratio

    % Assicurati che il segnale sia un vettore colonna
    sig = sig(:);

    % Rimuovi la media per evitare picchi a DC
    sig = sig - mean(sig);

    % Calcola lo spettro usando FFT
    N = length(sig);
    f = (0:N-1) * (fs / N); % vettore frequenze
    Y = fft(sig);
    P2 = abs(Y / N);       % spettro a due lati
    P1 = P2(1:floor(N/2)); % spettro a un lato
    f = f(1:floor(N/2));

    % Trova la frequenza fondamentale (picco principale, escludendo DC)
    [~, idx_max] = max(P1(2:end)); % ignora f=0
    idx_max = idx_max + 1;
    f0 = f(idx_max);

    % Numero di armoniche da considerare
    num_harmonics = floor((fs/2) / f0);

    % Calcolo HR: rapporto tra somma ampiezze armoniche pari e dispari
    odd_sum = 0;
    even_sum = 0;
    for k = 1:num_harmonics
        idx_h = round(f0*k / (fs/N)) + 1; % indice armonica
        if idx_h <= length(P1)
            if mod(k,2) == 1
                odd_sum = odd_sum + P1(idx_h);
            else
                even_sum = even_sum + P1(idx_h);
            end
        end
    end

    % Harmonic Ratio (secondo definizione comune: pari / dispari)
    HR = even_sum / odd_sum;
end
