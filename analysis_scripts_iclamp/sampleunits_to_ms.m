function convertedVal = sampleunits_to_ms(si, sampleunits)

%converts a value given in sample units to miliseconds in
%electrophysiological recording

%si = sampling interval extracted from the abf file in us.
% sampleunits = the value in sample units to convert.

% original script by: Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: AUg 28 2023

samplinginterval = si * 0.001; %convert sampling interval from us to miliseconds. this is the no. of miliseconds per 1 sample unit.

convertedVal = samplinginterval * sampleunits; %value in units of miliseconds

end