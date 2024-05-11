function [burst_AP_list, single_AP_list] = categorize_APvsAP(AP_list)

%this function categorizes each AP in AP_list as either being single or
%being in a burst WITH RESPECT TO ANOTHER AP (REGARDLESS of whether it's
%part of a burst with some non-AP spike).

% AP_list = list of all AP locations to categorize 
% burst_AP_list = time locations of APs that are in a burst with another AP
% single_AP_list = time locations of APs that are not in a burst with another AP

% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: August 22 2023
w = 1000;
countburst = 0;
countsingle = 0;
burst_AP_list = [];
single_AP_list = [];
for i = 1:numel(AP_list)
    if(i == 1)
        if (AP_list(i + 1) - AP_list(i) < w)
            %AP is part of a burst with another AP
            countburst = countburst + 1;
            burst_AP_list(countburst) = AP_list(i);
        else
            %AP is single with respect to another AP
            countsingle = countsingle + 1;
            single_AP_list(countsingle) = AP_list(i);
        end
    
   
    elseif(i >= 2 & i <numel(AP_list))
        if (AP_list(i + 1) - AP_list(i) < w) || (AP_list(i) - AP_list(i -1) < w)
            %AP is part of a burst with another AP
            countburst = countburst + 1;
            burst_AP_list(countburst) = AP_list(i);
        else
            %AP is single with respect to another AP
            countsingle = countsingle + 1;
            single_AP_list(countsingle) = AP_list(i);
        end

    else
        %if this is the last spike in AP_list
        if (AP_list(i) - AP_list(i -1) < w)
            %AP is part of a burst with another AP
            countburst = countburst + 1;
            burst_AP_list(countburst) = AP_list(i);
        else
            %AP is single with respect to another AP
            countsingle = countsingle + 1;
            single_AP_list(countsingle) = AP_list(i);
        end
    end

end


end