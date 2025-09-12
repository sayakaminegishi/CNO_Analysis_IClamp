
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

N = 5;

for P=1:N; %numel(p)
    et = p{P}.epochtable();

    for e=1:numel(et)
        [d,t] = p{P}.readtimeseries(e,-inf,inf);
        % spike detection
        figure;
        plot(t,d);
        xlabel('Time(sec)');
        ylabel('Voltage');
    end
end

