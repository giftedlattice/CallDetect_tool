function onClickAdd_v7(mainFig)
app = guidata(mainFig);

% Only add when one-shot mode is armed AND click is in overview axes
if ~isfield(app.state,'mode') || app.state.mode ~= "add_once" || ~isequal(gca, app.axOverview)
    return;
end

% Disarm immediately (one-shot)
app.state.mode = "none";
guidata(mainFig, app);

% Click time -> sample
cp = get(app.axOverview,'CurrentPoint');
tClick = cp(1,1);
sClick = round(tClick*app.fs) + 1;
sClick = max(1, min(numel(app.env_dB), sClick));

% --- Step 1: find LOCAL PEAK near click (more robust than using click sample)
pkWin_ms = 1.0; % search +/- 1 ms around click for peak
pkWinS = max(1, round((pkWin_ms/1000)*app.fs));
aPk = max(1, sClick - pkWinS);
bPk = min(numel(app.env_dB), sClick + pkWinS);
[~, iPk] = max(app.env_dB(aPk:bPk));
sPk = aPk + iPk - 1;

% --- Step 2: seed bounds by expanding from peak using current acceptance threshold
thr = app.noiseFloor_dB + app.state.thrAboveNoise_dB;

on = sPk;
while on > 1 && app.env_dB(on) > thr
    on = on - 1;
end

off = sPk;
while off < numel(app.env_dB) && app.env_dB(off) > thr
    off = off + 1;
end

% --- Step 3: refine to MAIN BURST to trim echoes (your new desired behavior)
if isfield(app.opts,'boundRefine_enable') && app.opts.boundRefine_enable
    [on, off] = krgui.refineBoundsMainBurst_v7(app.env_dB, app.fs, on, off, app.opts);
end

% Append to candidate pool + force keep (manual keep)
app.state.calls_on_fixed(end+1)   = on;
app.state.calls_off_fixed(end+1)  = off;
app.state.manualKeep_fixed(end+1) = true;

% Sort + scrub candidates
[app.state.calls_on_fixed, ord] = sort(app.state.calls_on_fixed(:));
app.state.calls_off_fixed  = app.state.calls_off_fixed(ord);
app.state.manualKeep_fixed = app.state.manualKeep_fixed(ord);

[app.state.calls_on_fixed, app.state.calls_off_fixed] = krgui.scrubBounds_v7( ...
    app.state.calls_on_fixed, app.state.calls_off_fixed, app.Nsamp);

% Recompute auto keep under current threshold
app.state.autoKeep_fixed = krgui.computeAutoKeepMask_v7( ...
    app.env_dB, app.noiseFloor_dB, app.state.thrAboveNoise_dB, ...
    app.state.calls_on_fixed, app.state.calls_off_fixed);

% Rebuild working list
[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = krgui.applyFilter_v7(app.state);

% Select the newly added call (find fixed index that was just added)
newFixedIdx = find(app.state.manualKeep_fixed, 1, 'last');
newDispIdx  = find(app.state.dispToFixed == newFixedIdx, 1, 'first');
if ~isempty(newDispIdx)
    app.state.selectedIdx = newDispIdx;
end

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);
end