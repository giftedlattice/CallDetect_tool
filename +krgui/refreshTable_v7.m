function refreshTable_v7(mainFig)
app = guidata(mainFig);

% Choose a fixed linear scale for power display (constant across all files)
% Pick something that makes values "human sized".
% If your values are typically ~1e-10 to 1e-6, then 1e9 gives ~1e-1 to 1e3.
SCALE = 1e9;
SCALE_LABEL = sprintf('(x%.0e)', SCALE);

% If nothing kept, show empty table with export column headers (+ the new display cols)
if isempty(app.state.calls_on)
    T = kr.deriveCallTable_full(app.sig, app.fs, struct([]), app.meta, app.opts);

    % Build display table with added columns (empty)
    Tdisp = addAmpDisplayColumns(T, SCALE);

    app.tbl.Data = cell(0, width(Tdisp));
    app.tbl.ColumnName = Tdisp.Properties.VariableNames;

    try, app.tbl.ColumnWidth = 'auto'; catch, end
    guidata(mainFig, app);
    return;
end

% Build calls struct from WORKING list (kept calls only)
n = numel(app.state.calls_on);
calls = repmat(struct('on_samp',[],'off_samp',[]), n, 1);
for k = 1:n
    calls(k).on_samp  = app.state.calls_on(k);
    calls(k).off_samp = app.state.calls_off(k);
end

% Generate export-accurate table
T = kr.deriveCallTable_full(app.sig, app.fs, calls, app.meta, app.opts);

% Build a DISPLAY table (adds scaled + dB columns)
Tdisp = addAmpDisplayColumns(T, SCALE);

% Convert to cell for uitable and sanitize types
data = table2cell(Tdisp);
data = sanitizeForUITable(data);

% Apply to UI
app.tbl.Data = data;

% Better header labels: annotate scaled columns
vars = Tdisp.Properties.VariableNames;
vars = annotateScaledHeaders(vars, SCALE_LABEL);
app.tbl.ColumnName = vars;

try, app.tbl.ColumnWidth = 'auto'; catch, end
guidata(mainFig, app);
end

% =====================================================================
% Helpers
% =====================================================================
function Tdisp = addAmpDisplayColumns(T, SCALE)
% Adds 3 scaled-linear columns + 3 dB columns, leaving original T unchanged.
Tdisp = T;

% Only act if these columns exist
ampNames = {'peakAmp_rear','peakAmp_left','peakAmp_right'};
for i = 1:numel(ampNames)
    nm = ampNames{i};
    if ~ismember(nm, Tdisp.Properties.VariableNames)
        return;
    end
end

% Scaled linear columns
Tdisp.peakAmp_rear_scaled  = Tdisp.peakAmp_rear  * SCALE;
Tdisp.peakAmp_left_scaled  = Tdisp.peakAmp_left  * SCALE;
Tdisp.peakAmp_right_scaled = Tdisp.peakAmp_right * SCALE;

% dB columns (10*log10 for power / PSD)
Tdisp.peakAmp_rear_dB  = toDbSafe(Tdisp.peakAmp_rear);
Tdisp.peakAmp_left_dB  = toDbSafe(Tdisp.peakAmp_left);
Tdisp.peakAmp_right_dB = toDbSafe(Tdisp.peakAmp_right);

% Reorder: keep original export columns first, then the display extras
origVars = T.Properties.VariableNames;
extraVars = {'peakAmp_rear_scaled','peakAmp_left_scaled','peakAmp_right_scaled', ...
             'peakAmp_rear_dB','peakAmp_left_dB','peakAmp_right_dB'};
Tdisp = Tdisp(:, [origVars, extraVars]);
end

function y = toDbSafe(x)
% Convert power to dB safely (NaN for <=0 or non-finite)
y = nan(size(x));
mask = isfinite(x) & (x > 0);
y(mask) = 10*log10(x(mask));
end

function names = annotateScaledHeaders(names, scaleLabel)
% Add "(x1e9)" tag to scaled columns and "(dB)" to dB columns
for i = 1:numel(names)
    if endsWith(names{i}, '_scaled')
        names{i} = [names{i} ' ' scaleLabel];
    elseif endsWith(names{i}, '_dB')
        names{i} = [names{i} ' (dB)'];
    end
end
end

function c = sanitizeForUITable(c)
% Convert unsupported cell contents to char for older uitable versions
for i = 1:numel(c)
    v = c{i};

    if isa(v,'string')
        if isscalar(v)
            c{i} = char(v);
        else
            c{i} = char(strjoin(v, ","));
        end

    elseif isa(v,'categorical')
        c{i} = char(string(v));

    elseif isa(v,'datetime') || isa(v,'duration')
        c{i} = char(string(v));

    elseif iscell(v)
        try
            c{i} = char(string(v));
        catch
            c{i} = char(class(v));
        end
    end
end
end