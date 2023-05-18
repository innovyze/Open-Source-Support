# InfoWorks SWMM Networks and the Length of Links

These Ruby scripts are intended to work with the InfoWorks SWMM network and InfoWorks Networks

##SW is SWMM
##HW is ICM or its grandfather HydroWorks

There Ruby codes find the basic stats for pipe lenghts = importand for tje SWMM Engine but not so much for ICM InfoWorks

  printf("%-440s %-0.2f\n", "Minimum link length", link_lengths.min)
  printf("%-440s %-0.2f\n", "Maximum link length", link_lengths.max)
  printf("%-44s %-0.2f\n", "Threshold length for lowest 10%", threshold_length)
  printf("%-44s %-0.2f\n", "Median link length (50th percentile)", median_length)
  printf("%-44s %-d\n", "Number of links below threshold", selected_links.length)
  printf("%-44s %-d\n", "Total number of links", total_links)  
