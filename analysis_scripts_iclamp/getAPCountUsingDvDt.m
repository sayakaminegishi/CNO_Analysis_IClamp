function apCounts = getAPCountUsingDvDt(filename1)
% GETAPCOUNTUSINGDVDT Detects and counts action potentials in each sweep of an ABF file using phase-plane analysis.
%
%   apCounts = GETAPCOUNTUSINGDVDT(filename1) processes intracellular
%   current-clamp data from an ABF file to detect spikes based on the
%   rate of change of voltage (dV/dt) using a winding number method.
%   It returns the number of action potentials (spikes) detected in
%   each sweep of the recording.
%
%   INPUT:
%     filename1 - Full path to the .abf file containing the recording.
%
%   OUTPUT:
%     apCounts  - A row vector where each element corresponds to the
%                 number of spikes detected in a sweep.
%
%   METHOD OVERVIEW:
%     1. The ABF file is loaded, and data from each sweep is extracted.
%     2. For a defined time window (starttime_ms to endtime_ms),
%        membrane potential (V) and its derivative (dV/dt) are computed.
%     3. Spikes are detected using a custom 'detect_spikes' function,
%        which identifies full clockwise rotations in the phase plot
%        (voltage vs. dV/dt), corresponding to action potentials.
%     4. For each sweep, spike indices are marked and visualized,
%        and the total spike count is stored in apCounts.
%
%   NOTES:
%     - This method is well-suited for detecting APs even when
%       traditional threshold-based methods are unreliable.
%     - Requires the function 'detect_spikes(v, dvdt)' to be defined.
%     - Assumes recording is in Channel 1 of the ABF file.
%     - Each sweep is plotted with the raw trace and phase plot
%       with spike markers shown.
%
%red circle at each time point where a spike was detected (ie. where the
%winding angle reached a full 2pi rotation

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

    for sweep = 1:numSweeps
        % Extract voltage trace for this sweep
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));

        % Compute dV/dt
        dvdt = diff(data) / si_actual;
        v_trimmed = data(1:end-1); % Align with dvdt

        % Use winding-number spike detection
        spike_indices = detect_spikes(v_trimmed, dvdt);


        % Store spike count
        apCounts(sweep) = numel(spike_indices);

        % Plot this sweep
        time_ms = linspace(starttime_ms, endtime_ms, length(data));
        figure('Name', ['Sweep ' num2str(sweep)], 'NumberTitle', 'off');

        subplot(2,1,1);
        plot(time_ms, data, 'k'); hold on;
        if ~isempty(spike_indices)
            plot(time_ms(spike_indices), data(spike_indices), 'ro');
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
