function getPhasePlot(data, starttime_ms, endtime_ms, si_actual)

% Define time vector for plotting
time_ms = linspace(starttime_ms, endtime_ms, length(data));

% Compute derivative (dV/dt)
dv_over_dt = diff(data) / si_actual; % Use sampling interval, not duration_ms

% Adjust time vector for dV/dt plot (length is reduced by 1)
time_ms_diff = time_ms(1:end-1); 

% Create figure with two subplots
figure;

% Left subplot: Membrane potential
subplot(1,2,1); 
plot(time_ms, data, 'b', 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('Membrane Potential (mV)');
title('Membrane Potential');
grid on;

% Right subplot: dV/dt
subplot(1,2,2); 
plot(time_ms_diff, dv_over_dt, 'r', 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('dV/dt (mV/ms)');
title('Rate of Change (dV/dt)');
grid on;

% Improve figure layout
sgtitle('Membrane Potential and dV/dt');


end