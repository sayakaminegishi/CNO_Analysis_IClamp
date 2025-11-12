function [currentInjections, FR, counts] = birrenFIcurves2(spikeTimes, type)
% birrenFIcurves2 calculates F-I curve parameters from spike time data
% Each sweep lasts 4 seconds, concatenated sequentially in time.
%
% INPUTS:
%   spikeTimes : cell array, where each cell contains spike times (in seconds)
%                for one sweep
%   type       : 1 = 25-sweep protocol, 2 = 28-sweep protocol
%
% OUTPUTS:
%   currentInjections : array of injected current steps (pA)
%   FR                : array of firing rates (Hz)
%   counts            : number of spikes per sweep

% Define current injection steps based on type
if type == 1
    % 25-sweep version
    currentInjections = [-50, -35, -20, -5, 10, 25, 40, 55, 70, 85, 100, 115, ...
                         130, 145, 160, 175, 190, 205, 220, 235, 250, 265, 280, 295, 310];
    numSweeps = 25;

elseif type == 2
    % 28-sweep version
    currentInjections = [-20, -10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, ...
                         100, 110, 120, 130, 140, 150, 160, 170, 180, 190, ...
                         200, 210, 220, 230, 240, 250];
    numSweeps = 28;

else
    error("Type not valid. Use 1 for 25 sweeps or 2 for 28 sweeps.");
end

% Timing parameters
sweepDuration_s = 4;            % each sweep lasts 4 seconds
starttime_ms = 138;             % start of current step (ms)
duration_ms = 500;              % duration of current step (ms)
startOffset_s = starttime_ms / 1000;       % convert to seconds
duration_s = duration_ms / 1000;           % convert to seconds

% Create start/stop times for each sweep (in seconds)
startTimes = (0:numSweeps-1) * sweepDuration_s + startOffset_s;
stopTimes  = startTimes + duration_s;

% Initialize outputs
counts = zeros(1, numSweeps);
FR = zeros(1, numSweeps);

% Compute spike counts and firing rates
for i = 1:numSweeps
    theseSpikes = spikeTimes{i};
    % Count spikes that occur within the current injection window
    counts(i) = sum(theseSpikes >= startOffset_s & theseSpikes < (startOffset_s + duration_s));
    % Compute firing rate (Hz) based on 0.5 s current step
    FR(i) = counts(i) / duration_s;
end

end
