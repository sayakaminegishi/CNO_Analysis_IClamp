
# CNO_Analysis_IClamp
scripts for CNO experiments at Birren lab. 

################
## Get AP counts for a cell:
INSTRUCTIONS: Download the zip file for this whole repository. Unzip on your computer and open avgAPCounter9.m. Click Run. It will direct you to pick your abf files for the cell, where each file represents one run of the protocol (one set of sweeps) for that cell. In the script avgAPCounter.m, please specify the name of the output excel file. Make sure you're picking a set of files for only ONE CELL.

## Run ANOVA
freqAnalyzer2.m and freqAnalyzerTwoWayAnova.m performs a one- and two-way ANOVA test respectively to compare whether there is a statistically significant difference in AP counts between the groups.




## Instructions:
1. Open'cnomain.m'.
2. Define the sweep numbers for each section (control, treatment, washout) as a vector, as [start_sweep:end_sweep].
3. Define the output excel file names, which will contain the summary of the analysis.
4. Click 'Run'


** Figures 2, 4, and 6 show the traces for the control, treatment, and washout groups respectively **



For any questions or concerns, please feel free to contact me at minegishis@brandeis.edu
