
[P, TBL, STATS] = tableANOVA_WKY_VirusEffect_AllFitless_Ranked(bT);



fields = fieldnames(P);
fprintf('\n%-35s | %-10s\n', 'Metric', 'P-Value');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:numel(fields)
    metric = fields{i};
    fprintf('%-35s | %.4f\n', metric, P.(metric));
end
