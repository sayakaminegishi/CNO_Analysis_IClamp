%FR analyzer VERSION 2 - loading csv filse and conducting singkle anovas
%from /Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/analysis_scripts_iclamp/firingRateAnalyzer.m

% Load CSV files
wkynChrCNO = readtable('wkynChrCNO3.csv'); 
shrnChrCNO = readtable('shrnChrCNO3.csv');
wkynOnlyFR = readtable('wkynOnly3.csv'); 
shrnOnlyFR = readtable('shrnOnly3.csv');

% Add Treatment and Strain columns to all tables 
wkynChrCNO.Treatment = repmat("CNO", height(wkynChrCNO), 1);
shrnChrCNO.Treatment = repmat("CNO", height(shrnChrCNO), 1);
wkynOnlyFR.Treatment = repmat("Control", height(wkynOnlyFR), 1);
shrnOnlyFR.Treatment = repmat("Control", height(shrnOnlyFR), 1);

wkynChrCNO.Strain = repmat("WKY", height(wkynChrCNO), 1);
wkynOnlyFR.Strain = repmat("WKY", height(wkynOnlyFR), 1);
shrnChrCNO.Strain = repmat("SHR", height(shrnChrCNO), 1);
shrnOnlyFR.Strain = repmat("SHR", height(shrnOnlyFR), 1);

% Combine SHR data for within-strain ANOVA
T_shr = [shrnOnlyFR; shrnChrCNO];

% One-way ANOVA within SHR: CNO effect
[p_rm, tbl_rm, stats_rm] = anova1(T_shr.Rm, T_shr.Treatment, 'off');
[p_mFR, tbl_mFR, stats_mFR] = anova1(T_shr.maxFiringRate, T_shr.Treatment, 'off');
[p_rb, tbl_rb, stats_rb] = anova1(T_shr.Rb, T_shr.Treatment, 'off');

% Display p-values
fprintf('Effect of CNO within SHR:\n');
fprintf('p (Rm): %.4f\n', p_rm);
fprintf('p (maxFiringRate): %.4f\n', p_mFR);
fprintf('p (Rb): %.4f\n', p_rb);
display(' '); %for formatting purposes

% Combine CNO-treated groups across strains
T_cno = [wkynChrCNO; shrnChrCNO];

% One-way ANOVA for strain effect under CNO
[p_rmT, tbl_rmT, stats_rmT] = anova1(T_cno.Rm, T_cno.Strain, 'off');
[p_mfrT, tbl_mfrT, stats_mfrT] = anova1(T_cno.maxFiringRate, T_cno.Strain, 'off');
[p_rbT, tbl_rbT, stats_rbT] = anova1(T_cno.Rb, T_cno.Strain, 'off');

% Display p-values
fprintf('Strain effect, under CNO treatment:\n');
fprintf('p (Rm): %.4f\n', p_rmT);
fprintf('p (maxFiringRate): %.4f\n', p_mfrT);
fprintf('p (Rb): %.4f\n', p_rbT);

%%%%%%%%%%%%%%%%%%%%%
% Combine WKY data for within-strain ANOVA
T_wky = [wkynOnlyFR; wkynChrCNO];

% One-way ANOVA within WKY: CNO effect
[p_rmW, tbl_rmW, stats_rmW] = anova1(T_wky.Rm, T_wky.Treatment, 'off');
[p_mFRW, tbl_mFRW, stats_mFRW] = anova1(T_wky.maxFiringRate, T_wky.Treatment, 'off');
[p_rbW, tbl_rbW, stats_rbW] = anova1(T_wky.Rb, T_wky.Treatment, 'off');

% Display p-values
display(' ') %formatting
fprintf('Effect of CNO within WKY:\n');
fprintf('p (Rm): %.4f\n', p_rmW);
fprintf('p (maxFiringRate): %.4f\n', p_mFRW);
fprintf('p (Rb): %.4f\n', p_rbW);
display(' '); %for formatting purposes

% compare control groups across strains
C_cno = [wkynOnlyFR; shrnOnlyFR];

% One-way ANOVA for strain effect under CNO
[p_rmC, tbl_rmC, stats_rmC] = anova1(C_cno.Rm, C_cno.Strain, 'off');
[p_mfrC, tbl_mfrC, stats_mfrC] = anova1(C_cno.maxFiringRate, C_cno.Strain, 'off');
[p_rbC, tbl_rbC, stats_rbC] = anova1(C_cno.Rb, C_cno.Strain, 'off');

% Display p-values
fprintf('Strain effect, under control conditions:\n');
fprintf('p (Rm): %.4f\n', p_rmC);
fprintf('p (maxFiringRate): %.4f\n', p_mfrC);
fprintf('p (Rb): %.4f\n', p_rbC);

