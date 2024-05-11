function sampleunits = ms_to_sampleunits(si, sample_in_ms)

%converts a value given in ms to sample units (to nearest integer) in
%electrophysiological recording

%si = sampling interval extracted from the abf file in us.
% sample_in_ms = the value in sample units to convert.

% original script by: Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: Nov 23 2023

samplinginterval = si * 0.001; %convert sampling interval from us to miliseconds. this is the no. of miliseconds per 1 sample unit.

sampleunits = 1/samplinginterval * sample_in_ms; %value in units of miliseconds
sampleunits = round(sampleunits);
end