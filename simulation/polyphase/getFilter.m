function Hd = getFilter(sps, a)
%GETFILTER Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.7 and Signal Processing Toolbox 8.3.
% Generated on: 22-Apr-2022 14:31:33

SPS        = sps;                           % Samples per Symbol
PulseShape = 'Square Root Raised Cosine';  % Pulse shape
Astop      = 30;                           % Stopband Attenuation
Beta       = a;                          % Rolloff Factor

h = fdesign.pulseshaping(SPS, PulseShape, 'ast,beta', Astop, Beta);

Hd = design(h, 'window');


