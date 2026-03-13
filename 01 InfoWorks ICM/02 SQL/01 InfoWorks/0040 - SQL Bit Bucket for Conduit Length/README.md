# Conduit Length Distribution Script for InfoWorks ICM

These scripts calculate the distribution of conduit lengths in an InfoWorks ICM model network. Links are grouped into buckets based on their length and counted per bucket. Two versions are provided — one using US Customary units (feet) and one using Metric units (metres).

## Scripts

| Script | Units |
|--------|-------|
| `SQL Bit Bucket for Length (feet).sql` | US Customary (feet) |
| `SQL Bit Bucket for Length (meters).sql` | Metric (metres) |

## How it Works

1. Each script defines a list of bucket boundaries for the conduit lengths:
   - **Feet:** 25, 50, 100, 200, 500, 1000, 2000, and 5000 feet
   - **Metres:** 10, 25, 50, 100, 200, 500, 1000, and 2000 metres

2. It then selects all links in the network.

3. For each link, it finds the largest bucket boundary that is less than or equal to the link's length. This is done using the `RINDEX` function, which returns the largest value in the list that is less than or equal to the input value.

4. The script groups the links by this bucket boundary and counts the number of links in each group.

5. Finally, it selects the count of links and the bucket boundary as the length, and groups the results by length category.

## Usage

Run the script in the context of an open network in InfoWorks ICM with **All Links** selected as the object type. The script will automatically calculate the distribution of conduit lengths and group them into the defined buckets.

