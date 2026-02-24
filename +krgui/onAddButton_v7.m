function onAddButton_v7(mainFig)
app = guidata(mainFig);

% Arm one-shot add mode
app.state.mode = "add_once";
guidata(mainFig, app);

% Optional: give the user a cue in the status text
try
    app.txtSel.String = "Add armed: click the OVERVIEW plot at the call peak.";
    guidata(mainFig, app);
catch
end
end