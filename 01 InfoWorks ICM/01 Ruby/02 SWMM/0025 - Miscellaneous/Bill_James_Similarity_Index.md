```markdown
# Using the Bill James Similarity Index to Compare SWMM5 and InfoWorks ICM Hydraulic Networks

This paper presents a novel paradigm for evaluating hydraulic modeling platforms using the **Bill James Similarity Index**, a statistical technique initially created for baseball statistics. The methodology allows for a systematic comparison of the **Storm Water Management Model 5 (SWMM5)** (utilizing ICM SWMM) and **InfoWorks ICM** by assessing their computational outputs and performance in standardized situations.

The methodology takes advantage of the unique ability to run both SWMM5 and InfoWorks ICM simultaneously under the same user interface, resulting in equivalent **InfoWorks Result (IWR) files**. The research uses 100 historical SWMM test files generated from SWMM3, SWMM4, and SWMM5 releases, which constitute the USEPA's standard engine testing suite. **ICM SWMM** is the background network, while **ICM InfoWorks** is the current network.

A modified similarity index was created by assigning weighted scores (0–100) to key hydraulic characteristics at shared network nodes. These metrics include flow rates, water depths, and velocities, with weights based on hydraulic relevance. Metrics such as **Current Network Mean**, **Background Network Mean**, **Root Mean Square Error**, **Mean Average Error**, **Mean Simple Least Square Error**, **Simulated Standard Deviation**, **Skewness of Background Network**, **Kurtosis of Background Network**, **Kurtosis of Current Network**, **Log Nash-Sutcliffe Efficiency**, **Index of Agreement**, **Integral Square Error**, **Kling-Gupta Efficiency**, **Correlation Coefficient**, and **Nash-Sutcliffe Efficiency** were used to guide the similarity index.

The evaluation framework looks at three major dimensions:
- **Computational correctness vs. observed data**
- **Hydraulic robustness in problem settings** (e.g., backwater effects, surcharges, flooding)
- **Computational efficiency for large networks**

Ruby scripting streamlines the analytical procedure, resulting in consistent evaluation across all test situations. This methodology combines sports analytics and hydraulic engineering to provide a consistent, replicable protocol for model comparison. The obtained similarity ratings provide objective criteria for selecting modeling platforms based on project specifications.

**Keywords:** Bill James Similarity Index, hydraulic modeling, model comparison, SWMM5, InfoWorks ICM, statistical evaluation, performance metrics, computational hydraulics
```
```markdown

# Explanation
## Statistical Methods:
Functions such as mean, rmse, mape, standard_deviation, skewness, and kurtosis compute basic descriptive statistics.

## Efficiency Metrics:
Methods like nash_sutcliffe_efficiency, log_nash_sutcliffe_efficiency, index_of_agreement, integral_square_error, correlation_coefficient, and kling_gupta_efficiency quantify the agreement between the two datasets using common hydraulic performance criteria.

## Scoring Function:
The score_for_metric function converts the raw metric error into a score from 0 to 100. A perfect match (error equal to the ideal value) earns a score of 100; as the error approaches the defined tolerance, the score linearly decreases.

## Aggregation:
In similarity_index, all metric scores are weighted and aggregated into a final similarity rating.

This script provides a template that can be extended or refined with more detailed error tolerances, more complex weighting schemes, or actual file I/O to process real IWR files from SWMM5 and InfoWorks ICM.