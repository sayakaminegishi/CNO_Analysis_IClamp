%function plotDvDtMembraneP(data, starttime_ms, endtime_ms, si_actual)

data = readtable('SHRN_Only_NEW.csv');

numSweeps=25;

starttime_ms = 138;
duration_ms = 500;
si= (1.0000e-04)/(1e-6)

    % Convert to indices
    starttime_idx = round(starttime_ms / (si * 1e-3)); % Convert ms to samples
    duration_idx = round(duration_ms / (si * 1e-3));
    endtime_idx = starttime_idx + duration_idx;
    endtime_ms = starttime_ms + duration_ms;

    % Process each sweep
    for sweep = 1:numSweeps
        % Extract relevant data
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        
    end
        % Define time vector for plotting
time_ms = linspace(starttime_ms, endtime_ms, length(data));

% Compute derivative (dV/dt)
dv_over_dt = diff(data) / si_actual; % Use sampling interval, not duration_ms

figure;
plot(data, dv_over_dt, 'r', 'LineWidth', 1.5);
xlabel('membrane potential (mV)');
ylabel('dV/dt (mV/ms)');
title('Rate of Change (dV/dt)');
grid on;

% Improve figure layout
sgtitle('Membrane Potential and dV/dt');


%end