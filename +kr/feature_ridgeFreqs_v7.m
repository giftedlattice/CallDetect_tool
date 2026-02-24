function out = feature_ridgeFreqs_v7(x, fs, opts)
%FEATURE_RIDGEFREQS_V7 Ridge-based frequency features in first harmonic band.
% Returns struct with fields:
%   start_kHz, end_kHz, min_kHz, max_kHz
% Uses spectrogram ridge and "active bins" mask.

out = struct('start_kHz',NaN,'end_kHz',NaN,'min_kHz',NaN,'max_kHz',NaN);

x = double(x(:));
if numel(x) < 32
    return;
end

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

[pCol, iCol] = max(Sb, [], 1);   % ridge power and index per time bin
fRidge = Fb(iCol);              % ridge frequency per time bin

pMax = max(pCol);
active = pCol >= (pMax - 12);   % default 12 dB-down active region
if ~any(active)
    active = true(size(pCol));
end

idx = find(active);
out.start_kHz = fRidge(idx(1));
out.end_kHz   = fRidge(idx(end));
out.min_kHz   = min(fRidge(active));
out.max_kHz   = max(fRidge(active));
end