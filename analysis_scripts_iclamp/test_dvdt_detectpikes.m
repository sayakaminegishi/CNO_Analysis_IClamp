filename1 = "/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata/SHR/SHRN+glia/2023_02_01_01_0006.abf"
% apcounts = getAPCountUsingDvDt_peakspike(filename1)
% 

% GETAPCOUNTUSINGDVDT_PEAKSPIKE
% Loads an ABF file and detects APs in each sweep using
% getSpikeTimesUsingDvDt (single-sweep function).
%
% INPUT:
%   filename1 : string, path to .abf file
%
% OUTPUT:
%   apCounts  : vector, spike counts per sweep

    % Load ABF file
    [dataallsweeps, si, h] = abf2load(filename1);
    numSweeps = size(dataallsweeps, 3);

    % Convert sampling interval to ms
    si_ms = si * 1e-3;   % si is in microseconds → ms
    si_s  = si * 1e-6;   % si in seconds for dv/dt (if needed inside subfunc)

    % Analysis window (ms)
    starttime_ms = 138;
    duration_ms  = 500;
    endtime_ms   = starttime_ms + duration_ms;

    % Convert to sample indices
    starttime_idx = round(starttime_ms / si_ms);
    duration_idx  = round(duration_ms  / si_ms);
    endtime_idx   = starttime_idx + duration_idx;

    % Storage
    apCounts = zeros(1, numSweeps);

    for sweep = 1:numSweeps
        % Extract data segment
        sweepData = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));

        % Create timepoints vector (ms)
        timepoints = linspace(starttime_ms, endtime_ms, length(sweepData));

        % Call single-sweep detector
        [spikeTimes, spikeCount] = getSpikeTimesUsingDvDt_givenData(timepoints, sweepData);

        % Store result
        apCounts(sweep) = spikeCount;

        % (Optional) display spike times
        fprintf('Sweep %d: %d spikes detected at [%.1f ...] ms\n', ...
                 sweep, spikeCount, spikeTimes);
              
    end
   