function refreshTable_v7(mainFig)
app = guidata(mainFig);

% If nothing kept, show empty table with export column headers
if isempty(app.state.calls_on)
    % Make an empty table with correct variable names by calling export on empty calls
    T = kr.deriveCallTable_full(app.sig, app.fs, struct([]), app.meta, app.opts);

    app.tbl.Data = cell(0, width(T));
    app.tbl.ColumnName = T.Properties.VariableNames;

    try
        app.tbl.ColumnWidth = 'auto';
    catch
    end

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

% Use the SAME export function to generate preview values
T = kr.deriveCallTable_full(app.sig, app.fs, calls, app.meta, app.opts);

% Convert to cell for uitable and sanitize types for compatibility
data = table2cell(T);
data = sanitizeForUITable(data);

% Apply to UI
app.tbl.Data = data;
app.tbl.ColumnName = T.Properties.VariableNames;

try
    app.tbl.ColumnWidth = 'auto';
catch
end

guidata(mainFig, app);
end

% =========================
% Local helper: convert unsupported cell contents to char
% =========================
function c = sanitizeForUITable(c)
for i = 1:numel(c)
    v = c{i};

    % Convert string scalars/arrays to char
    if isa(v,'string')
        if isscalar(v)
            c{i} = char(v);
        else
            % join string arrays for display
            c{i} = char(strjoin(v, ","));
        end

    % Convert categorical to char
    elseif isa(v,'categorical')
        c{i} = char(string(v));

    % Convert datetime/duration to char
    elseif isa(v,'datetime') || isa(v,'duration')
        c{i} = char(string(v));

    % Convert cellstr -> char (first element)
    elseif iscell(v)
        try
            c{i} = char(string(v));
        catch
            % last resort: show class name
            c{i} = char(class(v));
        end

    % Leave numeric/logical/char as-is
    else
        % ok
    end
end
end