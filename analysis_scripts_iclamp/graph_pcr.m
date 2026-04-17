% 1. Define the data from your table
% WKY values: Expt 1, Expt 2, Expt 3
wky_data = [1.069550416, 1, 12.56602308];

% SHR values: Expt 1, Expt 2, Expt 3 (using NaN for N/A)
shr_data = [11.50635902, 4.198866734, NaN];

% 2. Calculate Means and Standard Error of the Mean (SEM)
% 'omitnan' ignores the N/A value in the SHR group
wky_mean = mean(wky_data, 'omitnan');
shr_mean = mean(shr_data, 'omitnan');

wky_sem = std(wky_data, 'omitnan') / sqrt(sum(~isnan(wky_data)));
shr_sem = std(shr_data, 'omitnan') / sqrt(sum(~isnan(shr_data)));

% 3. Create the Plot
figure('Color', 'w');
hold on;

% Define categories and means
means = [wky_mean, shr_mean];
errors = [wky_sem, shr_sem];
labels = {'WKY', 'SHR'};

% Plot the Bars
b = bar(1:2, means, 'FaceColor', 'flat', 'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.2);
b.CData(1,:) = [0.4 0.6 0.8]; % Light Blue for WKY
b.CData(2,:) = [0.9 0.4 0.4]; % Light Red for SHR

% Add Error Bars
errorbar(1:2, means, errors, 'k', 'linestyle', 'none', 'LineWidth', 1.5, 'CapSize', 15);

% 4. Add Individual Data Points (Stripplot)
% This shows the distribution of your 3 experiments
scatter(ones(1,3), wky_data, 40, 'k', 'filled', 'MarkerFaceAlpha', 0.6);
scatter(2*ones(1,3), shr_data, 40, 'k', 'filled', 'MarkerFaceAlpha', 0.6);

% 5. Formatting
ylabel('Relative Expression (2^{-\Delta\Delta C_T})', 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTick', 1:2, 'XTickLabel', labels, 'FontSize', 11);
title('qPCR Gene Expression Analysis', 'FontSize', 14);
grid on;
ax = gca;
ax.GridLineStyle = '--';
ax.GridAlpha = 0.3;

hold off;