function saveLastMeta_v7(meta)
%SAVELASTMETA_V7 Save meta to disk as metaLast.
cfgPath = krgui.metaConfigPath_v7();
metaLast = meta; %#ok<NASGU>
try
    save(cfgPath, 'metaLast');
catch ME
    warning('Could not save last meta config: %s', ME.message);
end
end