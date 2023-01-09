# Calculate pipe capacity using Kutter's formula

The calculation is based on the formula shown in the link below,

http://www.sd-w.com/channel_flow/kutters_formula/

```
Q = a * c * [R * S]^(1/2)
c =	(41.65 + 0.00281/S + 1.811/n)/(1 + [41.65 + 0.00281/S] * n/[R^(1/2)])

units:
-a, area: ft^2
-R, hydraulic radius: ft
-n, manning's n: na
-S, slope: ft/ft
-Q, flow: cfs
-velocity: ft/s

```

* make sure the units is cfs in ICM, Tools->Options->Set Default Units = Cubic Feet
* open your network and validate it to update the capacity (full pipe capacity using manning's equation)
* create a new query, and paste in the code
* run the code to view the summary the results are saved in 
  * user_number_1: full pipe capaicty
  * user_number_2: water depth at 4/3 dimeter pipe capaicty
  * user_number_1: half pipe capaicty



![](./kutter%20formula.png)
