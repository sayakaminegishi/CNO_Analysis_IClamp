
% S = ndi.session('/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya');
% 
% S = S.getprobes('type', 'patch-Vm');
% subjectTable = ndi.fun.docTable.subject(S);

%% === Setup session ===
% Change this to your data folder
session_folder = '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya';

% Open or create NDI session
S = ndi.session.dir(session_folder);

%% === Scan for ABF files ===
abf_files = dir(fullfile(session_folder, '*.abf'));
nFiles = length(abf_files);

if nFiles == 0
    warning('No ABF files found in folder.');
end

%% === Create and register probes ===
for i = 1:nFiles
    abf_name = abf_files(i).name;
    
    % Create metadata for probe
    doc_struct = struct( ...
        'name', abf_name, ...             % name of probe = filename
        'type', 'patch-Vm', ...           % set probe type
        'description', 'Patch-clamp recording' ...
    );
    doc = ndi.document(doc_struct);
    
    % Create probe object
    p = ndi.probe(S, doc);
    
    % Register probe in session
    S = S.newprobe(p);
end

%% === Check probes by type ===
probes = S.getprobes('type','patch-Vm');
disp(['Registered ' num2str(length(probes)) ' patch-Vm probes:']);
for i = 1:length(probes)
    disp(probes{i}.name);
end


%% === Build subject/probe table in NDI v1 ===

% Assume S is your ndi.session object
docs = S.database_search();   % get all documents in the session
nDocs = length(docs);

% Initialize cell arrays
subject_list = cell(nDocs,1);
probe_name_list = cell(nDocs,1);
probe_type_list = cell(nDocs,1);
file_name_list = cell(nDocs,1);

for i = 1:nDocs
    doc_struct = docs{i}.document_struct;  % extract the metadata
    
    % Extract fields (use try/catch if some fields might not exist)
    try
        subject_list{i} = doc_struct.subject;
    catch
        subject_list{i} = 'unknown';
    end
    
    try
        probe_name_list{i} = doc_struct.name;
    catch
        probe_name_list{i} = 'unnamed';
    end
    
    try
        probe_type_list{i} = doc_struct.type;
    catch
        probe_type_list{i} = 'unknown';
    end
    
    try
        file_name_list{i} = doc_struct.filename;  % if you stored filename in metadata
    catch
        file_name_list{i} = '';
    end
end

% Create table
subjectTable = table(subject_list, probe_name_list, probe_type_list, file_name_list, ...
                     'VariableNames', {'Subject','ProbeName','Type','Filename'});

% Display table
disp(subjectTable);
