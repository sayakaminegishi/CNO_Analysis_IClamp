# CNO_Analysis_IClamp
scripts for CNO experiments at Birren lab. 

## Instructions:
1. Open'cnomain.m'.
2. Define the sweep numbers for each section (control, treatment, washout) as a vector, as [start_sweep:end_sweep].
3. Define the output excel file names, which will contain the summary of the analysis.
4. Click 'Run'


** Figures 2, 4, and 6 show the traces for the control, treatment, and washout groups respectively **

################
## Get AP counts for a cell:
INSTRUCTIONS: save getAPCountForTrial3.m in the same directory as the file avgAPCounter3.m.
Then click Run on avgAPCounter3.m. It will direct you to pick your abf files for the cell, where each file represents one run of the protocol (one set of
sweeps) for that cell. It will save the AP counts in a table called
APCounts.xlsx in the same directory as this script.


For any questions or concerns, please feel free to contact me at minegishis@brandeis.edu
