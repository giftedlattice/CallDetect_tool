function roi = clearROIs(roi)
%CLEARROIS Delete existing ROI objects/listeners (if any) and return a clean struct.

if nargin == 0 || isempty(roi)
    roi = struct('on',[],'off',[],'lisOn',[],'lisOff',[]);
    return;
end

% delete listeners
try
    if isfield(roi,'lisOn') && ~isempty(roi.lisOn),  delete(roi.lisOn);  end
    if isfield(roi,'lisOff')&& ~isempty(roi.lisOff), delete(roi.lisOff); end
catch
end

% delete ROI graphics
try
    if isfield(roi,'on') && ~isempty(roi.on) && isvalid(roi.on),   delete(roi.on);  end
    if isfield(roi,'off')&& ~isempty(roi.off)&& isvalid(roi.off),  delete(roi.off); end
catch
end

roi = struct('on',[],'off',[],'lisOn',[],'lisOff',[]);
end