%% === Setup session ===
steve = false;

if steve
    session_folder = '/Users/vanhoosr/data/saya';
else
    session_folder = '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya';
end

% Open or create NDI session
S = ndi.session.dir(session_folder);

%% === Get the probes that are patch recordings ===
p = S.getprobes('type', 'patch-Vm');

%% === Parameters ===
N = 1;   % number of probes to process
results = struct(); % store spike times and firing frequency

for P = 1:N  % loop through probes
    et = p{P}.epochtable();
    f = figure;
    counter = 0;

    % allocate storage
    allSpikeTimes = cell(numel(et),1);
    allFreqs = nan(numel(et),1);

    for e = 1:numel(et)
        counter = counter + 1;

        % read data
        [d,t] = p{P}.readtimeseries(e,-inf,inf);

        % detect spikes
        [apcount, spiketimes] = getSpikeTimesSingleSweep(d,t);

        % store results
        allSpikeTimes{e} = spiketimes;
        sweepDuration = t(end) - t(1);
        if sweepDuration > 0
            allFreqs(e) = apcount / sweepDuration;  % Hz
        else
            allFreqs(e) = NaN;
        end

        % plot
        supersubplot(f,4,4,counter);
        plot(t,d); hold on;
        if ~isempty(spiketimes)
            plot(spiketimes, ones(size(spiketimes))*mean(d), 'ko') % plot spikes on trace
        end
        xlabel('Time (s)');
        ylabel('Voltage (mV)');
        title(sprintf('Sweep %d: %d spikes, %.2f Hz', e, apcount, allFreqs(e)));
    end

    % save probe results
    results(P).probeID = p{P}.id();
    results(P).spikeTimes = allSpikeTimes;
    results(P).frequencies = allFreqs;
end

%% === Results summary ===
disp('Spike detection results:');
disp(results);
%% === Setup session ===
steve = false;

if steve
    session_folder = '/Users/vanhoosr/data/saya';
else
    session_folder = '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya';
end

% Open or create NDI session
S = ndi.session.dir(session_folder);

%% === Get the probes that are patch recordings ===
p = S.getprobes('type', 'patch-Vm');

%% === Parameters ===
N = 1;   % number of probes to process
results = struct(); % store spike times and firing frequency

for P = 1:N  % loop through probes
    et = p{P}.epochtable();
    f = figure;
    counter = 0;

    % allocate storage
    allSpikeTimes = cell(numel(et),1);
    allFreqs = nan(numel(et),1);

    for e = 1:numel(et)
        counter = counter + 1;

        % read data
        [d,t] = p{P}.readtimeseries(e,-inf,inf);

        % detect spikes
        [apcount, spiketimes] = getSpikeTimesSingleSweep(d,t);

        % store results
        allSpikeTimes{e} = spiketimes;
        sweepDuration = t(end) - t(1);
        if sweepDuration > 0
            allFreqs(e) = apcount / sweepDuration;  % Hz
        else
            allFreqs(e) = NaN;
        end

        % plot
        supersubplot(f,4,4,counter);
        plot(t,d); hold on;
        if ~isempty(spiketimes)
            plot(spiketimes, ones(size(spiketimes))*mean(d), 'ko') % plot spikes on trace
        end
        xlabel('Time (s)');
        ylabel('Voltage (mV)');
        title(sprintf('Sweep %d: %d spikes, %.2f Hz', e, apcount, allFreqs(e)));
    end

    % save probe results
    results(P).probeID = p{P}.id();
    results(P).spikeTimes = allSpikeTimes;
    results(P).frequencies = allFreqs;
end

%% === Results summary ===
disp('Spike detection results:');
disp(results);
%% === Setup session ===
steve = false;

if steve
    session_folder = '/Users/vanhoosr/data/saya';
else
    session_folder = '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya';
end

% Open or create NDI session
S = ndi.session.dir(session_folder);

%% === Get the probes that are patch recordings ===
p = S.getprobes('type', 'patch-Vm');

%% === Parameters ===
N = 1;   % number of probes to process
results = struct(); % store spike times and firing frequency

for P = 1:N  % loop through probes
    et = p{P}.epochtable();
    f = figure;
    counter = 0;

    % allocate storage
    allSpikeTimes = cell(numel(et),1);
    allFreqs = nan(numel(et),1);

    for e = 1:numel(et)
        counter = counter + 1;

        % read data
        [d,t] = p{P}.readtimeseries(e,-inf,inf);

        % detect spikes
        [apcount, spiketimes] = getSpikeTimesSingleSweep(d,t);

        % store results
        allSpikeTimes{e} = spiketimes;
        sweepDuration = t(end) - t(1);
        if sweepDuration > 0
            allFreqs(e) = apcount / sweepDuration;  % Hz
        else
            allFreqs(e) = NaN;
        end

        % plot
        supersubplot(f,4,4,counter);
        plot(t,d); hold on;
        if ~isempty(spiketimes)
            plot(spiketimes, ones(size(spiketimes))*mean(d), 'ko') % plot spikes on trace
        end
        xlabel('Time (s)');
        ylabel('Voltage (mV)');
        title(sprintf('Sweep %d: %d spikes, %.2f Hz', e, apcount, allFreqs(e)));
    end

    % save probe results
    results(P).probeID = p{P}.id();
    results(P).spikeTimes = allSpikeTimes;
    results(P).frequencies = allFreqs;
end

%% === Results summary ===
disp('Spike detection results:');
disp(results);
