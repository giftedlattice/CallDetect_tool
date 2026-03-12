function saveConditions_v7(conds)
%SAVECONDITIONS_V7 Save condition list into config file.

conds = unique(string(conds(:)), 'stable');

cfgPath = krgui.metaConfigPath_v7();

% Preserve existing metaLast if present
metaLast = [];
try
    if exist(cfgPath,'file') == 2
        S = load(cfgPath);
        if isfield(S,'metaLast'), metaLast = S.metaLast; end
    end
catch
end

conditionsList = conds; %#ok<NASGU>
try
    if ~isempty(metaLast)
        save(cfgPath, 'conditionsList', 'metaLast');
    else
        save(cfgPath, 'conditionsList');
    end
catch ME
    warning('Could not save conditions list: %s', ME.message);
end
end