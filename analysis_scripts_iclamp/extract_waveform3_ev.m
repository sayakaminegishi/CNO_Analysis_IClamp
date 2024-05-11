function [spikeWaveform,starttime,endtime] = extract_waveform3_ev(risingDuration,fallingDuration, mainpeakloc, data)
%gets the waveform of a spike given the peak point. rising and falling
%durations must be determined by findWaveform.m
starttime = mainpeakloc - risingDuration;
endtime = mainpeakloc + fallingDuration;
spikeWaveform = data(starttime:endtime);
end