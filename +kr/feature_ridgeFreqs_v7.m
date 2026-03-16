function out = feature_ridgeFreqs_v7(x, fs, opts)
%FEATURE_RIDGEFREQS_V7 Ridge-based frequency features in first harmonic band.
% Returns struct:
%   start_kHz, end_kHz, min_kHz, max_kHz, startHigh_kHz, endLow_kHz
%
% Thresholds:
%   opts.ridgeActiveDrop_dB        : active time bins (start/end time)
%   opts.ridgeEdgeDropStart_dB     : edge threshold for startHigh
%   opts.ridgeEdgeDropEnd_dB       : edge threshold for endLow

out = struct('start_kHz',NaN,'end_kHz',NaN,'min_kHz',NaN,'max_kHz',NaN, ...
             'startHigh_kHz',NaN,'endLow_kHz',NaN);

x = double(x(:));
if numel(x) < 32
    return;
end

% Defaults if not provided
if ~isfield(opts,'ridgeActiveDrop_dB'),     opts.ridgeActiveDrop_dB = 12; end
if ~isfield(opts,'ridgeEdgeDropStart_dB'),  opts.ridgeEdgeDropStart_dB = 28; end
if ~isfield(opts,'ridgeEdgeDropEnd_dB'),    opts.ridgeEdgeDropEnd_dB = 36; end

win  = min(opts.specWin, numel(x));
ovl  = min(opts.specOvl, win-1);
nfft = max(opts.specNfft, 2^nextpow2(win));

[S,F,~] = spectrogram(x, win, ovl, nfft, fs, 'yaxis');
SdB = 20*log10(abs(S)+eps);
FkHz = F/1000;

band = (FkHz >= opts.harmBand_kHz(1)) & (FkHz <= opts.harmBand_kHz(2));
if ~any(band)
    return;
end

Sb = SdB(band,:);
Fb = FkHz(band);

[pCol, iCol] = max(Sb, [], 1);
fRidge = Fb(iCol);

pMax = max(pCol);
active = pCol >= (pMax - opts.ridgeActiveDrop_dB);
if ~any(active)
    active = true(size(pCol));
end

idx = find(active);
tStart = idx(1);
tEnd   = idx(end);

out.start_kHz = fRidge(tStart);
out.end_kHz   = fRidge(tEnd);
out.min_kHz   = min(fRidge(active));
out.max_kHz   = max(fRidge(active));

% Start high edge
sliceS = Sb(:, tStart);
sliceS_peak = max(sliceS);
goodS = sliceS >= (sliceS_peak - opts.ridgeEdgeDropStart_dB);
if any(goodS)
    out.startHigh_kHz = max(Fb(goodS));
end

% End low edge
sliceE = Sb(:, tEnd);
sliceE_peak = max(sliceE);
goodE = sliceE >= (sliceE_peak - opts.ridgeEdgeDropEnd_dB);
if any(goodE)
    out.endLow_kHz = min(Fb(goodE));
end
end