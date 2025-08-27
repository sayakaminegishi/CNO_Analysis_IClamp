function apCounts = getAPCountUsingDvDt(filename1)
% GETAPCOUNTUSINGDVDT Detects and counts action potentials in each sweep of an ABF file using phase-plane analysis.

    % Load ABF file data
    [dataallsweeps, si, h] = abf2load(filename1);

    numSweeps = size(dataallsweeps, 3); % Total number of sweeps
    apCounts = zeros(1, numSweeps);     % Initialize AP count storage

    % Convert sampling interval to seconds
    si_actual = 1e-6 * si;

    % Define analysis window (ms)
    starttime_ms = 138;
    duration_ms = 500;
    endtime_ms = starttime_ms + duration_ms;

    % Convert to sample indices
    starttime_idx = round(starttime_ms / (si * 1e-3));
    duration_idx  = round(duration_ms  / (si * 1e-3));
    endtime_idx   = starttime_idx + duration_idx;

    % Refractory period for spike detection
    minISI_ms = 3;
    minISI_samples = round(minISI_ms / (si * 1e-3));

    for sweep = 1:numSweeps
        % Extract voltage trace for this sweep
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));

        % Compute dV/dt
        dvdt = diff(data) / si_actual;
        v_trimmed = data(1:end-1); % Align with dvdt

        % Use winding-number spike detection
        spike_indices = detect_spikes(v_trimmed, dvdt, minISI_samples);

        % Store spike count
        apCounts(sweep) = numel(spike_indices);

        % Plot this sweep
        time_ms = linspace(starttime_ms, endtime_ms, length(data));
        figure('Name', ['Sweep ' num2str(sweep)], 'NumberTitle', 'off');

        subplot(2,1,1);
        plot(time_ms, data, 'k'); hold on;
        
        % Make sure spike indices do not exceed length of data
        valid_spikes = spike_indices(spike_indices <= length(data));
        
        if ~isempty(valid_spikes)
            plot(time_ms(valid_spikes), data(valid_spikes), 'ro', 'MarkerFaceColor', 'r');
        end

        xlabel('Time (ms)');
        ylabel('Membrane Potential (mV)');
        title(['Sweep ' num2str(sweep) ' Voltage Trace']);
        grid on;

        subplot(2,1,2);
        plot(v_trimmed, dvdt, 'k');
        xlabel('Membrane Potential (mV)');
        ylabel('dV/dt (mV/s)');
        title(['Sweep ' num2str(sweep) ' Phase Plot']);
        grid on;
    end
end
