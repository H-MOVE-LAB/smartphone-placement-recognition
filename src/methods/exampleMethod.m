function y = exampleMethod(x, fs, cutoffHz)
% EXAMPLEMETHOD Example method to demonstrate project structure.
%
% Input:
%   x        : input signal [Nx1]
%   fs       : sampling frequency [Hz]
%   cutoffHz : low-pass cutoff frequency [Hz]
%
% Output:
%   y : filtered signal [Nx1]

arguments
    x (:,1) double
    fs (1,1) double {mustBePositive}
    cutoffHz (1,1) double {mustBePositive}
end

Wn = cutoffHz / (fs/2);
Wn = min(Wn, 0.99);

[b,a] = butter(2, Wn, "low");
y = filtfilt(b,a,x);
end
