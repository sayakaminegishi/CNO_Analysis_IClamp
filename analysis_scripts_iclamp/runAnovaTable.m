close all
%[p, tbl, stats] = tableANOVA2(bT);
[p, tbl, stats] = currentAtFirstNonZeroResponse(bT);
% [p, tbl, stats] = suppressionIndexANOVA(bT);
% 
% varnames = T.Properties.VariableNames;
% 
% fitlessCols = bT.Properties.VariableNames( ...
%     contains(bT.Properties.VariableNames, 'fitless') );
% afterFitless = extractAfter(fitlessCols, 'fitless');
% 
% for i = 1:numel(afterFitless)
%     disp(afterFitless{i})
% end
