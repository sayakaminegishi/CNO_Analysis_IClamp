
clf
filename = '2023_06_06_01_0003.abf';
[dataallsweeps, si, h] =abf2load(filename); %loads the abf file of interest
   
cleandata = clean_trace(filename); %get rid of initial transient spike - analyze properties from transient separately

dV_thresh = 3;
sweepofinterest = 4; %the sweep that we want to examine
data = cleandata(sweepofinterest, :); %load sweep data. this is the trace for sweep

all_dV = find(diff(data) > dV_thresh);  %list of locations at which slope > threshold
threshold_value = data(all_dV(1)); %for AP detection
allSpikeTimes = get_spikelocations(data); %WORKS
int_sp_intv = find_isi(allSpikeTimes); %get an array of interspike intervals for the sweep


%plot isi histogram
isi_hist = get_isi_histogram(int_sp_intv, 15);

%plot log(ISI) histogram
log_isi_hist = get_log_isi_histogram(int_sp_intv, 15);
avgSpikesPerBurst = get_SpikesPerBurst(log_isi_hist); %average number of spikes per burst. TODO: check wehther this is accurate


% %get threshold for burst detection
ln_ISI_thresh = get_logISI_threshold(log_isi_hist);
 
% convert lnISI threshold to ISI threshold, in units of samples (TODO: multiply by
% time interval per sample unit to get thresh isi in ms)

ISI_thresh = exp(ln_ISI_thresh);
 
%find matrix containing burst start and end locations (INCLUDES SINGLET AP)
burstTimesMatrix = find_burstMatrix(int_sp_intv, allSpikeTimes, ISI_thresh);
display(burstTimesMatrix);

% CORRECTED burst times and singlet AP times (measured as location of peak)
[singleAP_SpikeTimes, burstTimesMatrix] = refined_burstMatrix(burstTimesMatrix, data, threshold_value, allSpikeTimes)

%plot corrected burst times and singlet AP times
clf
plot(data)
hold on
plot(burstTimesMatrix(:,1), data(burstTimesMatrix(:,1)), 'r*')
plot(burstTimesMatrix(:,2), data(burstTimesMatrix(:,2)), 'rdiamond')
plot(singleAP_SpikeTimes, data(singleAP_SpikeTimes), 'ko')
legend({'Data', 'Burst Start Times','Burst End Times', 'Single APs'}, 'FontSize', 5, 'Location', 'southeast')
hold off


% % plot start and end times of UNCORRECTED bursts 
% clf
% plot(data)
% hold on
% plot(burstTimesMatrix(:,1), data(burstTimesMatrix(:,1)), 'r*')
% plot(burstTimesMatrix(:,2), data(burstTimesMatrix(:,2)), 'rdiamond')
% legend({'Data', 'Burst Start Times','Burst End Times'}, 'FontSize', 5, 'Location', 'southeast')
% hold off
% 


%Burst statistics: mean burst duration, burst frequency (no. of bursts per
%ms)

%frequency of bursts
burst_frequency = get_burst_frequency(burstTimesMatrix, data)

%average burst duration
avgduration = get_mean_burst_duration(burstTimesMatrix)




% Calculate totel area under the curve, but above baseline + 10mV line
baseline = data(1) + 10; 
y = data - baseline;

areaUnderCurve = trapz(y - baseline); %in samples*mV
areaUnderCurve = sampleunits_to_ms(si,areaUnderCurve); %convert to ms*mV
display(areaUnderCurve) 




%TODO: convert from sample units to ms






% [numberOfSpikes, spikeTimes] = spike_times3(data,threshold_value); %gives the number of spikes and the time locations of spikes
% display(numberOfSpikes)
% display(spikeTimes)
% 
% %for loop with a, the sweepnumber:
% totalsweeps = size(cleandata, 2); %total number of sweeps in the file
% 
% 
% %%%%%%%%%%
% 
% [singleAPTimes, first_peak_burst, burst_times_matrix] = list_APs_in_sweep(data,dV_thresh );
% 
% 
% 
% hold on
% plot(singleAPTimes, data(singleAPTimes), 'kdiamond'); %plot singlet APs as black diamonds
% plot(first_peak_burst, data(first_peak_burst), 'k+'); %plot first spike of a burst in black +
% %TODO: connect start and end points of each burst in burst_times_matrix.
% 
% %%%%%%%%%%%%%%%
% %get summary of AP properties of singlet AP spikes in this particular trace
% sweep_summary_row = analyze_singleAPs2(data, sweepofinterest, singleAPTimes, dV_thresh);
% display(sweep_summary_row);


% %%%%%%%%%
% %TESTING get_spikelocations.m
% % x = numel(data);
% % % [pks,locs] = findpeaks(data,1:x); %find peaks
% % % display(pks)
% % % display(locs)
% % % 
% % % plot(data) 
% % % hold on
% % % plot(locs, pks, "r*");
% % clf
% % 
% % spike_threshold_val = data(1) + 10;
% % [pks,locs] = findpeaks(data,'MinPeakHeight', spike_threshold_val); %find peak values and their locations
% % plot(data) 
% % hold on
% % plot(locs, pks, "r*")
% % plot(1:x, data(1), 'g') %plot a green line indicating the baseline
% % plot(1:x, spike_threshold_val, 'k'); %draw a black line indicating the spike threshold (includes both APs and bursts)
% 
% 
% % 
% %%testing analyze_singleAPs2.m
% % [singleAPTimes, first_peak_burst, burst_times_matrix] = classify_spikes(data,dV_thresh);
% % 
% % summaryRow = analyze_singleAPs2(data, sweepofinterest, singleAPTimes,dV_thresh);
% % display(summaryRow)
% 
% 
% display(allSpikeTimes)
% plot(data)
% hold on
% plot(allSpikeTimes, data(allSpikeTimes), 'r*');
% 
% %%% test classify_spikes function
% [true_single_list, burst_single_list, burst_burst_list, burst_times_matrix] = classify_spikes(data,dV_thresh);
% display(true_single_list)
% display(burst_single_list)
% display(burst_burst_list)
% display(burst_times_matrix)
% 
% %%%%%%%
% plot(data)
% hold on
% plot(530, data(530), 'kdiamond')
% plot(786, data(786), 'rdiamond')
% plot(7768, data(7768), 'rdiamond')
% plot(9398, data(9398), 'kdiamond')
% 
% 
% % the scripts seems to be working. next step is to extract the waveform of
% % the first spike and the last spike in each burst, and the waveform of
% % each AP in trace.
% threshspike = 10+data(1);
% [firstspike, spikestart, spikeend] = find_waveform(data, burst_times_matrix(1,2), allSpikeTimes, threshspike);
% display(allSpikeTimes);
% 
% %if findwaveform returns firstspike = empty, then don't count it as a spike
% %<- where should I do that?
% 
% display(firstspike);
% clf
% 
% plot(data, 'Color', 'blue')
% hold on
% plot(spikestart:spikeend, firstspike, 'Color', 'red')
% %plot(range(spikestart:spikeend), firstspike, 'Color', 'red')
% plot(spikestart, data(spikestart), 'rdiamond')
% plot(spikeend, data(spikeend), 'r*')
% plot(allSpikeTimes, data(allSpikeTimes), 'kdiamond')

% spikelocations = get_spikelocations(data);
% plot(data)
% hold on
% plot(spikelocations, data(spikelocations), 'k*')
