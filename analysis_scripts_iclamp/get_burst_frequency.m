function burst_frequency = get_burst_frequency(burstTimesMatrix)

% calculates burst frequency for the sweep, in bursts/unit sample time.
% calculated by number of bursts / no. of samples between peak time of
% initial spike in burst and peak time of final spike in burst.

% original script by: Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: Aug 27 2023

lengthBurst = burstTimesMatrix(end,2) - burstTimesMatrix(1,1);
burst_frequency = size(burstTimesMatrix,1)/lengthBurst;

end