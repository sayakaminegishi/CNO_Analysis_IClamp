
% S = ndi.session('/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya');
% 
% subjectTable = ndi.fun.docTable.subject(S);

%% === Setup session ===
% Change this to your data folder
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

%% === Plot the data from several epochs of first N probes ===

N = 1;

for P=1:N; %numel(p)
    et = p{P}.epochtable();
    f = figure;
    counter = 0;

    for e=1:numel(et)
        counter = counter+1;
        supersubplot(f,4,4,counter);
        [d,t] = p{P}.readtimeseries(e,-inf,inf);
        % spike detection
       
        plot(t,d);
        xlabel('Time(sec)');
        ylabel('Voltage');
        [apcount, spiketimes] = getSpikeTimesSingleSweep(d,t);
        supersubplot(f,4,4,counter);
        hold on;
        if ~isempty(spiketimes)
            plot(spiketimes, 1, 'ko')
        end

    end
end
%%%%%%%%%%%%%%%%%%
