function out = feature_ridgeFreqs_v7(x, fs, opts)
%FEATURE_RIDGEFREQS_V7 Ridge-based frequency features in first harmonic band.
% Returns struct:
%   start_kHz, end_kHz, min_kHz, max_kHz, startHigh_kHz
%
% Definitions:
% - Ridge at each time bin = max-energy frequency within harm band.
% - Active time bins = bins where ridge power within ridgeActiveDrop_dB of max ridge power.
% - start_kHz/end_kHz = ridge freq at first/last active time bin.
% - min/max = min/max ridge freq across active bins (bandwidth support).
% - startHigh_kHz = at first active time bin, highest freq whose power is within
%                   ridgeEdgeDrop_dB of that slice's peak (captures upper energy).

out = struct('start_kHz',NaN,'end_kHz',NaN,'min_kHz',NaN,'max_kHz',NaN,'startHigh_kHz',NaN);

x = double(x(:));
if numel(x) < 32
    return;
end

% Defaults if not provided
if ~isfield(opts,'ridgeActiveDrop_dB'), opts.ridgeActiveDrop_dB = 12; end
if ~isfield(opts,'ridgeEdgeDrop_dB'),   opts.ridgeEdgeDrop_dB   = 28; end

win  = min(opts.specWin, numel(x));
ovl  = min(opts.specOvl, win-1);
nfft = max(opts.specNfft, 2^nextpow2(win));

[S,F,~] = spectrogram(x, win, ovl, nfft, fs, 'yaxis');
SdB = 20*log10(abs(S)+eps);
FkHz = F/1000;

% Harmonic band
band = (FkHz >= opts.harmBand_kHz(1)) & (FkHz <= opts.harmBand_kHz(2));
if ~any(band)
    return;
end

Sb = SdB(band,:);
Fb = FkHz(band);

% Ridge per time bin
[pCol, iCol] = max(Sb, [], 1);
fRidge = Fb(iCol);

% Active time bins (for defining START/END time)
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

% High-edge frequency at the START time bin (more permissive threshold)
slice = Sb(:, tStart);
slicePeak = max(slice);

good = slice >= (slicePeak - opts.ridgeEdgeDrop_dB);
if any(good)
    out.startHigh_kHz = max(Fb(good));
end
end