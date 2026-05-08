



Contents
Overview	3
WHEN Clauses	3
GIS Export	4
Aggregate Functions	5
ALL	5
ANY	5
AVG	5
COUNT	5
DURATION	5
EARLIEST	5
FIRST	5
INTEGRAL	5
LAST	5
LATEST	6
MAX	6
MIN	6
SUM	6
WHENEARLIEST	6
WHENLATEST	6
WHENMAX	6
WHENMIN	6



Overview
The time varying SQL in ICM allows one to perform SQL queries on time varying (i.e. non-summary) results for simulations.
These results are accessed via aggregate functions in a similar way to one-to-many links or arrays of values. 
The aggregate functions used are:
* ALL
* ANY
* AVG
* COUNT
* DURATION
* EARLIEST
* FIRST
* INTEGRAL
* LAST
* LATEST
* MAX
* MIN
* SUM
* WHENEARLIEST
* WHENLATEST
* WHENMAX
* WHENMIN
Their specific meanings will be covered later in the document.
WHEN Clauses
It is possible to limit the number of time-steps used in the time varying aggregate functions by use of a WHEN clause e.g.
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no = 20
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_start = #01/01/2013 12:30#
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no = tsr.timesteps 
SELECT MAX(tsr.flooddepth) WHEN tsr.timestep_no > 20
If you use a WHEN clause then all the above aggregate functions perform their calculations only on the time-steps selected by the WHEN clause. 
Notice that you are still aggregating even if you are only aggregating over one time step as in this case, therefore you still have to use an aggregate function. If you have one time-step then many of the aggregate functions will give the value of the result at that time-step e.g. MAX(tsr.val). 


The field values that can be used in WHEN clauses are as follows:
* tsr.timestep_no - the number of the timestep, with 1 being the first timestep as an integer
* tsr.timestep_start - the time of the start of the timestep as a date or number - see below
* tsr.timesteps - the number of timesteps in the simulation as an integer
* tsr.timestep_duration - the duration of the timestep as a number of minutes
* tsr.sim_start - the time of the start of the simulation as a date or number - see below
* tsr.sim_end - the time of the end of the simulation as a date or number - see below
If the simulation uses 'relative times' then timestep_start, sim_start and sim_end return a number of minutes from the notional time 0, otherwise the date and time is returned as a 'date' value. 
When using relative times, if you wish to specify a time that is not an exact number of minutes exactly you will need to use calculations on the lines of 'WHEN tsr.timestep_start = 746+(1/60)' to get the timestep at 746 minutes and 1 second into the simulation
The expression in the WHEN clause can include the above field values along with scalar and list variables e.g. you can list a number of timesteps you are interested in and then use the list function 
The results will only be processed for timesteps for which the WHEN clause is true. 

GIS Export
It is possible for the expressions used in the export of 2D elements to GIS files to include time varying expressions. These expressions can also include WHEN clauses.
In the GIS export the results will only be processed for any given time step if that time-step is required based on the WHEN clauses i.e. if all the expressions have WHEN clauses then the results will only be processed for time-steps where at least one the WHEN clauses is true. This means, of course, that if any of the expressions don't have WHEN clauses the results will be process for all time-steps. 
It is important to note that the time varying results in SQL operate on the results in the results files. Therefore if you were to evaluate MAX(tsr.depth2d) this may not be the same as the maximum value stored in the results files, which is the maximum at all computational time-steps as opposed to the maximum value at all results time-steps.
This functionality is not available for expressions in themes due to the length of time required to perform these calculations. 



Aggregate Functions
ALL
Returns true if the expression is true for all timesteps under consideration. 
ALL(tsr.depth2d>1.0) will return true if the depth is greater than 1 for all timesteps under consideration.
ANY
Returns true if the expression is true for at least one of the timesteps under consideration.
AVG
In this context AVG does not simply return an average of the values at all the timesteps. Since the length of timesteps can vary, AVG returns the time weighted average i.e the sum of the values for all timesteps except the last multiplied by the duration of that timestep, divided by the total duration. 
The results are treated as step functions i.e. the results are assumed to remain constant for the duration of each timestep. 
COUNT
Returns the number of timesteps under consideration for which the expression is true.
COUNT(tsr.depth2d>1) will return the number of timesteps under consideration for which depth2d>1.
DURATION
Will return the length time in minutes for which the expression is true for timesteps under consideration, not necessarily contiguous. Because this returns the duration for which the expression is true rather than an actual point in time, the value is always a number rather than possibly being a date.
DURATION(tsr.depth)>30
EARLIEST
Returns the first non-null value of an expression. This is only likely to give a meaningful answer if used in combination with the IIF function e.g. to find the first surcharge value greater than 0.5.
SELECT oid,EARLIEST(IIF(tsr.surcharge>0.5,tsr.surcharge,NULL))
FIRST
Returns the value of the expression for the first timestep under consideration.
INTEGRAL
This returns the sum of the value of the expression at each timestep under consideration multiplied by the length of the timestep in minutes. Since the SQL engine is not aware of the units in which values are being reported it is the responsibility of the user to ensure that any required multiplication factor is applied. This is effectively a step function.
LAST
Returns the value of the expression for the last timestep under consideration.
LATEST
Returns the latest time for which the expression is true.
MAX
MAX(tsr.pressure) will return the maximum pressure
MIN
MIN(tsr.pressure) will return the minimum pressure
SUM
By contrast to INTEGRAL, SUM simply sums all the values at all the timesteps. This will almost certainly only tell you something useful if all the timesteps are the same length.
WHENEARLIEST
Returns the earliest time for which the expression is true e.g.
WHENEARLIEST(tsr.head<150) will return the first time at which the head is less than 150
WHENLATEST
Returns the last non-null value of an expression. As with WHENEARLIEST this is only likely to give a meaningful answer if used in combination with the IIF function.
WHENMAX
Returns the time at which the expression is at its maximum. If there is more than one timestep at which the expression is at the maximum value this will report the earliest time.
e.g. WHENMAX(tsr.Surcharge)=#16/01/1999 05:35:00#
WHENMIN
Returns the time at which the expression is at its minimum. If there is more than one timestep at which the expression is at the minimum value this will report the earliest time.
The aggregate functions EARILEST, LATEST, WHENEARLIEST, WHENLATEST, WHENMAX and WHENMIN will return dates if the simulation is using absolute times or numbers of minutes if the simulation is using relative times. 
The functions AVG, INTEGRAL and SUM will not consider the final timestep in the simulation because the final timestep does not a known duration since timestep lengths can vary. This only applies to the the final timestep in the simulation, not to the final timestep under consideration.

1



