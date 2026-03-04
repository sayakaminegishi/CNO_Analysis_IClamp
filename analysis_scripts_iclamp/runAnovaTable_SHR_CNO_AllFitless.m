close all

[P, TBL, STATS, C, M, gnames] = tableANOVA_SHR_CNO_AllFitless(bT);


fields = fieldnames(P);
fprintf('\n%-35s | %-10s\n', 'Metric', 'P-Value');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:numel(fields)
    metric = fields{i};
    fprintf('%-35s | %.4f\n', metric, P.(metric));
end
