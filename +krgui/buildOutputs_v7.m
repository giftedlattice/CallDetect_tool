function [calls, detInfo] = buildOutputs_v7(app)
calls = struct([]);
detInfo = struct('accepted',false);

if ~isfield(app,'state') || ~isfield(app.state,'accepted') || ~app.state.accepted
    return;
end

onK  = app.state.calls_on(:);
offK = app.state.calls_off(:);

for k = 1:numel(onK)
    calls(k).on_samp  = onK(k);
    calls(k).off_samp = offK(k);
end

detInfo.accepted = true;
detInfo.thrAboveNoise_dB = app.state.thrAboveNoise_dB;
detInfo.noiseFloor_dB = app.noiseFloor_dB;
detInfo.n_candidates = numel(app.state.calls_on_fixed);
detInfo.n_kept = numel(app.state.calls_on);
end