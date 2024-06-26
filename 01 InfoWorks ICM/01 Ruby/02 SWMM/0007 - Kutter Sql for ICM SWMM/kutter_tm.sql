/*1.	Kutters Formula Calculation:
For full capacity Kutter Calculation 
http://www.sd-w.com/channel_flow/kutters_formula/

Q = a * c * [R * S]^(1/2)
c =	(41.65 + 0.00281/S + 1.811/n)/(1 + [41.65 + 0.00281/S] * n/[R^(1/2)])

units:
-a, area: ft^2
-R, hydraulic radius: ft
-n, manning's n: na
-S, slope: ft/ft
-Q, flow: cfs
-velocity: ft/s

Assumptions in the calculation

- circular pipes using the following units
  - conduit_height, inch
  - gradient, 100*ft/ft
  - R = pi*r^2/(2*pi*r) = d/4

capacity calculated based on the water depth in pipe

*/

/*full pipe capacity
a = (((conduit_height/12)^2) * 0.78539) //a = pi*(d/2)^2 , 0.78539=pi/4
R (hydraulic radius) = pi*r^2/(2*pi*r) = d/4 = (conduit_height/48)
c = ((41.65+0.00281/(gradient/100)+1.811/bottom_roughness_N)/(1+(41.65+0.00281/(gradient/100))*bottom_roughness_N/((conduit_height/48)^0.5)))
(r*s)^(1/2) = (((conduit_height/48)*gradient/100)^0.5); */
SET user_number_1 = (((conduit_height/12)^2) * 0.78539)*((41.65+0.00281/(gradient/100)+1.811/bottom_roughness_N)/(1+(41.65+0.00281/(gradient/100))*bottom_roughness_N/((conduit_height/48)^0.5)))*(((conduit_height/48)*gradient/100)^0.5); 
  
  
  
/*For depth = 3/4 pipe diameter capacity Kutter Calculation 
theta = 120 degree/2.0944 rad, water is r/2 from top of the pipe
a = pi*r^2 - r^2(theta - sin(theta))/2
P = 2pi*r - r*theta 
R = a/P
a = ((((conduit_height/12)^2) * 0.78539)-((conduit_height/24)^2)*((2.0944-SIN(2.0944))/2))
R (hydraulic radius) = conduit_height/39.78
*/
SET user_number_2 = ((((conduit_height/12)^2) * 0.78539)-((conduit_height/24)^2)*((2.0944-SIN(2.0944))/2))*((41.65+0.00281/(gradient/100)+1.811/bottom_roughness_N)/(1+(41.65+0.00281/(gradient/100))*bottom_roughness_N/((conduit_height/39.78)^0.5)))*(((conduit_height/39.78)*gradient/100)^0.5); 
  
  
  
/* For pipe half full, it is half the capacity */
SET user_number_3= 0.5*user_number_1;
  
  
/*	Kutters Table Results Compared to ICM:
capacity is calculated using manning's equation for full pipe flow after the model is validated.
Assumptions:
- flow reported in cfs

*/
SELECT 
conduit_height as 'Diameter', 
gradient/100 as 'Slope', 
bottom_roughness_N as 'Mannings N Roughness', 
capacity as 'ICM Calculated Capacity (CFS)', 
user_number_1 as 'Kutters Full Capacity (CFS)', 
user_number_2 as 'Kutters 3/4 Capacity (CFS)', 
user_number_3 as 'Kutters 1/2 Capacity (CFS)' 
  
GROUP BY oid AS 'PIPE ID';