# CNO_Analysis_IClamp
scripts for CNO experiments at Birren lab. 

## Instructions:
1. Open 'avgAPCounter_FINAL25sw.m' (for files with 25 sweeps) or ''avgAPCounter_FINAL28sw.m' (for files with 28 sweeps)

2. change 'outputfile',ungroupedTableName, and 'outputFilename_SEM' in the script, in the section under 'USER INPUT!!!!'. 'outputfile' is the table containing the AP Counts of each CELL (trials for the same cell are grouped together), and ungroupedTableName gives the ap counts of all trials (not grouped by cell). outputFilename_SEM gives the mean and standard error of the points for each cell.

3.Click 'Run'
4.Choose the set of files from a group that you want to analyze. Eg.if you want to see the AP counts from a group of SHR neurons, select those cells (make sure each cell is in a separate abf file).
The program will show you:
- a boxplot for each sweep with the median AP Count and IQRs
- a scatterplot of the AP Counts for each current injected for each cell, with - the mean for each current level plotted with SEM bars.
- a table with AP counts for each file, for each current level (saved as the excel name that you wrote for outputfile)
a table with mean AP count and their SEM values for each current level, stored as an excel file with the name that you specified in outputFilename_SEM.

Change the array of injected currents to match your specific protocol.



For any questions or concerns, please feel free to contact me at minegishis@brandeis.edu
