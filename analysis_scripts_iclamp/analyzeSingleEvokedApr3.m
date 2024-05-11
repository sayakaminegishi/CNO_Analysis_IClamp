function M1 = analyzeSingleEvokedApr3(filename1, current_injected1)
%function ver. of singleEVOKED.m. This script finds the firing properties of the FIRST AP ever detected
%from A SPECIFIC ABF FILE (cell), and exports the summary table as an excel
%file. the single-file analysis version of Feb23_batchEvoked.m

%filename1= filename
% current_injected1 = stimulus current in matrix

% Created by: Sayaka (Saya) Minegishi
% minegishis@brandeis.edu
% Apr 5 2024

filename = filename1; %specify file to examine

myVarnames1= {'cell_name', 'current_injected(pA)','frequency(Hz)','spike_location(ms)', 'threshold(mV)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'trough location(ms)', 'peak value(mV)', 'peak location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)','AHP_width_90to30%(ms)', 'AHP_width_10to90%(ms)' };

multipleVariablesTable= zeros(0,numel(myVarnames1));
multipleVariablesRow1 = zeros(0, numel(myVarnames1));

T1= array2table(multipleVariablesTable, 'VariableNames', myVarnames1); %stores info from all the sweeps in an abf file

current_injected = current_injected1; %stimulus current

   
    [dataallsweeps, si, h] =abf2load(filename); %get si and h values from this abf file
   
    totalsweeps=size(dataallsweeps,3); %the total number of sweeps to be analyzed (25)
   
    numpointspersweep = size(dataallsweeps, 1); %size of first column, which is the total no. of points per sweep in this ABF file
    
    si_actual = 1e-6 * si; %in ms. original si is in usec

     apFoundInCell = 0; %1 if AP has been found in cell

    numspikes = 0;
  

     onems = si * 10^-3; %ms/sample
    dV_thresh_mVms = 10; % in mV/ms
    
    dV_thresh = dV_thresh_mVms*onems; % in mV/sample 

    
       
   for a= 1: totalsweeps %analyze the sweep that invokes the first AP in cell. change this to totalsweeps:totalsweeps to analyze 1st ap of last sweep
               
    if(apFoundInCell == 0)
        data=dataallsweeps(:,1,a); %select sweep to analyze....data=dataallsweeps(:,1,9). this is the trace.
        data = detrend(data, 1) + data(1); %Correct baseline - detrend shifts baseline to 0
    
        x_axis_samples = 1:size(data,1);
        x_axis_actual = sampleunits_to_ms(si, x_axis_samples);
        %threshold minimum

        
        
            alloweddeviation = 40;%if 30, anything within 30mV of resting potential (first value in trace) is deemed as noise
            
            minimumAmp = data(1) + alloweddeviation; %anything within 40mV of resting potential (first value in trace) is deemed as noise
            
            all_dV = find(diff(data) >= dV_thresh);  %list of indices in data at which slope > threshold
            
            %filter
            all_dV_filtered = [];
            k = 1;
            for i = 1:numel(all_dV)
                if (data(all_dV(i))>= minimumAmp)
                    all_dV_filtered(k) = all_dV(i);
                    k = k + 1;
                end 
            end
            
        %set threshold for noise
        if(isempty(all_dV_filtered))
            error = "No action potentials identified in this trace.";
            display(error); %error message.
        else
            apFoundInCell = 1;
            threshold_value = data(all_dV_filtered(1)); %threshold for AP detection
            threshold_pt = all_dV_filtered(1); %point whre threshold first hits, in samples
                restingpotential = data(1); %resting potential. 
              
                
                pks_in_trace = get_spikelocations(data,dV_thresh); %get AP spike times in trace
                [~,troughlocations] = findpeaks(-data, 'MinPeakProminence',5); %get all trough locations
                
                if(numel(pks_in_trace)>=1)
                    
                    mainpeakloc = pks_in_trace(1);
                    maintroughloc = troughlocations(1);

                    

                    threshold_voltage = data(all_dV_filtered(1)); 
                    %rising and falling durations of an AP
                    risingDuration = mainpeakloc - threshold_pt; %in sample units
                    
                    maxlength_pulse = 5248; %end pt of current pulse. obtained by visual inspection.
                    %find falling duration.
                  

                    if numel(pks_in_trace ==1)
                        rangetolook = data(maintroughloc:maxlength_pulse);
                        
                    else
                        rangetolook = data(maintroughloc:pks_in_trace(2));
                    end


                    thresh_pt_2_candidates = threshold_crossings( rangetolook, threshold_value );
                    % if numel(thresh_pt_2_candidates) >=1
                    %     threshpt2 = maintroughloc+ thresh_pt_2_candidates(1); %time where the first AP ends
                    %     fallingDuration = threshpt2-mainpeakloc;
                    % else
                    % 
                    %     fallingDuration = maxlength_pulse - mainpeakloc;
                    % end


                    %falling duration - method2 - find where slope sign changes
                
                    f=smoothdata(rangetolook, "gaussian"); %smooth out noise with gaussian filter after trough pt
                    negative_slope = find(diff(f)<0);
                    
                    if(numel(negative_slope)>=1)

                        slopedecreasept = maintroughloc + negative_slope(1);

                    else
                        if(numel(pks_in_trace) == 1)
                            slopedecreasept = maxlength_pulse;
                        else
                             slopedecreasept = pks_in_trace(2);
                        end
                    end
                    fallingDuration = slopedecreasept- mainpeakloc;
                    

                    

                    [test_spike,starttime,endtime] = extract_waveform3(risingDuration,fallingDuration, mainpeakloc, data); %in sample units
        
                       
                   
            
                    figure;
                plot(test_spike)
            
            
               %analyze the first spike in cell
                total_count_Aps = numel(pks_in_trace); %count total no. of APs in first sweep where AP is detected
                totalduration_sec = sampleunits_to_ms(si, numel(data)) * 10^(-3); %total duration of the recording in sec for the whole trace, minus the transients
                
                freq_in_hz = total_count_Aps/totalduration_sec; %frequency of the sweep with the first AP detected in cell.
            
                amplitude = max(test_spike) - test_spike(1);
                AHP_amp_real = min(test_spike) - test_spike(1);
                AHP_amp = abs(AHP_amp_real);

                max_voltage = data(mainpeakloc);
                
                
                maxpoint = find(test_spike == max(test_spike));
                maxpoint = maxpoint(1);
            
                % Find the minimum value in the specified portion
                minValue = min(test_spike(maxpoint:end));
            
                % Find the index of the minimum value in the specified portion
                minpoint = find(test_spike(maxpoint:end) == minValue, 1, 'first') + maxpoint - 1;
            
                minpoint_val = test_spike(minpoint);
            
                
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                 % AHP properties
                 AHP_10 = min(test_spike) + (AHP_amp * 0.9); %100-30 value
                 AHP_30 = min(test_spike) + (AHP_amp * 0.7); %100-30
                 AHP_90 = min(test_spike) + (AHP_amp * 0.1); %100-90
                 AHP_70 = min(test_spike) + (AHP_amp * 0.3); %100-70
                 AHP_50 = min(test_spike) + (AHP_amp * 0.5); %100-70
                  % AP properties
                 AP_50 = max(test_spike) - (amplitude * 0.5); %50% AP
             % %%%%%%%%%%%%%FINDING fractions of AP and AHP widths WITH interpolation
                % % Perform interpolation between max to min pt of test_spike
                x2 = [maxpoint:minpoint];
                xq_maxToMin = x2(1):0.2:x2(end);
                vq_maxToMin = interp1(x2, test_spike(x2), xq_maxToMin); %interpolated values of y between x = min:end
                %  % Create the x-values (assuming they are indices in this case)
                x = [minpoint:numel(test_spike)];
                % % Perform interpolation to get more detailed graph
                xq_minToEnd = x(1):0.2:x(end);
                vq_minToEnd = interp1(x, test_spike(x), xq_minToEnd); %interpolated values of y between x = min:end
            
                [~, ind_10_rise] = min(abs(vq_minToEnd-AHP_10)); %find the pt in the range (minpoint:end) where distance between value of test_spike at that point and AHP_10 value is the lowest. this finds the closest point to AHP_10.
                [~, ind_30_rise] = min(abs(vq_minToEnd-AHP_30));
                [~, ind_90_rise] = min(abs(vq_minToEnd-AHP_90));
                [~, ind_70_rise] = min(abs(vq_minToEnd-AHP_70));
                [~, ind_50_rise] = min(abs(vq_minToEnd-AHP_50));
            
                [~, ind_10_dec] = min(abs(vq_maxToMin-AHP_10));
                [~, ind_30_dec] = min(abs(vq_maxToMin-AHP_30));
                [~, ind_90_dec] = min(abs(vq_maxToMin-AHP_90));
                [~, ind_70_dec] = min(abs(vq_maxToMin-AHP_70));
                [~, ind_50_dec] = min(abs(vq_maxToMin-AHP_50));  
                % interpolation of y values between 1 to max pt
                x3 = 1:maxpoint;
                xq_1tomax= x3(1):0.2:x3(end);
                vq_1tomax = interp1(x3, test_spike(x3), xq_1tomax);
                % variables for finding half width of AP
                [~, AP_50_rise] = min(abs(vq_1tomax-AP_50));
                [~, AP_50_dec] = min(abs(vq_maxToMin-AP_50));
            
            
                 %FIXED:
                interp_hw_AHP = numel(vq_maxToMin)+ind_50_rise - ind_50_dec;
                interp_hw_AHP_time = 0.2 * sampleunits_to_ms(si,  interp_hw_AHP);
            
                %adjusted accordingly (in sample units):
                AHP_decay_10to10 = numel(vq_maxToMin)+ind_10_rise - ind_10_dec; %AHP 10% to 10% width
                AHP_decay_30to30 = numel(vq_maxToMin)+ind_30_rise - ind_30_dec;  %calculate AHP 30-30% time
                AHP_decay_70to70 = numel(vq_maxToMin)+ind_70_rise - ind_70_dec; %calculate AHP 70-70% width
                AHP_decay_90to90 = numel(vq_maxToMin)+ind_90_rise - ind_90_dec;
            
                %90- 30%
                AHP_decay_90to30 = numel(vq_maxToMin)+ ind_30_rise-ind_90_rise;
                AHP_decay_10to90 = numel(vq_maxToMin)+ind_10_rise - ind_90_rise;
            
                %convert from sampleunits to ms:
                % we're changing the sampling units to be from every 100us to be every 20us (in the interpolated space with step 0.2 sample units). 
                dec10w = 0.2 * sampleunits_to_ms(si,  AHP_decay_10to10);
                dec30w = 0.2 * sampleunits_to_ms(si,  AHP_decay_30to30);
               dec70w =0.2 * sampleunits_to_ms(si,  AHP_decay_70to70);
               dec90w =0.2 * sampleunits_to_ms(si,  AHP_decay_90to90);
              
               dec90_30w = 0.2 * sampleunits_to_ms(si,  AHP_decay_90to30);
               dec10_90w = 0.2 * sampleunits_to_ms(si,  AHP_decay_10to90);
                        
             
                        
                %%%%%%%% AP properties %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                interp_hw_AP = numel(vq_1tomax)+ AP_50_dec - AP_50_rise;
                interp_hw_AP_time = 0.2 * sampleunits_to_ms(si,  interp_hw_AP);
               
                %minpoint and maxpoints, in terms of whole data
                
                minpoint_in_trace = find(test_spike == test_spike(minpoint) ) + starttime;
             
                maxpoint_in_trace = find(test_spike == test_spike(maxpoint) ) + starttime;
              
          
                spikeloc = sampleunits_to_ms(si,mainpeakloc); % %
                minp = data(minpoint_in_trace); % % 
                minpInTrace =sampleunits_to_ms(si, minpoint_in_trace(1));
                maxpointdata = data(maxpoint_in_trace); % % 
                maxpointInTrace =sampleunits_to_ms(si,maxpoint_in_trace(1)); % % 
                
            
                %%% put into table %%%
                
               multipleVariablesRow1= [filename, current_injected(a), freq_in_hz, spikeloc(1), threshold_voltage(1), amplitude(1), AHP_amp_real(1), minp(1),minpInTrace(1), maxpointdata(1), maxpointInTrace(1), interp_hw_AP_time, AHP_30(1), AHP_50(1), AHP_70(1), AHP_90(1), interp_hw_AHP_time, dec10w(1), dec30w(1), dec70w(1), dec90w(1), dec90_30w(1), dec10_90w(1)];
                   
               M1= array2table(multipleVariablesRow1, 'VariableNames', myVarnames1);
               %T1 = [T1; M1];
            
              
               
            
            end
            end
    end
   end
       

