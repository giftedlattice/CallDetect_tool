function T = deriveCallTable_full(sig, fs, calls, meta, opts)
%DERIVECALLTABLE_FULL Export table for detected calls (modular version).
%
% Includes metadata columns:
%   bat, date, trial, condition, catchTrial, temperature_C, humidity_pct
%
% startFreq_kHz is defined as startFreq_high_kHz (upper edge at onset).

n = numel(calls);

% -------------------------
% Safe metadata extraction
% -------------------------
batVal = "";
if isstruct(meta) && isfield(meta,'bat'), batVal = string(meta.bat); end

dateVal = "";
if isstruct(meta) && isfield(meta,'date'), dateVal = string(meta.date); end

trialVal = "";
if isstruct(meta) && isfield(meta,'trial'), trialVal = string(meta.trial); end

condVal = "";
if isstruct(meta) && isfield(meta,'condition'), condVal = string(meta.condition); end

catchVal = false;
if isstruct(meta) && isfield(meta,'catchTrial'), catchVal = logical(meta.catchTrial); end

tempVal = NaN;
if isstruct(meta) && isfield(meta,'temperature_C'), tempVal = double(meta.temperature_C); end

humVal = NaN;
if isstruct(meta) && isfield(meta,'humidity_pct'), humVal = double(meta.humidity_pct); end

bat   = repmat(batVal,   n, 1);
date  = repmat(dateVal,  n, 1);
trial = repmat(trialVal, n, 1);

condition     = repmat(condVal, n, 1);
catchTrial    = repmat(catchVal, n, 1);
temperature_C = repmat(tempVal, n, 1);
humidity_pct  = repmat(humVal,  n, 1);

call_number = (1:n)';

% -------------------------
% Output variables
% -------------------------
timestamp_s = nan(n,1);
timestamp_left_s  = nan(n,1);
timestamp_right_s = nan(n,1);
duration_ms = nan(n,1);
ipi_ms      = nan(n,1);

peakFreq_kHz = nan(n,1);

% Canonical startFreq_kHz (will equal high edge)
startFreq_kHz = nan(n,1);

% Diagnostics
startFreq_low_kHz  = nan(n,1);
startFreq_high_kHz = nan(n,1);

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

    % Timing (rear)
    timestamp_s(k) = (on-1)/fs;
    duration_ms(k) = ((off-on)+1)/fs*1000; % inclusive

    if k < n
        ipi_ms(k) = ((calls(k+1).on_samp-1) - (on-1))/fs*1000;
    end

    segR  = sig(on:off,1);
    segL  = sig(on:off,2);
    segRR = sig(on:off,3);

    % Left/right timing only if finite samples exist
    if any(isfinite(segL))
        [~, iPkL] = max(abs(segL), [], 'omitnan');
        timestamp_left_s(k)  = (on + iPkL - 2)/fs;
    end
    if any(isfinite(segRR))
        [~, iPkR] = max(abs(segRR), [], 'omitnan');
        timestamp_right_s(k) = (on + iPkR - 2)/fs;
    end

    % Peak frequency from Welch (rear)
    fPeak = kr.feature_peakFreqWelch_v7(segR, fs, opts);
    peakFreq_kHz(k) = fPeak;

    % Ridge features (includes startHigh)
    r = kr.feature_ridgeFreqs_v7(segR, fs, opts);

    startFreq_low_kHz(k)  = r.start_kHz;
    startFreq_high_kHz(k) = r.startHigh_kHz;

    % Canonical startFreq for downstream use: HIGH edge
    startFreq_kHz(k) = r.startHigh_kHz;

    endFreq_kHz(k) = r.end_kHz;

    if isfinite(r.min_kHz) && isfinite(r.max_kHz)
        bandwidth_kHz(k) = r.max_kHz - r.min_kHz;
    end

    % Slope uses canonical startFreq_kHz (high edge)
    if isfinite(startFreq_kHz(k)) && isfinite(endFreq_kHz(k)) && duration_ms(k) > 0
        slope_kHz_per_ms(k) = (endFreq_kHz(k) - startFreq_kHz(k)) / duration_ms(k);
    end

    % Amplitudes at rear peak frequency (NaN-safe inside helper)
    if isfinite(fPeak)
        amps = kr.feature_peakAmpsAtPeakFreq_v7(segR, segL, segRR, fs, opts, fPeak);
        peakAmp_rear(k)  = amps.rear;
        peakAmp_left(k)  = amps.left;
        peakAmp_right(k) = amps.right;
    end
end

% -------------------------
% Final table (metadata first)
% -------------------------
T = table(bat,date,trial,condition,catchTrial,temperature_C,humidity_pct,call_number, ...
    timestamp_s,timestamp_left_s,timestamp_right_s, ...
    duration_ms,ipi_ms, ...
    peakFreq_kHz, ...
    startFreq_kHz, ...
    startFreq_low_kHz,startFreq_high_kHz, ...
    endFreq_kHz,bandwidth_kHz,slope_kHz_per_ms, ...
    peakAmp_rear,peakAmp_left,peakAmp_right);
end