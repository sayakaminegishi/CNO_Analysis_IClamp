function unmatchedFile = searchFileForManifest(T, fileManifest)

unmatchedFile = {};

for i=1:numel(fileManifest)
    [par,fname,ext] = fileparts(fileManifest{i});
    matches = find(strcmp(T.folderPath,par) & strcmp(T.filename,[fname ext]));
    if isempty(matches)
        unmatchedFile{end+1} = fileManifest{i};
    end;
end

