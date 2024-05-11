%this script analyzes the properties of individual bursts in 
%electrophysiological recordings (abf files) and summarizes the information in a table,
%which would be exported as an excel file. Each row of the table
%corresponds to a separate cell recorded in spontaneous mode (i.e. no
%stimulus). Each row considers data from all the sweeps combined.

%features that will be identified/analyzed: frequency of bursts for each cell (sum of freq. of bursts for all sweeps),
%total area under the bursts for each cell, mean duration of bursts, mean
%time interval between the end of a previous burst and the start of the
%next burst, average amplitude and average half-width of spikes in a burst.





% todo: crestr matrix contsining ap spiketitmes only for ones in buryts
% (i.e. everythting in identified spikess minus the singles) in another
% function file

