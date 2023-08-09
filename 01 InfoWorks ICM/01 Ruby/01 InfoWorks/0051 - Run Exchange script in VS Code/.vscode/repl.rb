#Text file containing path of ruby script which will be executed using 'repl.rb'
#"REPL" stands for "Read-Eval-Print Loop. Its an interactive way of executing code which is widely used in programing languages like ruby, python and etc. 
#This script tries to mimic ruby IRB enviroment. 
#Objective of this script is to have access to variables of ruby script executed using Exchange, so that user can interactively play with the script variable after the execution of script.

text_file_path = File.join(File.dirname(__FILE__), 'current_file_path.txt')

# Check if the file exists
if File.exist?(text_file_path)
  #  File.open(text_file_path, 'r') do |file|
  ruby_file_path = File.open(text_file_path, 'r', &:readline).chomp
  #Delete "current_file_path.txt"
  File.delete(text_file_path)
else
  puts "File not found: #{text_file_path}"
end


# Function to evaluate and print the expression
def evaluate_and_print(expr, binding)
  begin
    result = eval(expr, binding)
    puts "Result: #{result}"
  rescue => e
    puts "Error: #{e.message}"
  end
end

# Function to start the Read-Eval-Print Loop (REPL)
def start_repl(ruby_file_path)
  # Initialize an empty binding to store variable state
  repl_binding = binding

  #File.foreach(ruby_script_to_run) do |line|
  puts "Executing ruby script -------------- #{ruby_file_path} --------------"

  # Read the content of the Ruby file
  ruby_content = File.read(ruby_file_path)

  # Evaluate and print the content using the binding to maintain state
  begin
    eval(ruby_content, repl_binding)
  rescue => e
    puts "Error in input Ruby file: #{e.message}"
  end

  loop do
    print "Exchange>>>"
    input = gets
    input=input.chomp

    break if input.downcase == 'exit'

    # Evaluate and print the expression using the binding to maintain state
    evaluate_and_print(input, repl_binding)
  end
end

start_repl(ruby_file_path)
