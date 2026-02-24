function refreshTable_v7(mainFig)
app = guidata(mainFig);

n = numel(app.state.calls_on);
app.tbl.ColumnName  = {'L/U','#','t_on_s','dur_ms','next_ms'};
app.tbl.ColumnWidth = {40,35,80,70,80};

if n == 0
    app.tbl.Data = cell(0,5);
    guidata(mainFig, app);
    return;
end

onS  = app.state.calls_on(:);
offS = app.state.calls_off(:);
[onS, offS] = krgui.scrubBounds_v7(onS, offS, app.Nsamp);

tOn_s  = (onS - 1) / app.fs;
dur_ms = ((offS - onS) + 1) / app.fs * 1000;

next_ms = nan(n,1);
if n > 1
    next_ms(1:n-1) = (onS(2:n) - onS(1:n-1)) / app.fs * 1000;
end

data = cell(n,5);
for k = 1:n
    data{k,1} = 'L'; % all shown are kept
    data{k,2} = k;
    data{k,3} = round(tOn_s(k), 6);
    data{k,4} = round(dur_ms(k), 3);
    data{k,5} = round(next_ms(k), 3);
end

app.tbl.Data = data;
guidata(mainFig, app);
end