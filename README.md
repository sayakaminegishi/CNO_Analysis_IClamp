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
INSTRUCTIONS: Download the zip file for this whole repository. Unzip on your computer and open avgAPCounter8.m. SPECIFY FILE NAME OF THE OUTPUT EXCEL FILE (with .xlsx ending). Click Run. It will direct you to pick your abf files for the cell, where each file represents one run of the protocol (one set of sweeps) for that cell. Enter the start time of the pulse in ms and the duration of the pulse when prompted. It will save the AP counts for each sweep, plus the average, in a table with your excel name, in the same directory as this script. Make sure you're picking a set of files for only ONE CELL.


For any questions or concerns, please feel free to contact me at minegishis@brandeis.edu
