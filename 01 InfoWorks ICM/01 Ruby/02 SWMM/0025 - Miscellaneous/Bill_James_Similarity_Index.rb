#!/usr/bin/env ruby
# -----------------------------------------------------------------------------
# Title: Using the Bill James Similarity Index to Compare SWMM5 and InfoWorks ICM
#
# This script demonstrates a simplified evaluation framework that compares
# hydraulic modeling outputs from two networks: a background network (ICM SWMM)
# and a current network (InfoWorks ICM). The methodology uses a modified version
# of the Bill James Similarity Index, where various hydraulic metrics (e.g., means,
# RMSE, standard deviation, skewness, kurtosis, efficiency metrics, etc.) are scored
# on a scale from 0-100, and then combined with assigned weights to produce a 
# final similarity rating.
#
# NOTE:
# - In an actual implementation, the data arrays would be generated from reading
#   InfoWorks Result (IWR) files produced by the simulation platforms.
# - The error tolerance values and weights are set arbitrarily for demonstration.
# -----------------------------------------------------------------------------

class HydraulicNetworkComparison
    attr_reader :background_data, :current_data, :weights
  
    # Initialize with two datasets and optionally a custom set of weights.
    # The weights hash assigns relative importance to each metric.
    def initialize(background_data, current_data, weights = {})
      @background_data = background_data
      @current_data = current_data
      @weights = {
        mean: 10,
        rmse: 20,
        mape: 15,
        std_dev: 10,
        skewness: 5,
        kurtosis: 5,
        log_nse: 10,
        index_of_agreement: 10,
        integral_square_error: 5,
        correlation: 5,
        nse: 5,
        kling_gupta: 5
      }.merge(weights)
    end
  
    # -------------------------
    # Basic Statistical Methods
    # -------------------------
  
    # Computes the mean (average) of an array of numbers.
    def mean(data)
      data.sum.to_f / data.size
    end
  
    # Computes the Root Mean Square Error (RMSE) between two datasets.
    def rmse(data1, data2)
      sum = data1.zip(data2).map { |a, b| (a - b)**2 }.sum
      Math.sqrt(sum.to_f / data1.size)
    end
  
    # Computes the Mean Absolute Percentage Error (MAPE) between two datasets.
    def mape(data1, data2)
      errors = data1.zip(data2).map do |a, b|
        # Avoid division by zero by adding a small epsilon when needed.
        a = 1e-6 if a.abs < 1e-6
        ((a - b).abs / a.abs) * 100.0
      end
      errors.sum / data1.size
    end
  
    # Computes the standard deviation of an array.
    def standard_deviation(data)
      m = mean(data)
      variance = data.map { |x| (x - m)**2 }.sum / data.size
      Math.sqrt(variance)
    end
  
    # Computes the skewness of the dataset.
    def skewness(data)
      m = mean(data)
      sd = standard_deviation(data)
      return 0 if sd.zero?
      n = data.size
      data.map { |x| ((x - m) / sd)**3 }.sum / n
    end
  
    # Computes the kurtosis (excess kurtosis) of the dataset.
    def kurtosis(data)
      m = mean(data)
      sd = standard_deviation(data)
      return 0 if sd.zero?
      n = data.size
      data.map { |x| ((x - m) / sd)**4 }.sum / n - 3.0
    end
  
    # ---------------------------------------------
    # Efficiency and Agreement Metric Calculations
    # ---------------------------------------------
  
    # Computes the Nash-Sutcliffe Efficiency (NSE).
    # NSE values close to 1 indicate a good match between simulated and observed data.
    def nash_sutcliffe_efficiency(simulated, observed)
      mean_obs = mean(observed)
      numerator = observed.zip(simulated).map { |o, s| (o - s)**2 }.sum
      denominator = observed.map { |o| (o - mean_obs)**2 }.sum
      return 1.0 if denominator.zero?
      1 - (numerator / denominator.to_f)
    end
  
    # Computes the Log Nash-Sutcliffe Efficiency.
    # We take the natural logarithm of both datasets to emphasize differences at lower magnitudes.
    def log_nash_sutcliffe_efficiency(data1, data2)
      epsilon = 1e-6 # small constant to avoid log(0)
      log_data1 = data1.map { |x| Math.log(x.abs + epsilon) }
      log_data2 = data2.map { |x| Math.log(x.abs + epsilon) }
      nash_sutcliffe_efficiency(log_data1, log_data2)
    end
  
    # Computes the Index of Agreement between two datasets.
    # This metric is another measure of agreement where 1 indicates perfect agreement.
    def index_of_agreement(simulated, observed)
      mean_obs = mean(observed)
      numerator = observed.zip(simulated).map { |o, s| (o - s)**2 }.sum
      denominator = observed.zip(simulated).map { |o, s| ((s - mean_obs).abs + (o - mean_obs).abs)**2 }.sum
      return 1.0 if denominator.zero?
      1 - (numerator / denominator.to_f)
    end
  
    # Computes the Integral Square Error (ISE) between the two datasets.
    def integral_square_error(data1, data2)
      data1.zip(data2).map { |a, b| (a - b)**2 }.sum
    end
  
    # Computes the Pearson correlation coefficient between two datasets.
    def correlation_coefficient(data1, data2)
      n = data1.size
      mean1 = mean(data1)
      mean2 = mean(data2)
      sum_xy = data1.zip(data2).map { |a, b| (a - mean1) * (b - mean2) }.sum
      sum_x2 = data1.map { |a| (a - mean1)**2 }.sum
      sum_y2 = data2.map { |b| (b - mean2)**2 }.sum
      denominator = Math.sqrt(sum_x2 * sum_y2)
      return 0 if denominator.zero?
      sum_xy / denominator
    end
  
    # Computes the Kling-Gupta Efficiency (KGE), which synthesizes correlation, bias, and variability.
    def kling_gupta_efficiency(simulated, observed)
      r = correlation_coefficient(simulated, observed)
      sd_sim = standard_deviation(simulated)
      sd_obs = standard_deviation(observed)
      mean_sim = mean(simulated)
      mean_obs = mean(observed)
      
      alpha = sd_sim / sd_obs
      beta = mean_sim / mean_obs
      1 - Math.sqrt((r - 1)**2 + (alpha - 1)**2 + (beta - 1)**2)
    end
  
    # ------------------------------------------------------
    # Metric Scoring and Aggregation for Similarity Index
    # ------------------------------------------------------
  
    # Converts a raw metric value into a score between 0 and 100.
    # For error metrics, a value equal to the ideal (usually 0 error) scores 100.
    # A value equal to the specified tolerance will score 0. Values in between
    # are scaled linearly.
    def score_for_metric(value, ideal = 0, tolerance = 1.0)
      return 100 if value <= ideal
      score = 100 * (1 - (value - ideal) / tolerance)
      score < 0 ? 0 : score
    end
  
    # Computes the overall similarity index by calculating individual metric scores,
    # weighting them, and then aggregating into a final score.
    def similarity_index
      scores = {}
  
      # 1. Compare the mean values of the two datasets.
      mean_bg = mean(background_data)
      mean_cur = mean(current_data)
      mean_diff = (mean_bg - mean_cur).abs
      scores[:mean] = score_for_metric(mean_diff, 0, tolerance = 10)  # Tolerance of 10 units
  
      # 2. Compute RMSE between datasets.
      rmse_val = rmse(background_data, current_data)
      scores[:rmse] = score_for_metric(rmse_val, 0, tolerance = 10)
  
      # 3. Compute MAPE between datasets.
      mape_val = mape(background_data, current_data)
      scores[:mape] = score_for_metric(mape_val, 0, tolerance = 50)
  
      # 4. Compare standard deviations.
      std_bg = standard_deviation(background_data)
      std_cur = standard_deviation(current_data)
      std_diff = (std_bg - std_cur).abs
      scores[:std_dev] = score_for_metric(std_diff, 0, tolerance = 5)
  
      # 5. Compare skewness.
      skew_bg = skewness(background_data)
      skew_cur = skewness(current_data)
      skew_diff = (skew_bg - skew_cur).abs
      scores[:skewness] = score_for_metric(skew_diff, 0, tolerance = 1)
  
      # 6. Compare kurtosis.
      kurt_bg = kurtosis(background_data)
      kurt_cur = kurtosis(current_data)
      kurt_diff = (kurt_bg - kurt_cur).abs
      scores[:kurtosis] = score_for_metric(kurt_diff, 0, tolerance = 1)
  
      # 7. Log Nash-Sutcliffe Efficiency: we want an efficiency close to 1.
      log_nse = log_nash_sutcliffe_efficiency(background_data, current_data)
      scores[:log_nse] = score_for_metric((1 - log_nse).abs, 0, tolerance = 1)
  
      # 8. Index of Agreement: also aiming for values near 1.
      ioa = index_of_agreement(current_data, background_data)
      scores[:index_of_agreement] = score_for_metric((1 - ioa).abs, 0, tolerance = 1)
  
      # 9. Integral Square Error per data point.
      ise = integral_square_error(background_data, current_data) / background_data.size
      scores[:integral_square_error] = score_for_metric(ise, 0, tolerance = 10)
  
      # 10. Correlation Coefficient: closer to 1 is better.
      corr = correlation_coefficient(background_data, current_data)
      scores[:correlation] = score_for_metric((1 - corr).abs, 0, tolerance = 1)
  
      # 11. Nash-Sutcliffe Efficiency.
      nse = nash_sutcliffe_efficiency(current_data, background_data)
      scores[:nse] = score_for_metric((1 - nse).abs, 0, tolerance = 1)
  
      # 12. Kling-Gupta Efficiency.
      kge = kling_gupta_efficiency(current_data, background_data)
      scores[:kling_gupta] = score_for_metric((1 - kge).abs, 0, tolerance = 1)
  
      # Combine weighted scores: each metric’s score is multiplied by its weight,
      # and the sum is normalized by the total weight.
      total_weight = weights.values.sum.to_f
      weighted_sum = scores.reduce(0) { |sum, (metric, score)| sum + score * weights[metric] }
      final_index = weighted_sum / total_weight
  
      { scores: scores, weighted_score: final_index }
    end
  end
  
  # -----------------------
  # Example Usage Section
  # -----------------------
  if __FILE__ == $0
    # In a real scenario, data would be extracted from IWR files representing the
    # hydraulic outputs from ICM SWMM (background network) and InfoWorks ICM (current network).
  
    # For demonstration, we generate synthetic data for 100 nodes.
    # These numbers could represent flow rates, water depths, velocities, etc.
    def generate_data(mean, std, size)
      Array.new(size) { rand * std + mean }
    end
  
    # Generate synthetic datasets
    background_data = generate_data(50, 5, 100)  # Background network (ICM SWMM)
    # Simulate a slight deviation for the current network (InfoWorks ICM)
    current_data = background_data.map { |val| val + rand(-2.0..2.0) }
  
    # Instantiate the comparison object
    comparator = HydraulicNetworkComparison.new(background_data, current_data)
  
    # Compute and display the similarity index and individual metric scores.
    result = comparator.similarity_index
    puts "Individual Metric Scores (0-100):"
    result[:scores].each do |metric, score|
      puts "  #{metric.to_s.capitalize.ljust(22)}: #{score.round(2)}"
    end
    puts "\nFinal Weighted Similarity Index: #{result[:weighted_score].round(2)}"
  end
  
  