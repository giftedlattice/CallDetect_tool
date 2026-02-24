function redrawAll_v7(mainFig)
app = guidata(mainFig);

% -----------------------------
% Overview envelope (rear only) - improved visibility
% -----------------------------
axes(app.axOverview); cla(app.axOverview);
t = (0:numel(app.env_dB)-1)/app.fs;
envPlot = app.env_dB(:);

plot(app.axOverview, t, envPlot, 'Color', [0.15 0.15 0.15], 'LineWidth', 0.75);
hold(app.axOverview,'on');

thr = app.noiseFloor_dB + app.state.thrAboveNoise_dB;

yl = [min(envPlot) max(envPlot)];
patch(app.axOverview, ...
    [t(1) t(end) t(end) t(1)], ...
    [thr thr yl(2) yl(2)], ...
    [1 0.92 0.92], 'EdgeColor','none', 'FaceAlpha',0.35);

yline(app.axOverview, thr, '--', 'Color', [0.85 0.1 0.1], 'LineWidth', 2);

above = envPlot > thr;
if any(above)
    envHi = envPlot; envHi(~above) = NaN;
    plot(app.axOverview, t, envHi, 'Color', [0.85 0.1 0.1], 'LineWidth', 1.0);
end

% Dots at top for WORKING calls ONLY
yTop = yl(2);
dotY = yTop - 0.5;
for kk = 1:numel(app.state.calls_on)
    tt = (app.state.calls_on(kk)-1)/app.fs;
    cDot = [0.0 0.45 0.85];
    plot(app.axOverview, tt, dotY, 'o', ...
        'MarkerFaceColor', cDot, ...
        'MarkerEdgeColor', cDot, ...
        'MarkerSize', 6);

    text(app.axOverview, tt, dotY-0.8, sprintf('%d',kk), ...
        'HorizontalAlignment','center','VerticalAlignment','top', ...
        'FontSize',9,'FontWeight','bold', ...
        'Color', cDot,'Clipping','on');
end

xlabel(app.axOverview,'Time (s)');
ylabel(app.axOverview,'Env (dB)');

% Refresh list window
krgui.refreshTable_v7(mainFig);
krgui.refreshSelectedText_v7(mainFig);

% Draw selected views
krgui.redrawSelected_v7(mainFig);
end