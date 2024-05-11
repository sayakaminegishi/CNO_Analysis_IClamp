function alpha2 = find_alpha2(skewness_val)

% this function returns the alpha 2 value corresponding to a particular
% skewnewss of an ISI histogram of interest. The scale was formed by Kapucu
% et al. Alpha2 value is multiplied by ISI_burst_threshold_prelim (from
% cnoscript.m) to find the ISI threshold for burst-related spikes (i.e. spikes before or after burst).

% Original Script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: Oct 6 2023

if (skewness_val < 1)
    alpha2 = 0.5;
elseif (skewness_val >= 1 & skewness_val < 4)
    alpha2 = 0.5;
elseif (skewness_val >= 4 & skewness_val < 9)
    alpha2 = 0.3;
else
    alpha2 = 0.1;
end
end