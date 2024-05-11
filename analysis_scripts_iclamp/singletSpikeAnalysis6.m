function T1 = singletSpikeAnalysis6(data, singletTimesMatrix, all_dV, dV_thresh, si)

% aim: make a summary table for all the singlet spikes detected in an abf file. this file must be in the
% same directory as the abf file of interest. 
%singletTimesMatrix in sample units. si must be in microseconds.

% Created by: Sayaka (Saya) Minegishi, with support from Dr. Stephen Van
% Hooser
% Contact: minegishis@brandeis.edu
% Last revised: 2/17/23



% %%%%%%%%%%%%%%%%%% SINGLET AP ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

myVarNames1 = {'spike_location(ms)', 'threshold(mV)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'trough location(ms)', 'peak value(mV)', 'peak location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)','AHP_width_90to30%(ms)', 'AHP_width_10to90%(ms)' };

multipleVariablesTable1= zeros(0,numel(myVarNames1));
multipleVariablesRow1 = zeros(0, numel(myVarNames1));

T1= array2table(multipleVariablesTable1, 'VariableNames', myVarNames1); %stores info from all the sweeps in an abf file

%si_actual = 1e-6 * si; %in s. original si is in usec
%si_actual = 1e-3 * si; %in ms

 x_axis_samples = 1:numel(data);
x_axis_actual = sampleunits_to_ms(si, x_axis_samples);
       
baseline = data(1); %resting potential. used for calculating AHP troughs
%go through each spike and get their waveform
for j = 1:size(singletTimesMatrix,1)  
    mainpeakloc = singletTimesMatrix(j); %in sample units
  
    %Spike times - extract waveform
    threshold_voltage = data(all_dV(1)); 
    

%find first pt after pkloc where instn gradient is positive (and smaller than 2mv/ms), y is back to
%baseline.

z = find(data-baseline>=0);
c = find(z>mainpeakloc);
endtimesp=c(1) %time AHP comes back to baseline again



    risingDuration = 1279-947; %obtained by visual inspection
    %fallingDuration = endtimesp-mainpeakloc;
   % %fallingDuration = 1542-1279;
   % fallingDuration = 235671-234662; %peak of AP to end of AHP, in sample units

    %[test_spike,starttime,endtime] = extract_waveform3(risingDuration,fallingDuration, mainpeakloc, data); %in sample units
    
    starttime = mainpeakloc - risingDuration
    endtime = endtimesp
    size(data)
test_spike = data(starttime:endtime);
    figure(8)
    plot(test_spike)


   

    amplitude = max(test_spike) - test_spike(1);
    AHP_amp = test_spike(1) - min(test_spike);
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
  
   %  % DURATION OF AP: include only if the spike window was not fixed! ,
   %  duration_ms(1) = , 'duration(ms)'
   %  duration_sampleunits = numel(test_spike);
   % duration_ms = sampleunits_to_ms(si, duration_sampleunits);
   % 
 
    spikeloc = sampleunits_to_ms(si,mainpeakloc); % %
    minp = data(minpoint_in_trace); % % 
    minpInTrace =sampleunits_to_ms(si, minpoint_in_trace(1));
    maxpointdata = data(maxpoint_in_trace); % % 
    maxpointInTrace =sampleunits_to_ms(si,maxpoint_in_trace(1)); % % 
    

    %%% put into table %%%
    
   multipleVariablesRow1= [spikeloc(1), threshold_voltage(1), amplitude(1), AHP_amp(1), minp(1),minpInTrace(1), maxpointdata(1), maxpointInTrace(1), interp_hw_AP_time, AHP_30(1), AHP_50(1), AHP_70(1), AHP_90(1), interp_hw_AHP_time, dec10w(1), dec30w(1), dec70w(1), dec90w(1), dec90_30w(1), dec10_90w(1)];
       
   M1= array2table(multipleVariablesRow1, 'VariableNames', myVarNames1);
   T1 = [T1; M1];

   %%%%%visualize this singlet %%%%%%
    % figure(7);
    % plot(x_axis_actual,data)
    % hold on
    % plot(sampleunits_to_ms(si, starttime + maxpoint), data(starttime + maxpoint), 'ro')
    % plot(sampleunits_to_ms(si, starttime + minpoint), data(starttime + minpoint), 'rdiamond')
    % plot(sampleunits_to_ms(si, numel(vq_maxToMin)+ind_10_rise), test_spike(ind_10_rise))
    % 
    % xlabel("Time (ms)")
    % ylabel("Membrane Potential (mV)")
    % hold off
    % 
    % 

   

end
end


