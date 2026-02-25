function T = deriveCallTable_full(sig, fs, calls, meta, opts)
%DERIVECALLTABLE_FULL Export table for detected calls (modular version).
%
% Robust to missing channels:
% - sig(:,2) or sig(:,3) may be NaN-filled (from normalizeSigTo3ch)
% - left/right timing and amps remain NaN when channel is missing.

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

Nsamp = size(sig,1);

for k = 1:n
    on  = max(1, min(Nsamp, calls(k).on_samp));
    off = max(1, min(Nsamp, calls(k).off_samp));
    if off <= on
        continue;
    end

    % ---- timing (rear)
    timestamp_s(k) = (on-1)/fs;
    duration_ms(k) = ((off-on)+1)/fs*1000; % inclusive duration

    if k < n
        ipi_ms(k) = ((calls(k+1).on_samp-1) - (on-1))/fs*1000;
    end

    segR  = sig(on:off,1);
    segL  = sig(on:off,2);
    segRR = sig(on:off,3);

    % ---- left/right timing (only if channel exists)
    if any(isfinite(segL))
        [~, iPkL] = max(abs(segL), [], 'omitnan');
        timestamp_left_s(k)  = (on + iPkL - 2)/fs;
    end
    if any(isfinite(segRR))
        [~, iPkR] = max(abs(segRR), [], 'omitnan');
        timestamp_right_s(k) = (on + iPkR - 2)/fs;
    end

    % ---- spectral features (rear)
    fPeak = kr.feature_peakFreqWelch_v7(segR, fs, opts);
    peakFreq_kHz(k) = fPeak;

    r = kr.feature_ridgeFreqs_v7(segR, fs, opts);
    startFreq_kHz(k) = r.start_kHz;
    endFreq_kHz(k)   = r.end_kHz;

    if isfinite(r.min_kHz) && isfinite(r.max_kHz)
        bandwidth_kHz(k) = r.max_kHz - r.min_kHz;
    end

    if isfinite(r.start_kHz) && isfinite(r.end_kHz) && isfinite(duration_ms(k)) && duration_ms(k) > 0
        slope_kHz_per_ms(k) = (r.end_kHz - r.start_kHz) / duration_ms(k);
    end

    % ---- amplitudes at rear peak frequency (only compute channel if data exists)
    if isfinite(fPeak)
        amps = kr.feature_peakAmpsAtPeakFreq_v7(segR, segL, segRR, fs, opts, fPeak);
        peakAmp_rear(k) = amps.rear;
        peakAmp_left(k) = amps.left;
        peakAmp_right(k)= amps.right;
    end
end

T = table(bat,date,trial,call_number, ...
    timestamp_s,timestamp_left_s,timestamp_right_s, ...
    duration_ms,ipi_ms, ...
    peakFreq_kHz,startFreq_kHz,endFreq_kHz,bandwidth_kHz,slope_kHz_per_ms, ...
    peakAmp_rear,peakAmp_left,peakAmp_right);
end