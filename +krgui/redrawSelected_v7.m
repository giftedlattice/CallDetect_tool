function redrawSelected_v7(mainFig)
app = guidata(mainFig);

cla(app.axCallWave); cla(app.axCallSpec);
cla(app.axCtxWave);  cla(app.axCtxSpec);

if isempty(app.state.calls_on)
    return;
end

k = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
on = app.state.calls_on(k);
off = app.state.calls_off(k);

on = max(1, min(app.Nsamp, on));
off = max(1, min(app.Nsamp, off));
if off < on
    tmp = on; on = off; off = tmp;
end

tOn  = (on-1)/app.fs;
tOff = (off-1)/app.fs;

% CALL display segment
half = round(app.opts.callHalfWin_s * app.fs);
a = max(1, round((on+off)/2) - half);
b = min(app.Nsamp, round((on+off)/2) + half);
tSeg = (a:b)/app.fs;
seg  = app.rear(a:b);

% CALL waveform (rear only)
axes(app.axCallWave);
kr.plotDecimated(tSeg, seg, app.opts.maxSegForPlot);
hold on;
ylW = ylim(app.axCallWave);

app.roi = kr.clearROIs(app.roi);
app.roi.on  = drawline(app.axCallWave, 'Position',[tOn ylW(1); tOn ylW(2)], 'LineWidth',2);
app.roi.off = drawline(app.axCallWave, 'Position',[tOff ylW(1); tOff ylW(2)], 'LineWidth',2);

app.roi.lisOn  = addlistener(app.roi.on,  'ROIMoved', @(src,evt) krgui.moveBound_v7(mainFig, src, "on"));
app.roi.lisOff = addlistener(app.roi.off, 'ROIMoved', @(src,evt) krgui.moveBound_v7(mainFig, src, "off"));

xlim(app.axCallWave, [tOn-app.opts.callPad_s, tOff+app.opts.callPad_s]);
title(app.axCallWave, sprintf('Call %d (KEPT) - REAR waveform', k));
xlabel(app.axCallWave,'Time (s)');

% CALL spectrogram
axes(app.axCallSpec);
[SdB,Fk,Tk] = kr.fastSpec(seg, app.fs, app.opts);
imagesc(app.axCallSpec, Tk + tSeg(1), Fk, SdB); axis(app.axCallSpec,'xy');
ylim(app.axCallSpec, app.opts.harmBand_kHz);
xlim(app.axCallSpec, [tOn-app.opts.callSpecPad_s, tOff+app.opts.callSpecPad_s]);
xlabel(app.axCallSpec,'Time (s)'); ylabel(app.axCallSpec,'kHz');
title(app.axCallSpec,'Spectrogram (rear)');
kr.contrastStretch(app.axCallSpec, SdB);

try
    if isgraphics(app.specBounds.on),  delete(app.specBounds.on);  end
    if isgraphics(app.specBounds.off), delete(app.specBounds.off); end
catch
end
app.specBounds.on  = xline(app.axCallSpec, tOn,  '--', 'LineWidth', 1.5);
app.specBounds.off = xline(app.axCallSpec, tOff, '--', 'LineWidth', 1.5);

% CONTEXT segment
ctxHalf = round(app.opts.contextHalfWin_s * app.fs);
cA = max(1, round((on+off)/2) - ctxHalf);
cB = min(app.Nsamp, round((on+off)/2) + ctxHalf);
tCtx = (cA:cB)/app.fs;

axes(app.axCtxWave);
kr.plotDecimated(tCtx, app.rear(cA:cB), app.opts.maxSegForPlot);
hold on;
xline(app.axCtxWave, tOn,'--'); xline(app.axCtxWave, tOff,'--');
title(app.axCtxWave, 'Context waveform (rear)');
xlabel(app.axCtxWave,'Time (s)');

axes(app.axCtxSpec);
ctx = app.rear(cA:cB);
[SdBc,Fkc,Tkc] = kr.fastSpec(ctx, app.fs, app.opts);
imagesc(app.axCtxSpec, Tkc + tCtx(1), Fkc, SdBc); axis(app.axCtxSpec,'xy');
ylim(app.axCtxSpec, app.opts.harmBand_kHz);
xlabel(app.axCtxSpec,'Time (s)'); ylabel(app.axCtxSpec,'kHz');
title(app.axCtxSpec,'Context spectrogram (rear)');
kr.contrastStretch(app.axCtxSpec, SdBc);

guidata(mainFig, app);
end