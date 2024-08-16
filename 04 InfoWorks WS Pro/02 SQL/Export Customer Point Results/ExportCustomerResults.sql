//Object Type: Customer Points

SELECT
reference AS 'Key',
identifier AS 'Identifier',
sim.pnavg AS 'Average Pressure',
sim.pnmax AS 'Max Pressure',
sim.pnmin AS 'Min Pressure'
INTO FILE "C:\Temp\MyResults.csv"
