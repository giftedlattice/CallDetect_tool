function amps = feature_peakAmpsAtPeakFreq_v7(segR, segL, segRR, fs, opts, fPeak_kHz)
%FEATURE_PEAKAMPSATPEAKFREQ_V7 PSD value at rear peak frequency for each channel.

harmBand_Hz = opts.harmBand_kHz * 1000;

amps = struct();
amps.rear  = kr.ampAtFreqFromPSD(segR,  fs, harmBand_Hz, fPeak_kHz);
amps.left  = kr.ampAtFreqFromPSD(segL,  fs, harmBand_Hz, fPeak_kHz);
amps.right = kr.ampAtFreqFromPSD(segRR, fs, harmBand_Hz, fPeak_kHz);
end