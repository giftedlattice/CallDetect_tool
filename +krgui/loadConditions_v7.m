function conds = loadConditions_v7(defaultList)
%LOADCONDITIONS_V7 Load saved condition list from config file.
% Returns string array.

if nargin < 1 || isempty(defaultList)
    defaultList = [""]; % allow blank
end

conds = string(defaultList);
cfgPath = krgui.metaConfigPath_v7();

if exist(cfgPath,'file') ~= 2
    return;
end

try
    S = load(cfgPath, 'conditionsList');
    if isfield(S,'conditionsList')
        c = string(S.conditionsList);
        if ~isempty(c)
            conds = unique(c(:), 'stable');
        end
    end
catch
    % ignore
end

% ensure at least one entry
if isempty(conds)
    conds = string(defaultList);
end
end