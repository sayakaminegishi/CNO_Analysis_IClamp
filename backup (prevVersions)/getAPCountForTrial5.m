function [apCounts] = getAPCountForTrial5(filename1)
    % Load ABF file data
    [dataallsweeps, si, h] = abf2load(filename1); 
    
    numSweeps = size(dataallsweeps, 3); % Total number of sweeps
    apCounts = zeros(1, numSweeps); % Initialize AP count storage
    
    % Convert sampling interval to seconds
    si_actual = 1e-6 * si; 

    % Get user input for pulse timing
    prompt_start = "Input pulse start time in ms after start of recording: ";
    starttime_ms = input(prompt_start); 

    prompt_duration = "Enter the duration of the pulse (ms): ";
    duration_ms = input(prompt_duration);

   % Convert to indices
    starttime_idx = round(starttime_ms / (si * 1e-3)); % Convert ms to samples
    duration_idx = round(duration_ms / (si * 1e-3));
    endtime_idx = starttime_idx + duration_idx;
    endtime_ms = starttime_ms + duration_ms; % Define missing variable

    for sweep = 1:numSweeps
        % Extract relevant data only
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        mistake_spike_count = 0;
        %%%%%%% DISPLAY DATA - ALLOW USER TO ENTER NO. OF APs THAT MIGHT BE
        %%%%%%% MISTAKENLY COUNTED. STORE THE NUMBER AS n, AND SUBTRACT
        %%%%%%% THAT VALUE FROM TOTAL COUNT AT THE END. 
        
        
        time_ms = linspace(starttime_ms, endtime_ms, length(data));
        plot(time_ms, data, 'b', 'LineWidth', 1.5);
        xlabel('Time (ms)');
        ylabel('Membrane Potential (mV)');
        title('Membrane Potential for sweep ' + sweep);

        prompt_mistakes = "Enter the number of spikes that should not be counted: ";
        mistake_spike_count = input(prompt_mistakes); 


        %%%%%%%%% GET PHASE PLOT %%%%%%%%%%%
        getPhasePlot(data, starttime_ms, endtime_ms, si_actual)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Set AP detection parameters
        dV_thresh_mVms = 10; % AP threshold in mV/ms
        dV_thresh = dV_thresh_mVms * si_actual; % Convert threshold to mV/sample
        allowedDeviation = 40; % Noise filter threshold

        % Set minimum amplitude for AP detection
        minAmp = data(1) + allowedDeviation;

        % Detect spikes
        [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 5);
        
        % Store the count of detected APs, set to 0 if none are found
        apCounts(sweep) = numel(spikeLocations)-mistake_spike_count;
        
        % Store the count of detected APs, set to 0 if none are found
        if isempty(spikeLocations)
            apCounts(sweep) = 0;
        else
            apCounts(sweep) = numel(spikeLocations);
        end
     end
end
