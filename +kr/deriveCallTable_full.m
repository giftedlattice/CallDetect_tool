function T = deriveCallTable_full(sig, fs, calls, meta, opts)
%DERIVECALLTABLE_FULL Export table for detected calls (modular version).
%
% Metadata columns:
%   bat, date, trial, condition, catchTrial, temperature_C, humidity_pct
%
% Frequency conventions (UPDATED):
%   startFreq_kHz  = start HIGH edge at the START time bin (startHigh_kHz)
%   endFreq_kHz    = end LOW edge at the END time bin (endLow_kHz)
%
% Diagnostic columns retained:
%   startFreq_low_kHz  (ridge at start bin)
%   startFreq_high_kHz (high edge at start bin)
%   endFreq_ridge_kHz  (ridge at end bin)
%   endFreq_low_kHz    (low edge at end bin)  <-- same as exported endFreq_kHz
%
% Bandwidth and slope:
%   bandwidth_kHz      = max(ridge)-min(ridge) across active time bins
%   slope_kHz_per_ms   = (endFreq_kHz - startFreq_kHz) / duration_ms  (signed)

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

% Exported start/end frequencies
startFreq_kHz = nan(n,1);  % START HIGH edge
endFreq_kHz   = nan(n,1);  % END LOW edge

% Diagnostics
startFreq_low_kHz   = nan(n,1); % ridge at start time bin
startFreq_high_kHz  = nan(n,1); % high edge at start time bin
endFreq_ridge_kHz   = nan(n,1); % ridge at end time bin
endFreq_low_kHz     = nan(n,1); % low edge at end time bin (same as endFreq_kHz)

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

    % Ridge features (includes startHigh and endLow)
    r = kr.feature_ridgeFreqs_v7(segR, fs, opts);

    % Diagnostics at start
    startFreq_low_kHz(k)  = r.start_kHz;
    startFreq_high_kHz(k) = r.startHigh_kHz;

    % Exported START = high edge
    startFreq_kHz(k) = r.startHigh_kHz;

    % Diagnostics at end
    endFreq_ridge_kHz(k) = r.end_kHz;
    endFreq_low_kHz(k)   = r.endLow_kHz;

    % Exported END = low edge
    endFreq_kHz(k) = r.endLow_kHz;

    % Bandwidth from ridge min/max across active bins
    if isfinite(r.min_kHz) && isfinite(r.max_kHz)
        bandwidth_kHz(k) = r.max_kHz - r.min_kHz;
    end

    % Slope uses exported start/end
    if isfinite(startFreq_kHz(k)) && isfinite(endFreq_kHz(k)) && duration_ms(k) > 0
        slope_kHz_per_ms(k) = (endFreq_kHz(k) - startFreq_kHz(k)) / duration_ms(k);
    end

    % Amplitudes at rear peak frequency (NaN-safe helper)
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
T = table( ...
    bat,date,trial,condition,catchTrial,temperature_C,humidity_pct,call_number, ...
    timestamp_s,timestamp_left_s,timestamp_right_s, ...
    duration_ms,ipi_ms, ...
    peakFreq_kHz, ...
    startFreq_kHz, endFreq_kHz, ...
    startFreq_low_kHz, startFreq_high_kHz, ...
    endFreq_ridge_kHz, endFreq_low_kHz, ...
    bandwidth_kHz, slope_kHz_per_ms, ...
    peakAmp_rear, peakAmp_left, peakAmp_right);

end