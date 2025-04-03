function [apCounts] = getAPCountForTrial8(filename1)
    % Load ABF file data
    [dataallsweeps, si, h] = abf2load(filename1); 
    
    numSweeps = size(dataallsweeps, 3); % Total number of sweeps
    apCounts = zeros(1, numSweeps); % Initialize AP count storage
    
    if numSweeps>28
        return; %invalid data (eg voltage clamp). skip.
        end
    % Convert sampling interval to seconds
    si_actual = 1e-6 * si; 
    %%%%%% UNCOMMENT BELOW CODE TO GENERALIZE CODE %%%%%%%%%%%%%%%%%%%
    % % Collect all user inputs at the beginning
    % while true
    %     userInput = input("Input pulse start time in ms after start of recording (or type 'q' to quit): ", 's');
    %     if strcmpi(userInput, 'q') || strcmpi(userInput, 'quit')
    %         disp('Program terminated by user.');
    %         return;
    %     end
    %     starttime_ms = str2double(userInput);
    %     if isnan(starttime_ms) || starttime_ms < 0
    %         disp('Invalid input. Please enter a positive numeric value.');
    %         continue;
    %     end
    %     break;
    % end
    % 
    % while true
    %     userInput = input("Enter the duration of the pulse in ms (or type 'q' to quit): ", 's');
    %     if strcmpi(userInput, 'q') || strcmpi(userInput, 'quit')
    %         disp('Program terminated by user.');
    %         return;
    %     end
    %     duration_ms = str2double(userInput);
    %     if isnan(duration_ms) || duration_ms <= 0
    %         disp('Invalid input. Please enter a positive numeric value.');
    %         continue;
    %     end
    %     break;
    % end
    %%%%%%%%%%%%%%%%%%
    %IF NOT GENERALIZED:
    starttime_ms = 138;
    duration_ms = 500;
    
    % Convert to indices
    starttime_idx = round(starttime_ms / (si * 1e-3)); % Convert ms to samples
    duration_idx = round(duration_ms / (si * 1e-3));
    endtime_idx = starttime_idx + duration_idx;
    endtime_ms = starttime_ms + duration_ms;

    % Process each sweep
    for sweep = 1:numSweeps
        % Extract relevant data
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        

        % Set AP detection parameters
       allowedDeviation = 25; % Noise filter threshold
        
        firstpercentile = prctile(dataallsweeps(starttime_idx:endtime_idx),1); 
        minAmp = firstpercentile + allowedDeviation;

        % Detect spikes
        [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 45, 'MinPeakDistance',50); %TODO: base it on intraspike interval like in spike_times2.m
        %d(:,1,sweep),height); 
        %[number, times] = spike_times2(dataallsweeps(:, 1, 28),minAmp)

        % Store the count of detected APs
        apCounts(sweep) = numel(spikeLocations);

        %%%%%%%%% PLOT last sweep only %%%%%%%%%%%%
        time_ms = linspace(starttime_ms, endtime_ms, length(data));
        
        if sweep==1 | sweep==numSweeps
            figure;
            plot(time_ms, data, 'b', 'LineWidth', 1.5); % Plot trace in blue
            hold on;
            plot(time_ms(spikeLocations), pks, 'ro', 'MarkerFaceColor', 'r'); % Red dots for detected APs
            xlabel('Time (ms)');
            ylabel('Membrane Potential (mV)');
            title(['Sweep ' num2str(sweep) ': Membrane Potential']);
            grid on;
            hold off;
        end
        %getPhasePlot(data, starttime_ms, endtime_ms, si_actual)
    end
end
