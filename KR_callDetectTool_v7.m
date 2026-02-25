function KR_callDetectTool_v7()
% KR_callDetectTool_v7 (modularized v7)
% - Detect calls using REAR channel only
% - Edit call start/end in REAR waveform (draggable bounds)
% - Toggle / Delete / Add supported in GUI
% - Export computes first-harmonic features + per-channel timing/amp (if channels exist)
%
% Audio MAT must contain:
%   sig: [Nsamp x 1] OR [Nsamp x 2] OR [Nsamp x 3]
%   fs : optional

% ====== METADATA (edit these) ======
meta = struct();
meta.bat   = "bat1";
meta.date  = "2026-02-12";
meta.trial = "03";

fsDefault = 250000;
opts = kr.defaultOpts_v7();

[aFiles, aPath] = uigetfile('*.mat', ...
    'Select audio MAT file(s) containing "sig"', ...
    'MultiSelect','on');

if isequal(aFiles,0)
    return;
end
if ischar(aFiles)
    aFiles = {aFiles};
end

for i = 1:numel(aFiles)
    fullMat = fullfile(aPath, aFiles{i});
    S = load(fullMat);

    if ~isfield(S,'sig')
        warning('Skipping %s: no sig.', aFiles{i});
        continue;
    end

    % Normalize to Nx3 [rear,left,right]
    try
        sig = kr.normalizeSigTo3ch(S.sig);
    catch ME
        warning('Skipping %s: %s', aFiles{i}, ME.message);
        continue;
    end

    fs = fsDefault;
    if isfield(S,'fs') && ~isempty(S.fs)
        fs = double(S.fs);
    end

    % GUI (now takes meta for preview table)
    [calls, detInfo] = kr.callDetectGUI_v7(sig, fs, opts, meta);

    [~, baseChar] = fileparts(aFiles{i});
    base = string(baseChar);

    outCalls = fullfile(aPath, base + "_calls.mat");
    save(outCalls,'calls','detInfo','fs','fullMat');

    if isfield(detInfo,'accepted') && detInfo.accepted && ~isempty(calls)
        T = kr.deriveCallTable_full(sig, fs, calls, meta, opts);
        writetable(T, fullfile(aPath, base + "_calls.csv"));

        % store table in calls mat for convenience
        detInfo.callTable = T; %#ok<NASGU>
        save(outCalls,'calls','detInfo','fs','fullMat');
    end
end
end