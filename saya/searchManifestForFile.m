function T_out = searchManifestForFile(T, fileManifest)

for i=1:height(T)
    isFileNow = isfile([T.folderPath{i} '/' T.filename{i}]);
    if ~isFileNow
        match_count = 0;
        last_match = 0;
        % search manifest
        for j=1:numel(fileManifest)
            [par,fname,ext]=fileparts(fileManifest{j});
            if strcmp(T.filename{i},[fname ext])
                match_count = match_count + 1;
                last_match = par;
            end
        end
        if match_count == 1
            T.folderPath{i} = last_match;
        elseif match_count > 1
            T.folderPath{i} = 'multiple';
        else
            T.folderPath{i} = 'unknown';
        end
    end
end

T_out = T;