function moveBound_v7(mainFig, roiHandle, which)
app = guidata(mainFig);
if isempty(app.state.calls_on)
    return;
end

kDisp = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
fixedIdx = app.state.dispToFixed(kDisp);

pos = roiHandle.Position;
sNew = round(pos(1,1)*app.fs) + 1;
sNew = max(1, min(numel(app.rear), sNew));

minDurS = round((app.opts.minCallDur_ms/1000)*app.fs);

onS  = app.state.calls_on_fixed(fixedIdx);
offS = app.state.calls_off_fixed(fixedIdx);

if which == "on"
    onS = min(sNew, offS - minDurS);
else
    offS = max(sNew, onS + minDurS);
end

app.state.calls_on_fixed(fixedIdx)  = onS;
app.state.calls_off_fixed(fixedIdx) = offS;

[app.state.calls_on_fixed, app.state.calls_off_fixed] = krgui.scrubBounds_v7(app.state.calls_on_fixed, app.state.calls_off_fixed, app.Nsamp);

app.state.autoKeep_fixed = krgui.computeAutoKeepMask_v7( ...
    app.env_dB, app.noiseFloor_dB, app.state.thrAboveNoise_dB, ...
    app.state.calls_on_fixed, app.state.calls_off_fixed);

[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = krgui.applyFilter_v7(app.state);

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);
end