% FR analyzer VERSION 3 - loading csv files and conducting TWO-WAY anova
% from /Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/analysis_scripts_iclamp/firingRateAnalyzer.m

% Load CSV fileshttps://www.brandeis.edu/library/#
wkynChrCNO = readtable('48h10umCNO-WKY_25sw_NEW.csv'); 
shrnChrCNO = readtable('48h10umCNO-SHR_25sw_NEW.csv');
wkynOnlyFR = readtable('WKYN_Only_NEW_CLEANED.csv'); 
shrnOnlyFR = readtable('SHRN_Only_NEW_CLEANED.csv');

% Add Treatment and Strain columns
wkynChrCNO.Treatment = repmat("CNO", height(wkynChrCNO), 1);
shrnChrCNO.Treatment = repmat("CNO", height(shrnChrCNO), 1);
wkynOnlyFR.Treatment = repmat("Control", height(wkynOnlyFR), 1);
shrnOnlyFR.Treatment = repmat("Control", height(shrnOnlyFR), 1);

wkynChrCNO.Strain = repmat("WKY", height(wkynChrCNO), 1);
wkynOnlyFR.Strain = repmat("WKY", height(wkynOnlyFR), 1);
shrnChrCNO.Strain = repmat("SHR", height(shrnChrCNO), 1);
shrnOnlyFR.Strain = repmat("SHR", height(shrnOnlyFR), 1);

% Combine all data into one table
T_all = [wkynChrCNO; wkynOnlyFR; shrnChrCNO; shrnOnlyFR];

% Convert grouping variables to categorical
T_all.Strain = categorical(T_all.Strain);
T_all.Treatment = categorical(T_all.Treatment);


% TWO-WAY ANOVA for Rm
fprintf('TWO-WAY ANOVA for Rm:\n');
[p_rm_tbl, anova_rm_tbl, stats_rm] = anovan(T_all.Rm, ...
    {T_all.Strain, T_all.Treatment}, ...
    'model', 'interaction', ...
    'varnames', {'Strain', 'Treatment'}, ...
    'display', 'off'); % suppress full table output

fprintf('p (Strain): %.4f\n', p_rm_tbl(1));
fprintf('p (Treatment): %.4f\n', p_rm_tbl(2));
fprintf('p (Interaction): %.4f\n', p_rm_tbl(3));
disp(' ');

% TWO-WAY ANOVA for maxFiringRate
fprintf('TWO-WAY ANOVA for maxFiringRate:\n');
[p_mfr_tbl, anova_mfr_tbl, stats_mfr] = anovan(T_all.maxFiringRate, ...
    {T_all.Strain, T_all.Treatment}, ...
    'model', 'interaction', ...
    'varnames', {'Strain', 'Treatment'}, ...
    'display', 'off');
fprintf('p (Strain): %.4f\n', p_mfr_tbl(1));
fprintf('p (Treatment): %.4f\n', p_mfr_tbl(2));
fprintf('p (Interaction): %.4f\n', p_mfr_tbl(3));
disp(' ');


% TWO-WAY ANOVA for Rb
fprintf('TWO-WAY ANOVA for Rb:\n');
[p_rb_tbl, anova_rb_tbl, stats_rb] = anovan(T_all.Rb, ...
    {T_all.Strain, T_all.Treatment}, ...
    'model', 'interaction', ...
    'varnames', {'Strain', 'Treatment'}, ...
    'display', 'off');

fprintf('p (Strain): %.4f\n', p_rb_tbl(1));
fprintf('p (Treatment): %.4f\n', p_rb_tbl(2));
fprintf('p (Interaction): %.4f\n', p_rb_tbl(3));
disp(' ');

% TWO-WAY ANOVA for threshold
fprintf('TWO-WAY ANOVA for Rb:\n');
[p_rb_tbl, anova_rb_tbl, stats_rb] = anovan(T_all.Threshold, ...
    {T_all.Strain, T_all.Treatment}, ...
    'model', 'interaction', ...
    'varnames', {'Strain', 'Treatment'}, ...
    'display', 'off');

fprintf('p (Strain): %.4f\n', p_rb_tbl(1));
fprintf('p (Treatment): %.4f\n', p_rb_tbl(2));
fprintf('p (Interaction): %.4f\n', p_rb_tbl(3));
disp(' ');
