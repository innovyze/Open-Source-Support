# Kutter's Formula Calculation in Ruby

# Define the method to calculate Kutter's coefficient 'c'
def kutter_coefficient(gradient, roughness_n, conduit_height)
  r = conduit_height.to_f / 48.0
  numerator = 41.65 + (0.00281 / (gradient / 100.0)) + (1.811 / roughness_n)
  denominator = 1.0 + (numerator * roughness_n / Math.sqrt(r))
  numerator / denominator
end

# Calculate full pipe capacity
def full_pipe_capacity(conduit_height, gradient, roughness_n)
  a = (((conduit_height / 12.0)**2) * 0.78539) # Area
  r = conduit_height.to_f / 48.0 # Hydraulic radius
  c = kutter_coefficient(gradient, roughness_n, conduit_height)
  q = a * c * Math.sqrt(r * gradient / 100.0)
  q
end

# Calculate 3/4 pipe capacity
def three_quarter_pipe_capacity(conduit_height, gradient, roughness_n)
  theta = 2.0944 # 120 degrees in radians
  r = conduit_height.to_f / 12.0
  area = Math::PI * (r**2) - (r**2 * (theta - Math.sin(theta)) / 2.0)
  perimeter = (2.0 * Math::PI * r) - (r * theta)
  hydraulic_radius = area / perimeter
  c = kutter_coefficient(gradient, roughness_n, conduit_height)
  q = area * c * Math.sqrt(hydraulic_radius * gradient / 100.0)
  q
end

# Calculate half pipe capacity as half of the full pipe capacity
def half_pipe_capacity(full_capacity)
  0.5 * full_capacity
end

# Example usage
conduit_height = 48 # Replace with actual value in inches
gradient = 100 # Replace with actual slope (ft/ft * 100)
roughness_n = 0.013 # Replace with actual Manning's n

full_capacity = full_pipe_capacity(conduit_height, gradient, roughness_n)
three_quarter_capacity = three_quarter_pipe_capacity(conduit_height, gradient, roughness_n)
half_capacity = half_pipe_capacity(full_capacity)

# Output the results
puts "Diameter: #{conduit_height} inches"
puts "Slope: #{gradient / 100.0} ft/ft"
puts "Manning's N Roughness: #{roughness_n}"
puts "ICM Calculated Capacity (CFS): [ICM Calculated Value]" # Replace with actual ICM calculated value
puts "Kutter's Full Capacity (CFS): #{full_capacity}"
puts "Kutter's 3/4 Capacity (CFS): #{three_quarter_capacity}"
puts "Kutter's 1/2 Capacity (CFS): #{half_capacity}"

# This Ruby script defines methods to calculate the flow in a pipe based on Kutter's formula. 
# It assumes that the conduit_height, gradient, and roughness_n values are provided. 
# The full_pipe_capacity, three_quarter_pipe_capacity, and half_pipe_capacity methods correspond to the respective calculations in the pseudocode. 
# The kutter_coefficient method calculates Kutter's coefficient 'c' as a helper function.
