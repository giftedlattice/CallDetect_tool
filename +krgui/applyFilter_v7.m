function [onW, offW, dispToFixed] = applyFilter_v7(state)
keepMask = state.autoKeep_fixed(:) | state.manualKeep_fixed(:);
dispToFixed = find(keepMask);
onW  = state.calls_on_fixed(keepMask);
offW = state.calls_off_fixed(keepMask);
end