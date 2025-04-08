%FR analyzer - loading csv filse and conducting anova
%from /Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/analysis_scripts_iclamp/firingRateAnalyzer.m

%import files produced by firingRateAnalyzer.m
% Use readtable, not readmatrix
wkynChrCNO = readtable('wkynChrCNO3.csv'); %control, treatment 
shrnChrCNO = readtable('shrnChrCNO3.csv'); %test, treatment
wkynOnlyFR = readtable('wkynOnly3.csv'); %control, control
shrnOnlyFR = readtable('shrnOnly3.csv'); %test, control

% Label treatment groups
shrnOnlyFR.Treatment = repmat("Control", height(shrnOnlyFR), 1);
shrnChrCNO.Treatment = repmat("CNO", height(shrnChrCNO), 1);

% Combine SHR data
T_shr = [shrnOnlyFR; shrnChrCNO];


%%%%% FIND EFFECT OF CNO ON RM, MFR, AND RB WITHIN SHR RATS %%%%%%%
% Run one-way ANOVA on Rm
[p_rm, tbl_rm, stats_rm] = anova1(T_shr.Rm, T_shr.Treatment);

% Run one-way ANOVA on MaxFiringRate
[p_mFR, tbl_mFR, stats_mFR] = anova1(T_shr.maxFiringRate, T_shr.Treatment);

% Run one-way ANOVA on Rb
[p_rb, tbl_rb, stats_rb] = anova1(T_shr.Rb, T_shr.Treatment);


%%%%%%%%% FIND EFFECT OF STRAIN ON RM, MFR AND RB IN CNO-TREATED RATS%%%%%

% Label strain groups
wkynChrCNO.Strain = repmat("WKY", height(wkynChrCNO), 1);
shrnChrCNO.Strain = repmat("SHR", height(shrnChrCNO), 1);

% Combine CNO-treated groups only
T_cno = [wkynChrCNO; shrnChrCNO];

% Rm ANOVA
[p_rmT, tbl_rmT, stats_rmT] = anova1(T_cno.Rm, T_cno.Strain, 'off');

% mFR anova
[p_mfrT, tbl_mfrT, stats_mfrT] = anova1(T_cno.mFR, T_cno.Strain, 'off');

% Rb
[p_rbT, tbl_rbT, stats_rbT] = anova1(T_cno.Rb, T_cno.Strain, 'off');

% Display p-values
fprintf('p (Rm): %.4f\n', p_rmT);
fprintf('p (mFR): %.4f\n', p_mfrT);
fprintf('p (Rb): %.4f\n', p_rbT);







