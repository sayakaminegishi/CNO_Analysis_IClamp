
% this function takes in a trace of interest (i.e. abf file defined by its filename) and the threshold slope at which a spike should be detected, identifies all bursts, and
% returns an array containing the waveforms of each burst (so waveform as
% an array of membrane potential values, stored in a larger array that
% would serve as the collection of such waveforms).  Trace is the waveform
% of the entire continuous sweep that we're trying to analyze. It should be
% a collection of all the membrane potential values.
% 
% The array containing the
% bursts can then be analyzed in another script to get the properties of
% each burst and summarize the info in a table. 

%the abf file must be recorded in current-clamp mode.


% Created by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: 18 August 2023


%a burst = 2 or more spikes identified within the time w from the threshold
%of first spike, where w = average duration of an AP (from start of
%threshold to end of spike).

function bursts_list = identifybursts2(trace_name, threshold_slope)

  
    %start loading files
    bursts_list = []; %create an empty list to store the waveforms of the bursts in the trace

    %burst_array = []; %stores the waveform of a single burst
    %filenameExcelDoc = strcat('AP_properties_filteredContinuous_AUG16.xlsx');
    
    
    idx = 1; %keeps track of the spikes that actually count as AP, per the amplitude rule
        
    filename = trace_name; %file to work on
    disp([int2str(n) '. Working on: ' filename{:}])
       
    dataallsweeps=abf2load(filename{:}); %loads the abf file of interest
   
    %combine the sweeps to a single sweep. store as dataallwsweeps
    data = combine_sweeps(dataallsweeps);
   
    
    numpointspersweep = size(data); %size of first column, which is the total no. of points per sweep in this ABF file
  
    numspikes = 0;
    dV_thresh = threshold_slope; %THRESHOLD SLOPE
    w = 433; %average duration of an AP, from start of threshold to end
   
    waveform = zeros(1,numpointspersweep); % define waveform for this particular sweep. 1 row, numpointspersweep columns.
    all_dV=zeros(1, numpointspersweep);  %identifies all start pts of action potentials (i.e. when voltage starts to rise. not the peaks themselves).
   
    restingpotential = data(1); %resting potential. used for calculating AHP troughs
     
    
     %find all the points (indices) in this sweep where AP is detected.
    
     all_dV = find(diff(data) > dV_thresh);  %list of locations at which slope > threshold
    
     if numel(all_dV) > 0
         waveform = data(all_dV(1):all_dV(1) + 100)';
     else
         waveform = zeros(1,101);
     end
    
    
     if (numel(all_dV) ~= 0) 
      
        threshold_value = data(all_dV(1)); 


        [numberOfSpikes, spikeTimes] = spike_times2(data,threshold_value);

        %identify whether a spike is a part of burst
        firstspike = spikeTimes(1); %location of first spike
        burst = zeros(1); %waveform of a particular burst

        %TODO: identify APs in this sweep, and analyze if they are a part
        %of a burst.
        for n = 2:numberOfSpikes
           
                burst = burst + data(spikeTimes(n-1):spikeTimes(n)); %waveform of a burst






        %analyzing each spike, and storing their properties in appropriate
        %array so that kth entry in a properties array would be for kth
        %spike. SO MAKE SURE ALL THE PROPERTIES ARE STORED IN AN ARRAY OF
        %SIZE numel(spiketimes_t)!!!!

        % idx_c = 0; %indexes for spikes that count as an AP
        indexestocount = zeros(1);

        for k = 1:numel(spiketimes_t)
            %note: test_spike represents the spike of interest here. 
            if numel(spiketimes_t) == k
                test_spike = data(spiketimes_t(k):numpointspersweep); %if there's only one spike, use the whole trace starting from that point
            else
                test_spike = data(spiketimes_t(k):spiketimes_t(k+1)); %if there are multiple spikes, AP of interest is the one between 2 consecutive spikes
                
            end
        
            %amplitude of spike and AHP
            amplitude(k) = max(test_spike) - test_spike(1); 
            AHP_amp(k) = test_spike(1) - min(test_spike); 
            
            

            % if AHP_amp(k) <= 0
            %     indexestocount(idx_c) = k; %don't count spike as AP if ahp amplitude is less than or equal to 0
            %     idx_c = idx_c+1;
            % end

         

            minpoint = find(test_spike == min(test_spike)); %minimum point of this particular AP in the sweep
            minpoint = minpoint(1);
            minpoint_val = test_spike(minpoint);

            %find the time of the max point in test_spike
            maxpoint = find(test_spike == max(test_spike));
            maxpoint = maxpoint(1);
            maxpoint_val = test_spike(maxpoint);

            

            % AHP properties for the spike
            AHP_10(k) = min(test_spike) + (AHP_amp(k) * 0.9); %100-30 value
            AHP_30(k) = min(test_spike) + (AHP_amp(k) * 0.7); %100-30
            AHP_90(k) = min(test_spike) + (AHP_amp(k) * 0.1); %100-90
            AHP_70(k) = min(test_spike) + (AHP_amp(k) * 0.3); %100-70
            AHP_50(k) = min(test_spike) + (AHP_amp(k) * 0.5); %100-70

            [~, ind_10_rise(k)] = min(abs(test_spike(minpoint:end)-AHP_10(k))); %find the pt in the range (minpoint:end) where distance between value of test_spike at that point and AHP_10 value is the lowest. this finds the closest point to AHP_10.
            [~, ind_30_rise(k)] = min(abs(test_spike(minpoint:end)-AHP_30(k)));
            [~, ind_90_rise(k)] = min(abs(test_spike(minpoint:end)-AHP_90(k)));
            [~, ind_70_rise(k)] = min(abs(test_spike(minpoint:end)-AHP_70(k)));
            [~, ind_50_rise(k)] = min(abs(test_spike(minpoint:end)-AHP_50(k)));
        
            [~, ind_10_dec(k)] = min(abs(test_spike(1:minpoint)-AHP_10(k)));
            [~, ind_30_dec(k)] = min(abs(test_spike(1:minpoint)-AHP_30(k)));
            [~, ind_90_dec(k)] = min(abs(test_spike(1:minpoint)-AHP_90(k)));
            [~, ind_70_dec(k)] = min(abs(test_spike(1:minpoint)-AHP_70(k)));
            [~, ind_50_dec(k)] = min(abs(test_spike(1:minpoint)-AHP_50(k)));  
    
            AHP_decay_10to10(k) = ind_10_rise(k) -ind_10_dec(k);%calculate AHP 10-10% time
            AHP_decay_30to30(k) = ind_30_rise(k)-ind_30_dec(k); %calculate AHP 30-30% time
            AHP_decay_70to70(k) = ind_70_rise(k) - ind_70_dec(k); %calculate AHP 70-70% time
            AHP_decay_90to90(k) = ind_90_rise(k) -ind_90_dec(k);%calculate AHP 90-90% time
            interp_hw_AHP(k) = ind_50_rise(k) - ind_50_dec(k);
        
       
            %%%%%%%% AP properties %%%%%%%%%%%%%%%%%%%%%%%%%%%%


             % HALF WIDTH OF AP
             AP_50(k) = max(test_spike) - (amplitude(k) * 0.5); %50% AP
   
            [~, AP_50_rise(k)] = min(abs(test_spike(1:minpoint)-AP_50(k)));
            [~, AP_50_dec(k)] = min(abs(test_spike(minpoint:end)-AP_50(k)));
            interp_hw_AP(k) = AP_50_dec(k) - AP_50_rise(k);

    
            minpoint_in_trace_candidates = find(data == test_spike(minpoint) );
            minpoint_in_trace(k) = minpoint_in_trace_candidates(1);
            maxpoint_in_trace_candidates =  find(data == test_spike(maxpoint) );
            maxpoint_in_trace(k) = maxpoint_in_trace_candidates(1);

            minpoint_values(k) = minpoint_val;
            maxpoint_values(k) = maxpoint_val;

            numspikes = numel(spiketimes_t);


        %count the spike as an AP only if it meets the amplitude and AHP
        %amplitude requirements

        if amplitude(k) >= 40 & AHP_amp(k) >=20
            amplitude_final(idx) = amplitude(k);
            AHP_amp_final(idx) = AHP_amp(k);
            minpoint_val_f(idx) = minpoint_values(k);
            maxpoint_val_f(idx) = maxpoint_values(k);
            interp_hw_AP_f(idx) = interp_hw_AP(k);
            AHP_30_f(idx) = AHP_30(k);

            AHP_50_f(idx) = AHP_50(k);
            AHP_70_f(idx) = AHP_70(k);
            AHP_90_f(idx) = AHP_90(k);
            interp_hw_AHP_f(idx) = interp_hw_AHP(k);
            AHP_decay_10to10_f(idx) = AHP_decay_10to10(k);
            AHP_decay_30to30_f(idx) = AHP_decay_30to30(k);
            AHP_decay_70to70_f(idx) = AHP_decay_70to70(k);
            AHP_decay_90to90_f(idx) = AHP_decay_90to90(k);


            idx = idx+1;
    
        end

        
        end

        if idx >1 
            multipleVariablesRow= [filename, numel(amplitude_final), threshold_value, mean(amplitude_final), mean(AHP_amp_final), mean(minpoint_val_f), mean(maxpoint_val_f), mean(interp_hw_AP_f), mean(AHP_30_f), mean(AHP_50_f), mean(AHP_70_f), mean(AHP_90_f), mean(interp_hw_AHP_f), mean(AHP_decay_10to10_f), mean(AHP_decay_30to30_f), mean(AHP_decay_70to70_f), mean(AHP_decay_90to90_f)];
            M= array2table(multipleVariablesRow, 'VariableNames', myVarnames);  
            T = [T; M];
        end
    
end



end
display(T)
writetable(T, filenameExcelDoc, 'Sheet', 1); %export summary table to excel
end

