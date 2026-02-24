function [calls, detInfo] = callDetectGUI_v7(sig, fs, opts)
%CALLDETECTGUI_V7 Modular GUI entry point (public API stays the same).

% Validate inputs (fast)
if ~isnumeric(sig) || size(sig,2) ~= 3
    error('sig must be Nsamp x 3 numeric: [rear,left,right].');
end
if ~isscalar(fs) || ~isfinite(fs) || fs <= 0
    error('fs must be a positive finite scalar.');
end

% Build initial state (detection happens ONCE here)
app = krgui.initState_v7(sig, fs, opts);

% Build UI (two windows) and store handles into app
app = krgui.buildUI_v7(app);

% Wire callbacks (callbacks live in package functions; they read/write guidata)
krgui.wireCallbacks_v7(app.mainFig);

% Initial draw
krgui.redrawAll_v7(app.mainFig);

% Block until OK/Cancel
uiwait(app.mainFig);

% If figures were closed unexpectedly
if ~ishandle(app.mainFig)
    calls = struct([]);
    detInfo = struct('accepted',false);
    return;
end

% Pull final app state
app = guidata(app.mainFig);

% Build outputs
[calls, detInfo] = krgui.buildOutputs_v7(app);

% Close windows
krgui.safeClose_v7(app);

end