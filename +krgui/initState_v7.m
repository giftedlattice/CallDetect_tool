function app = initState_v7(sig, fs, opts, meta)
%INITSTATE_V7 Initialize analysis + detection + candidate pool. No UI here.

rear  = sig(:,1);
Nsamp = size(sig,1);

% Rear-only bandpass for detection envelope
xBP = kr.bandpass3(rear, fs, opts.bpHz);

% Envelope in amplitude (Hilbert) + smoothing
env = abs(hilbert(xBP));
env = movmean(env, max(1, round((opts.envSmooth_ms/1000)*fs)));
env_dB = 20*log10(env + eps);

% Robust noise floor in dB (used as reference)
noiseFloor_dB = median(env_dB);

% Initial detection ONCE (defines candidate bounds)
thr0 = opts.initThrAboveNoise_dB;
[cOn, cOff] = kr.detectCalls_dB(env_dB, fs, noiseFloor_dB, thr0, opts);
[cOn, cOff] = krgui.scrubBounds_v7(cOn, cOff, Nsamp);

% Optional: refine bounds to main burst to trim echoes
if isfield(opts,'boundRefine_enable') && opts.boundRefine_enable && ~isempty(cOn)
    for k = 1:numel(cOn)
        [cOn(k), cOff(k)] = krgui.refineBoundsMainBurst_v7(env_dB, fs, cOn(k), cOff(k), opts);
    end
    [cOn, cOff] = krgui.scrubBounds_v7(cOn, cOff, Nsamp);
end

% State
state = struct();
state.thrAboveNoise_dB = thr0;

% Candidate pool (fixed length unless Add)
state.calls_on_fixed  = cOn;
state.calls_off_fixed = cOff;

% Manual override per candidate
state.manualKeep_fixed = false(numel(cOn),1);

% Auto keep mask at current threshold
state.autoKeep_fixed = krgui.computeAutoKeepMask_v7(env_dB, noiseFloor_dB, thr0, cOn, cOff);

% Working list (only kept)
[state.calls_on, state.calls_off, state.dispToFixed] = krgui.applyFilter_v7(state);

% GUI interaction state
state.selectedIdx = min(1, max(1, numel(state.calls_on)));
state.mode = "none";
state.accepted = false;

% App container
app = struct();
app.sig = sig;
app.fs = fs;
app.opts = opts;
app.meta = meta;              % <-- NEW: stored for export-preview table
app.rear = rear;
app.env_dB = env_dB;
app.noiseFloor_dB = noiseFloor_dB;
app.Nsamp = Nsamp;
app.state = state;

end