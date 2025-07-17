# Test to find the maximum number of rows
def test_prompt_limit
  (10..250).step(10) do |num_rows|
    puts "Testing with #{num_rows} rows..."
    
    options = []
    num_rows.times do |i|
      options << ["Option #{i+1}", 'Boolean', false]
    end
    
    begin
      result = WSApplication.prompt("Test #{num_rows} rows", options, false)
      if result.nil?
        puts "User cancelled or prompt failed at #{num_rows} rows"
        break
      else
        puts "Success with #{num_rows} rows"
      end
    rescue => e
      puts "Failed at #{num_rows} rows: #{e.message}"
      break
    end
  end
end

test_prompt_limit