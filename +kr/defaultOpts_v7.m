% =========================
% File: +kr/defaultOpts_v7.m
% FULL UPDATED VERSION
% =========================
function opts = defaultOpts_v7()
%DEFAULTOPTS_V7 Central place for all tunable parameters.

opts = struct();

% Detection band (rear only)
opts.bpHz = [20000 100000];

% FIRST HARMONIC band for all spectral features + displayed spectrograms
opts.harmBand_kHz = [20 70];

% Envelope smoothing
opts.envSmooth_ms = 0.6;

% Detection criteria
opts.minCallDur_ms = 0.3;
opts.minCallSep_ms = 2.0;
opts.mergeGap_ms   = 0.6;
opts.initThrAboveNoise_dB = 12;

% Windows
opts.callHalfWin_s    = 0.020; % around call for call-view display
opts.contextHalfWin_s = 1.50;  % big context window

% Tight display padding around editable bounds
opts.callPad_s     = 0.002; % waveform
opts.callSpecPad_s = 0.030; % spectrogram

% Fast spectrogram settings (ALWAYS use these)
opts.specWin  = 256;
opts.specOvl  = 192;
opts.specNfft = 512;

% Plot decimation
opts.maxSegForPlot = 2500;

% --- Auto boundary refinement to cut off echoes (main burst) ---
opts.boundRefine_enable = true;

% Relative-to-peak drop (dB). Bigger = shorter bounds (more aggressive).
% Typical: 12–18. Start at ~14.
opts.boundRefine_dropFromPeak_dB = 14;

opts.ridgeActiveDrop_dB = 12;  % for active time bins (start/end time)
opts.ridgeEdgeDrop_dB   = 28;  % for high-edge at start bin (more permissive)

% Quiet hold time required below (peak-drop) to declare end (ms).
% Typical: 0.1–0.4 ms depending on echo density.
opts.boundRefine_quiet_ms = 0.20;

% Search padding around initial bounds (ms)
opts.boundRefine_pad_ms = 0.30;

% Start refinement: threshold below peak used to find true onset (dB down from peak)
% Typical: 16–24. Larger = later onset (more conservative).
opts.boundRefine_startDrop_dB = 18;

end