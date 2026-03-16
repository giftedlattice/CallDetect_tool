function KR_viewCallFromDB_v1()
%KR_viewCallFromDB_v1 Standalone viewer:
% - Asks for a call_id (from SQLite DB)
% - Loads the source MAT
% - Plots a spectrogram view around the call with on/off bounds
%
% Assumptions:
% - DB file "KR_callDetectTool_v7.sqlite" lives in the same folder as this file (or you can browse to it)
% - trials.source_mat stored in DB is a valid path on this machine
% - MAT file contains variable "sig" (Nx1/Nx2/Nx3) and optional "fs"
%
% If you want different spectrogram settings, edit the opts section below.

clc;

% -----------------------------
% Locate DB
% -----------------------------
toolRoot = fileparts(mfilename('fullpath'));
defaultDb = fullfile(toolRoot, "Bats.sqlite");

if exist(defaultDb, 'file') ~= 2
    [f,p] = uigetfile('*.sqlite', 'Select Bats.sqlite');
    if isequal(f,0), return; end
    dbPath = fullfile(p,f);
else
    dbPath = defaultDb;
end

% -----------------------------
% Ask for call_id
% -----------------------------
answ = inputdlg({'Enter call_id (integer):'}, 'View Call From DB', [1 45], {''});
if isempty(answ), return; end
call_id = str2double(strtrim(answ{1}));
if ~isfinite(call_id) || call_id < 1 || floor(call_id) ~= call_id
    errordlg('call_id must be a positive integer.', 'Invalid input');
    return;
end

% -----------------------------
% Query DB for call + trial info
% -----------------------------
conn = sqlite(char(dbPath), 'connect');

% Verify tables exist quickly
tbls = fetch(conn, 'SELECT name FROM sqlite_master WHERE type="table";');
if istable(tbls)
    names = string(tbls{:,1});
else
    names = string(tbls(:,1));
end
need = ["calls","trials"];
if ~all(ismember(need, names))
    close(conn);
    errordlg('DB missing required tables (calls/trials).', 'DB schema error');
    return;
end

sql = [ ...
    'SELECT c.call_id, c.trial_id, c.call_number, c.on_samp, c.off_samp, ' ...
    't.fs_hz, t.source_mat, t.bat_id, t."date", t."trial", t.condition ' ...
    'FROM calls c JOIN trials t ON c.trial_id = t.trial_id ' ...
    'WHERE c.call_id = ' num2str(call_id) ';' ];

res = fetch(conn, sql);
close(conn);

if isempty(res) || (istable(res) && height(res)==0)
    errordlg(sprintf('No call_id=%d found in DB.', call_id), 'Not found');
    return;
end

% Handle table vs cell return types
if istable(res)
    row = res(1,:);
    trial_id     = row.trial_id;
    call_number  = row.call_number;
    on_samp      = row.on_samp;
    off_samp     = row.off_samp;
    fs_db        = row.fs_hz;
    source_mat   = string(row.source_mat);
    dateStr      = string(row.date);
    trialStr     = string(row.trial);
    condStr      = string(row.condition);
else
    % cell
    trial_id     = res{1,2};
    call_number  = res{1,3};
    on_samp      = res{1,4};
    off_samp     = res{1,5};
    fs_db        = res{1,6};
    source_mat   = string(res{1,7});
    dateStr      = string(res{1,9});
    trialStr     = string(res{1,10});
    condStr      = string(res{1,11});
end

% Convert numeric-ish
trial_id    = double(trial_id);
call_number = double(call_number);
on_samp     = double(on_samp);
off_samp    = double(off_samp);
fs_db       = double(fs_db);

if source_mat == "" || exist(source_mat, 'file') ~= 2
    [f,p] = uigetfile('*.mat', sprintf('MAT not found. Select source MAT for call_id=%d', call_id));
    if isequal(f,0), return; end
    source_mat = string(fullfile(p,f));
end

% -----------------------------
% Load MAT
% -----------------------------
S = load(source_mat);

if ~isfield(S,'sig')
    errordlg('Selected MAT does not contain variable "sig".', 'Bad MAT file');
    return;
end

sig = normalizeSigTo3ch_local(S.sig); % rear,left,right (NaNs for missing)

fs = fs_db;
if isfield(S,'fs') && ~isempty(S.fs)
    fs = double(S.fs);
end
if ~isfinite(fs) || fs <= 0
    errordlg('Invalid fs in DB/MAT.', 'Bad sample rate');
    return;
end

Nsamp = size(sig,1);
on_samp  = max(1, min(Nsamp, round(on_samp)));
off_samp = max(1, min(Nsamp, round(off_samp)));
if off_samp < on_samp
    tmp = on_samp; on_samp = off_samp; off_samp = tmp;
end

rear = sig(:,1);

% -----------------------------
% Viewer opts (edit freely)
% -----------------------------
opts = struct();
opts.harmBand_kHz = [20 70];  % display band
opts.contextHalfWin_s = 0.200; % +/- 200 ms around call center
opts.specWin  = 256;
opts.specOvl  = 192;
opts.specNfft = 512;

% Context window around call center
center = round((on_samp + off_samp)/2);
ctxHalf = round(opts.contextHalfWin_s * fs);
a = max(1, center - ctxHalf);
b = min(Nsamp, center + ctxHalf);
x = rear(a:b);

t0 = (a-1)/fs;
t_on  = (on_samp-1)/fs;
t_off = (off_samp-1)/fs;

% -----------------------------
% Plot
% -----------------------------
fig = figure('Color','w','Name',sprintf('call_id=%d (trial_id=%d)', call_id, trial_id));
ax = axes('Parent',fig);

[Sx,F,Tt] = spectrogram(double(x), opts.specWin, opts.specOvl, opts.specNfft, fs, 'yaxis');
SdB = 20*log10(abs(Sx)+eps);
FkHz = F/1000;

imagesc(ax, Tt + t0, FkHz, SdB);
axis(ax,'xy');
ylim(ax, opts.harmBand_kHz);
xlabel(ax,'Time (s)');
ylabel(ax,'Frequency (kHz)');
title(ax, sprintf('call_id=%d | trial_id=%d | call#=%d | %s trial=%s | %s', ...
    call_id, trial_id, call_number, dateStr, trialStr, condStr), 'Interpreter','none');

% Contrast stretch
v1 = prctile(SdB(:), 10);
v2 = prctile(SdB(:), 99);
if isfinite(v1) && isfinite(v2) && v2 > v1
    caxis(ax, [v1 v2]);
end

hold(ax,'on');
xline(ax, t_on,  '--', 'LineWidth', 2);
xline(ax, t_off, '--', 'LineWidth', 2);
hold(ax,'off');

% Optional: show a waveform panel too
fig2 = figure('Color','w','Name',sprintf('Waveform call_id=%d', call_id));
ax2 = axes('Parent',fig2);
tt = (a:b)/fs;
plot(ax2, tt, x, 'k');
hold(ax2,'on');
xline(ax2, t_on,  '--', 'LineWidth', 2);
xline(ax2, t_off, '--', 'LineWidth', 2);
xlim(ax2, [tt(1) tt(end)]);
xlabel(ax2,'Time (s)');
ylabel(ax2,'Amplitude');
title(ax2, sprintf('Rear waveform | call_id=%d', call_id));
hold(ax2,'off');

end

% =========================
% Local helper: normalize sig to Nx3
% =========================
function sig3 = normalizeSigTo3ch_local(sigIn)
sigIn = double(sigIn);
if isvector(sigIn)
    sigIn = sigIn(:);
end
N = size(sigIn,1);
switch size(sigIn,2)
    case 1
        sig3 = [sigIn, nan(N,1), nan(N,1)];
    case 2
        sig3 = [sigIn(:,1), sigIn(:,2), nan(N,1)];
    case 3
        sig3 = sigIn;
    otherwise
        error('sig must be Nsamp x 1, 2, or 3.');
end
end
