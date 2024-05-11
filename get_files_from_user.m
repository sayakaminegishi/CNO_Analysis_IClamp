function get_files_from_user(dirname)

%function to allow user to select files of interest (to analyze), and saves
%the files in the pre-made 'tempdata' folder. 

% Created by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: 5/11/2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get files
[filename,pathname] = uigetfile('*.abf',...
        'Select One or More Files', ...
        'MultiSelect', 'on'); %prompt user to select multiple files
  
    %move selected data to folder temporarily
        pdest   = fullfile(dirname, filesep, 'tempdata');

    if isequal(filename,0) || isequal(pathname,0)
        disp('User pressed cancel');
    else
        if isa(filename, "char")  %if only one file
              str = string(filename);
              sourceFile = fullfile(pathname, filename);
                destFile   = fullfile(pdest, filename);  
                copyfile(sourceFile, destFile);

        else %if multiple files selected
            str = sprintf('%s; ', filename{:}); % Convert string vector to a single string with newline characters
 
            for k = 1:numel(filename)
                sourceFile = fullfile(pathname, filename{k});
                destFile   = fullfile(pdest, filename{k});  
                copyfile(sourceFile, destFile);
       
            end
        end

        disp("Files to analyze: " + str); %show which files will be analyzed
        
    end

end
