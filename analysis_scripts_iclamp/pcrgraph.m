%% TMEM16A qPCR plot: independent WKY vs SHR cultures
clear; clc; close all;

% Raw 2^-ΔΔCT values from table
WKY = [1.069550416, 1.000000000, 12.56602308];
SHR = [11.50635902, 4.198866734];

% Log2 transform for statistics
WKY_log2 = log2(WKY);
SHR_log2 = log2(SHR);

% Welch unpaired t-test on log2-transformed values
[~, p] = ttest2(WKY_log2, SHR_log2, 'Vartype', 'unequal');

% Summary stats for plotting raw fold change
mean_WKY = mean(WKY);
mean_SHR = mean(SHR);

sem_WKY = std(WKY, 0) / sqrt(numel(WKY));
sem_SHR = std(SHR, 0) / sqrt(numel(SHR));

% Descriptive fold difference from mean log2 difference
meanDiff_log2 = mean(SHR_log2) - mean(WKY_log2);
foldDiff = 2^(meanDiff_log2);

fprintf('WKY mean fold change = %.3f\n', mean_WKY);
fprintf('SHR mean fold change = %.3f\n', mean_SHR);
fprintf('WKY mean log2 = %.3f\n', mean(WKY_log2));
fprintf('SHR mean log2 = %.3f\n', mean(SHR_log2));
fprintf('Mean difference (log2) = %.3f\n', meanDiff_log2);
fprintf('Back-transformed fold difference = %.3f\n', foldDiff);
fprintf('Welch unpaired t-test p = %.4f\n', p);

%% Figure
figure('Color','w','Position',[200 200 520 500]); hold on;

% jittered x positions
x_wky = 1 + [-0.05 0 0.05];
x_shr = 2 + [-0.03 0.03];

% individual points
scatter(x_wky, WKY, 75, 'k', 'filled');
scatter(x_shr, SHR, 75, [0.35 0.35 0.35], 'filled');

% mean ± SEM
errorbar(1, mean_WKY, sem_WKY, 'k', 'LineStyle', 'none', 'LineWidth', 1.8, 'CapSize', 10);
errorbar(2, mean_SHR, sem_SHR, 'k', 'LineStyle', 'none', 'LineWidth', 1.8, 'CapSize', 10);

% mean markers
plot(1, mean_WKY, 'ks', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);
plot(2, mean_SHR, 'ks', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);

% axes
xlim([0.5 2.5]);
ylim([0 14]);
set(gca, 'XTick', [1 2], 'XTickLabel', {'WKY','SHR'}, ...
    'FontSize', 13, 'LineWidth', 1.2, 'Box', 'off');
ylabel('Relative TMEM16A expression (2^{-\\Delta\\DeltaC_T})', 'FontSize', 14);
title('TMEM16A expression in independent WKY and SHR cultures', 'FontSize', 15);

% annotation
text(1.5, 13.0, sprintf('Estimated difference = %.2f-fold', foldDiff), ...
    'HorizontalAlignment', 'center', 'FontSize', 12);
text(1.5, 12.1, sprintf('Welch unpaired t-test on log_2 values: p = %.4f', p), ...
    'HorizontalAlignment', 'center', 'FontSize', 11);

hold off;

% exportgraphics(gcf, 'TMEM16A_qPCR_unpaired.png', 'Resolution', 300);