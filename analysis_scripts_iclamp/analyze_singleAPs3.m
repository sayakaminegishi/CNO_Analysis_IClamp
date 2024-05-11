function summaryRow = analyze_singleAPs3(sweep_data, sweep_number, singleAPTimes, thresh_slope) 
% function to identify the beginning and end time of a single action potential (i.e. not part of a
% burst) in a continuous recording for A PARTICULAR SWEEP.

%inputs: sweep_data = continuous electrophysiology recording data for this sweep with the
%transient spike at the beginning of the sweep removed.
% singleAPTimes = an array containing the peak times of
% all action potentials identified as a singlet in list_APs_in_sweep.m function.
%thresh_slope = minimum dV/dt between 2 pts for ap detection.
%sweep_number = sweep number in the entire recording.


%output: a table ROW with averaged summary of singlet AP properties in this
%particular sweep. %TODO: add these rows from all the sweeps together to
%create the final summary table for singlet AP properties of this
%recording.

%NOTE: this function is meant to be used after running list_APs2.m, but
%single_AP_matrix data can also be created manually.

% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: August 22 2023

myVarnames = {'sweep_number', 'total_AP_count', 'avg_amplitude','avg_AHP_amp', 'avg_minvalue','avg_maxvalue','avg_AHP_decay_10to10','avg_AHP_decay_30to30','avg_AHP_decay_70to70','avg_AHP_decay_90to90','avg_interp_hw_AHP','avg_AP_50','avg_interp_hw_AP'};

numpointspersweep = numel(sweep_data); %number of data pts per sweep

%function runs even if singleAPTimes is empty
if numel(singleAPTimes) ~= 0
 
    %initialize variables
    total_amplitude = []; %total_amplitude is a matrix that contains all the amplitudes of single APs from this particlar sweep
    total_AHP_amp = [];
    total_minvalue = [];
    total_maxvalue = [];
    total_AHP_decay_10to10 = [];
    total_AHP_decay_30to30= [];
    total_AHP_decay_70to70= [];
    total_AHP_decay_90to90= [];
    total_interp_hw_AHP = [];
    total_AP_50 = [];
    total_interp_hw_AP = [];
    avg_amplitude = 0;
    avg_AHP_amp = 0;
    avg_minvalue = 0;
    avg_maxvalue=0;
    avg_AHP_decay_10to10 =0;
    avg_AHP_decay_30to30 = 0;
    avg_AHP_decay_70to70 = 0;
    avg_AHP_decay_90to90 = 0;
    avg_interp_hw_AHP = 0;
    avg_AP_50 = 0;
    avg_interp_hw_AP = 0;
    
    apcount = 0;
    data = sweep_data; %data = waveform of sweep data
    single_APs_in_sweep = singleAPTimes; %get a list of the single AP peak times in that particular sweep
    
    all_dV = find(diff(data) > thresh_slope);  %list of locations at which slope > threshold
    
    threshold_value = data(all_dV(1)); %threshold membrane potential value
    
    all_spiketimes = get_spikelocations(data); %list of all spike locations in data
    
    waveform = zeros(1,numpointspersweep); % define waveform for this particular sweep. 1 row, numpointspersweep columns.

    
    restingpotential = data(1); %assuming 1st point is the baseline
    
    
    
    %identify the waveform for each AP in single_APs_in_sweep
    for k = 1:numel(single_APs_in_sweep)
        %initialize all the local variables
        AHP_10 = 0;
        AHP_30 = 0;
        AHP_90 = 0; %100-90
        AHP_70 = 0; %100-70
        AHP_50 = 0;
        ind_10_rise = 0;
        ind_30_rise = 0;
        ind_90_rise = 0;
        ind_70_rise = 0;
        ind_50_rise = 0;
        ind_10_dec = 0;
        ind_30_dec = 0;
        ind_70_dec = 0;
        ind_90_dec = 0;
        ind_50_dec = 0;
    
        AHP_decay_10to10 = 0;
        AHP_decay_30to30 = 0; 
        AHP_decay_70to70 = 0;
        AHP_decay_90to90 = 0;
        interp_hw_AHP = 0;
        AP_50 = 0;
        AP_50_rise = 0;
        AP_50_dec = 0;
        interp_hw_AP = 0;
    
        %countasap = 0; %count this spike as an AP if 0, don't count it if 1.
        nextspikeloc = 0;
    
        if numel(all_dV) > 0
            waveform = data(all_dV(1):all_dV(1) + 100)';
        else
            waveform = zeros(1,101);
        end
    
        peaktime_AP = single_APs_in_sweep(k); %peak time of kth single AP in sweep a
        
        %1+last time pt in data before crossing threshold value for the 1st time
        indicestosearch = 1:peaktime_AP;
    
        lastlocbeforethresh_list = find(data(indicestosearch) == threshold_value);
        lastlocbeforethresh = lastlocbeforethresh_list(end); %last element before threshold location
        spikestart_loc = lastlocbeforethresh + 1; %start location of spike
        
        %find time when this spike hyperpolarizes back to the threshold potential
        backatrest_loc = peaktime_AP - spikestart_loc; %assuming rising time is the same as falling time
    
        %find the first data pt after the peak time where the curve crosses
        %threshold, and slope is rising.
    
        breakloop = 0;
        for j=1:numel(all_spiketimes)
            if(all_spiketimes(j) == peaktime_AP) & breakloop == 0
                nextspikeloc = all_spiketimes(j+1); %find location of next peak in data
                breakloop = 1;
            end
        end
    
        searchindex = backatrest_loc+1:nextspikeloc; 

        [~,lastbeforenext] = min(abs(sweep_data(searchindex)- threshold_value)); %last time point before the peak of next spike, where threshold is reached
        spikeend_loc = lastbeforenext + backatrest_loc;

        if(numel(spikeend_loc) == 0)
            spikeend_loc = numpointspersweep; %if the spike is the final spike 
        end
    
        test_spike = data(spikestart_loc:spikeend_loc); %waveform of this AP

        
        display(spikestart_loc)
        display(spikeend_loc)
        display(data(spikestart_loc))

        display( data(spikestart_loc))


        amplitude = max(test_spike) - test_spike(1); %AP amplitude
        AHP_amp = test_spike(1) - min(test_spike); %AHP amplitude

    
        %once the waveform is identified, calcualte AP and AHP properties
        %don't count this spike as an AP if it doesn't have AHP
        if AHP_amp >= 20 & amplitude >= 40
            apcount = apcount+1;

            [minpoint_val,minpoint] = min(test_spike);
            %find the time of the max and min points in test_spike
            [max_value,maxpoint] = max(test_spike);
        
            % AHP properties
             AHP_10 = min(test_spike) + (AHP_amp * 0.9); %100-30 value
             AHP_30 = min(test_spike) + (AHP_amp * 0.7); %100-30
             AHP_90 = min(test_spike) + (AHP_amp * 0.1); %100-90
             AHP_70 = min(test_spike) + (AHP_amp * 0.3); %100-70
             AHP_50 = min(test_spike) + (AHP_amp * 0.5); %100-70
    
            [~, ind_10_rise] = min(abs(test_spike(minpoint:end)-AHP_10)); %find the pt in the range (minpoint:end) where distance between value of test_spike at that point and AHP_10 value is the lowest. this finds the closest point to AHP_10.
            [~, ind_30_rise] = min(abs(test_spike(minpoint:end)-AHP_30));
            [~, ind_90_rise] = min(abs(test_spike(minpoint:end)-AHP_90));
            [~, ind_70_rise] = min(abs(test_spike(minpoint:end)-AHP_70));
            [~, ind_50_rise] = min(abs(test_spike(minpoint:end)-AHP_50));
            ind_10_rise = ind_10_rise + minpoint - 1;
            ind_30_rise = ind_30_rise + minpoint - 1;
            ind_90_rise = ind_90_rise + minpoint - 1;
            ind_70_rise = ind_70_rise + minpoint - 1;
            ind_50_rise = ind_50_rise + minpoint - 1;
        
            [~, ind_10_dec] = min(abs(test_spike(1:minpoint)-AHP_10));
            [~, ind_30_dec] = min(abs(test_spike(1:minpoint)-AHP_30));
            [~, ind_90_dec] = min(abs(test_spike(1:minpoint)-AHP_90));
            [~, ind_70_dec] = min(abs(test_spike(1:minpoint)-AHP_70));
            [~, ind_50_dec] = min(abs(test_spike(1:minpoint)-AHP_50));  
    
            AHP_decay_10to10 = ind_10_rise-ind_10_dec;%calculate AHP 10-10% time
            AHP_decay_30to30 = ind_30_rise-ind_30_dec; %calculate AHP 30-30% time
            AHP_decay_70to70 = ind_70_rise-ind_70_dec; %calculate AHP 70-70% time
            AHP_decay_90to90 = ind_90_rise-ind_90_dec;%calculate AHP 90-90% time
            interp_hw_AHP = ind_50_rise - ind_50_dec;
        
                    
                    
            %%%%%%%% AP properties %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
            
            % HALF WIDTH OF AP
             AP_50 = max(test_spike) - (amplitude * 0.5); %50% AP
    
            [~, AP_50_rise] = min(abs(test_spike(1:maxpoint)-AP_50));
            [~, AP_50_dec] = min(abs(test_spike(maxpoint:minpoint)-AP_50));
            AP_50_dec = AP_50_dec + maxpoint - 1;
            interp_hw_AP = AP_50_dec - AP_50_rise;
            
            
            minpoint_in_trace = find(data == test_spike(minpoint) );
            maxpoint_in_trace = find(data == test_spike(maxpoint) );
         
    
            %store each property in the bigger column heading variable for that
            %sweep. this column vareiable is a matrix where each row corresponds to
            %an AP in sweep a
    
            total_amplitude = [total_amplitude; amplitude]; %total_amplitude is a matrix that contains all the amplitudes of single APs from this particlar sweep
            total_AHP_amp = [total_AHP_amp; AHP_amp];
            total_minvalue = [total_minvalue; minpoint_val];
            total_maxvalue = [total_maxvalue; max_value];
            total_AHP_decay_10to10 = [total_AHP_decay_10to10; AHP_decay_10to10];
            total_AHP_decay_30to30= [total_AHP_decay_30to30; AHP_decay_30to30];
            total_AHP_decay_70to70= [total_AHP_decay_70to70; AHP_decay_70to70];
            total_AHP_decay_90to90= [total_AHP_decay_90to90; AHP_decay_90to90];
            total_interp_hw_AHP = [total_interp_hw_AHP;interp_hw_AHP];
            total_AP_50 = [total_AP_50; AP_50];
            total_interp_hw_AP = [total_interp_hw_AP;interp_hw_AP];
    
    
               
        end
    
    
    end
    
    %calculate average of each property for APs in this sweep
    if apcount > 0
        avg_amplitude = mean(total_amplitude);
        avg_AHP_amp = mean(total_AHP_amp);
        avg_minvalue = mean(total_minvalue);
        avg_maxvalue = mean(total_maxvalue);
        avg_AHP_decay_10to10 = mean(total_AHP_decay_10to10);
        avg_AHP_decay_30to30 = mean(total_AHP_decay_30to30);
        avg_AHP_decay_70to70 = mean(total_AHP_decay_70to70);
        avg_AHP_decay_90to90 = mean(total_AHP_decay_90to90);
        avg_interp_hw_AHP = mean(total_interp_hw_AHP);
        avg_AP_50 = mean(total_AP_50);
        avg_interp_hw_AP = mean(total_interp_hw_AP);
    
         %store the averaged properties in a new array
        sweepSummaryRow = [sweep_number,apcount, avg_amplitude, avg_AHP_amp, avg_minvalue, avg_maxvalue, avg_AHP_decay_10to10,avg_AHP_decay_30to30,avg_AHP_decay_70to70,avg_AHP_decay_90to90,avg_interp_hw_AHP,avg_AP_50, avg_interp_hw_AP];
      display(sweepSummaryRow) %TODO: DEBUG CODE
        summaryRow = array2table(sweepSummaryRow, 'VariableNames', myVarnames); %one row in a table summarizing average of each AP property for all singlet APs in this sweep
        
    end
end
end
        

