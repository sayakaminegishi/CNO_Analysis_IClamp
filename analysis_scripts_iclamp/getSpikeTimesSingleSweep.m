function [apCount, spikeTimes] = getSpikeTimesSingleSweep(data, timepoints)
% GETSPIKETIMESSINGLESWEEP Detects and counts action potentials for a SINGLE sweep
% using phase-plane analysis. single-sweep version of
% getSpikeTimesUsingDvDt_givenData2.m
%
% Inputs:
%   data        : voltage trace for one sweep [samples x 1]
%   timepoints  : time vector corresponding to the samples (ms)
%
% Outputs:
%   apCount     : number of detected spikes in the sweep
%   spikeTimes  : vector of spike times (ms) for the sweep

% Hardcoded parameters
threshold = 0;    % voltage threshold for spike detection (mV)
minISI_s = 0.003;    % minimum interspike interval (s)
dvdt_thresh=0.5e5;
% Compute sampling interval from timepoints
si_actual = mean(diff(timepoints)); % in seconds
minISI_samples = round(minISI_s / mean(diff(timepoints))); % convert s to samples

% Compute dV/dt
dvdt = diff(data) / si_actual;
v_trimmed = data(1:end-1); % Align with dvdt

% --- Detect threshold crossings (candidate spikes) ---
spike_indices = find(v_trimmed(1:end-1) < threshold & v_trimmed(2:end) >= threshold) + 1;

% Apply minimum ISI to avoid double-counting
if ~isempty(spike_indices)
    isi = [inf; diff(spike_indices(:))]; % column vector
    spike_indices = spike_indices(isi >= minISI_samples);
end

% --- Find first dv/dt = 0 after threshold (AP peak) ---
peak_indices = [];
for i = 1:length(spike_indices)
    found_dvdt_thresh=false;
    idx_start = spike_indices(i);

    for j = idx_start:length(dvdt)-1
        if dvdt(j)>dvdt_thresh
            found_dvdt_thresh = true;
        end
        if found_dvdt_thresh && dvdt(j) > 0 && dvdt(j+1) <= 0
            peak_indices(end+1,1) = j; % store peak index
            break
        end
    end
end

% Store spike count and times
apCount = numel(peak_indices);
spikeTimes = timepoints(peak_indices);

% --- Plot voltage and phase plots ---
figure('Name', 'Single Sweep', 'NumberTitle', 'off');

% Voltage trace
subplot(2,1,1);
plot(timepoints, data, 'k'); hold on;
if ~isempty(peak_indices)
    plot(timepoints(peak_indices), data(peak_indices), 'ro', 'MarkerFaceColor', 'r');
end
xlabel('Time (ms)'); ylabel('Membrane Potential (mV)');
title('Voltage Trace'); grid on;

% Phase plot
subplot(2,1,2);
plot(v_trimmed, dvdt, 'k'); hold on;
if ~isempty(peak_indices)
    plot(data(peak_indices), dvdt(peak_indices), 'ro', 'MarkerFaceColor', 'r');
end
xlabel('Membrane Potential (mV)'); ylabel('dV/dt (mV/s)');
title('Phase Plot'); grid on;

end
