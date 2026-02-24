function T = deriveCallTable_full(sig, fs, calls, meta, opts)
% All spectral features are computed from FIRST HARMONIC ONLY:
%   opts.harmBand_kHz
%
% Rear-only spectral features:
%   peakFreq_kHz, startFreq_kHz, endFreq_kHz, bandwidth_kHz, slope_kHz_per_ms
% Per-call timing:
%   timestamp_s (rear onset), timestamp_left_s/right_s (peak time within window), ipi_ms
% Per-channel amplitude at rear peak frequency:
%   peakAmp_rear/left/right (PSD value at rear peak frequency)

harmBand_Hz = opts.harmBand_kHz * 1000;

n = numel(calls);

bat   = repmat(string(meta.bat),  n, 1);
date  = repmat(string(meta.date), n, 1);
trial = repmat(string(meta.trial),n, 1);
call_number = (1:n)';

timestamp_s = nan(n,1);
timestamp_left_s  = nan(n,1);
timestamp_right_s = nan(n,1);
duration_ms = nan(n,1);
ipi_ms      = nan(n,1);

peakFreq_kHz = nan(n,1);
startFreq_kHz = nan(n,1);
endFreq_kHz   = nan(n,1);
bandwidth_kHz = nan(n,1);
slope_kHz_per_ms = nan(n,1);

peakAmp_rear = nan(n,1);
peakAmp_left = nan(n,1);
peakAmp_right= nan(n,1);

for k = 1:n
    on  = calls(k).on_samp;
    off = calls(k).off_samp;

    on  = max(1, min(size(sig,1), on));
    off = max(1, min(size(sig,1), off));

    if off <= on
        continue;
    end

    timestamp_s(k) = (on-1)/fs;
    duration_ms(k) = (off-on)/fs*1000;

    if k < n
        ipi_ms(k) = ((calls(k+1).on_samp-1) - (on-1))/fs*1000;
    end

    segR  = sig(on:off,1);
    segL  = sig(on:off,2);
    segRR = sig(on:off,3);

    % per-channel timing (peak abs waveform within window)
    [~, iPkL] = max(abs(segL));
    [~, iPkR] = max(abs(segRR));
    timestamp_left_s(k)  = (on + iPkL - 2)/fs;
    timestamp_right_s(k) = (on + iPkR - 2)/fs;

    % Rear PSD in harmonic band
    [Fr_kHz, Pr] = kr.pwelchBand(segR, fs, harmBand_Hz);
    if isempty(Fr_kHz)
        continue;
    end

    [~, iMax] = max(Pr);
    fPeak_kHz = Fr_kHz(iMax);
    peakFreq_kHz(k) = fPeak_kHz;

    % NOTE: start/end/bandwidth/slope are intentionally left NaN in v7 as in your current code.
    % You can later compute them using kr.minMaxFreqFromSpec() without touching GUI or IO.

    % Peak amplitude at REAR peak frequency, measured on all channels (PSD value)
    peakAmp_rear(k)  = kr.ampAtFreqFromPSD(segR,  fs, harmBand_Hz, fPeak_kHz);
    peakAmp_left(k)  = kr.ampAtFreqFromPSD(segL,  fs, harmBand_Hz, fPeak_kHz);
    peakAmp_right(k) = kr.ampAtFreqFromPSD(segRR, fs, harmBand_Hz, fPeak_kHz);
end

T = table(bat,date,trial,call_number, ...
    timestamp_s,timestamp_left_s,timestamp_right_s, ...
    duration_ms,ipi_ms, ...
    peakFreq_kHz,startFreq_kHz,endFreq_kHz,bandwidth_kHz,slope_kHz_per_ms, ...
    peakAmp_rear,peakAmp_left,peakAmp_right);
end