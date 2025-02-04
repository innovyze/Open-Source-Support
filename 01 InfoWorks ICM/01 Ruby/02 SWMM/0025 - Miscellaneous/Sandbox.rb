# Source of this code is https://github.com/sancarn/Innovyze-ICM-Libraries/blob/master/libraries/InfoWorks-ICM/Ruby/Randoms/SandboxingExample.rb

class Monk
  # Monk class (currently empty)
end

class Sandbox
  # Sandbox class (currently empty)
end

# Creating a new instance of Sandbox
box = Sandbox.new

# Adding methods to the instance 'box' using instance_eval
box.instance_eval do
  # Define a method 'amazing'
  def amazing
    "amazing"
  end

  # Output combining 'amazing' method and string
  p amazing + " stuff"

  # Define another method 'number'
  def number
    42
  end

  # Output combining 'amazing' method and 'number' method
  p amazing + " " + number.to_s
end

# Trying to access the 'amazing' method outside of its context
begin
  p amazing
rescue
  p "We couldn't evaluate 'amazing' from outside the instance context!"
end

# Accessing 'amazing' method from within its instance context
p "Accessing 'amazing' from inside the instance: " + box.instance_eval('amazing')

# Creating a new Sandbox instance
new_box = Sandbox.new

# Trying to access the 'amazing' method in a new instance where it's not defined
begin
  p new_box.instance_eval('Sandox says amazing')
rescue
  p "We couldn't evaluate 'amazing' in a new Sandbox instance!"
end
