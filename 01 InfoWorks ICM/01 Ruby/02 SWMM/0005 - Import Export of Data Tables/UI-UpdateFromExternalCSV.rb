require "csv"

first=true
myHash=Hash.new
File.open (File.dirname(WSApplication.script_file) + '\\test.csv') do |f|
	f.each_line do |l|
		if first
			first=false
		else
			l.chomp!
			arr=CSV.parse_line(l)
			if !myHash.has_key? arr[0]
				fred=Array.new
				fred << nil
				fred << nil
				myHash[arr[0]]=fred
			end
			if myHash[arr[0]][0].nil? || arr[2]>myHash[arr[0]][0]
				myHash[arr[0]][0]=arr[0]
				myHash[arr[0]][1]=arr[1]
			end
		end
	end
end

db=WSApplication.current_network 
db.transaction_begin

db.row_objects('cams_manhole').each do |v|	
if myHash.has_key? v.user_text_1
		val=myHash.values_at(v.user_text_1)
puts val[0].to_s
		v.user_text_2=val[0][1].to_s
		v.write
	end
end

db.transaction_commit