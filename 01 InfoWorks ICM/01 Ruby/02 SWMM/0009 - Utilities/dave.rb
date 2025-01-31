# Appreciation script for Dave's contributions

def print_centered(text, width = 60)
    puts text.center(width)
  end
  
  def print_bordered(text, width = 60)
    puts "+" + "-" * (width + 2) + "+"
    puts "| #{text.center(width)} |"
    puts "+" + "-" * (width + 2) + "+"
  end
  
  # ASCII Art
  print_centered("*" * 40)
  print_centered("Thank You, Dave!")
  print_centered("*" * 40)
  puts
  
  # Message parts
  contributions = [
    "exceptional Ruby scripting for ICM",
    "Ruby Excel List",
    "fantastic online Ruby Help File"
  ]
  
  # Print appreciation message
  print_bordered("We are grateful for your:")
  contributions.each_with_index do |contribution, index|
    puts "#{index + 1}. #{contribution.capitalize}"
  end
  puts
  
  print_centered("You will be greatly missed!")
  puts
  
  print_bordered("Thames Water is fortunate to have you")
  print_centered("for WS Pro value-added scripts.")
  
  # Final touch
  puts
  print_centered("*" * 40)
  print_centered("Best Wishes!")
  print_centered("*" * 40)