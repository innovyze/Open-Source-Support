require 'date'

class ICMBinaryObject
	attr_reader :offset, :name
	def initialize(name,offset,float_blob_attributes,double_blob_attributes)
		@name=name
		@offset=offset
		@float_blob_attributes=float_blob_attributes
		@float_blob_offsets=Array.new
		@double_blob_attributes=double_blob_attributes
		@double_blob_offsets=Array.new
		blob_offset=0 # NB, this is a count for both sorts of blobs i.e. if there are float blobs and double blobs, the double blob offsets include the float blobs
		if !float_blob_attributes.nil?
			(0...float_blob_attributes.size).each do |i|
				@float_blob_offsets << blob_offset
				blob_offset+=float_blob_attributes[i]
			end
		end
		if !double_blob_attributes.nil?
			(0...double_blob_attributes.size).each do |i|
				@double_blob_offsets << blob_offset
				blob_offset+=(double_blob_attributes[i]*2)
			end
		end
	end
	def get_float_blob_size(n)
		return @float_blob_attributes[n]
	end
	def get_float_blob_offset(n)
		return @float_blob_offsets[n]
	end
	def get_double_blob_size(n)
		return @double_blob_attributes[n]
	end
	def get_double_blob_offset(n)
		return @double_blob_offsets[n]
	end	
	def dump
		out=@name + ' ' + @offset.to_s
		if !@float_blob_attributes.nil?
			@float_blob_attributes.each do |a|
				out+=' '
				out+=a.to_s
			end
		end
		if !@double_blob_attributes.nil?
			@double_blob_attributes.each do |a|
				out+=' '
				out+=a.to_s
			end
		end		
		puts out
	end
end

class SimTime
	def initialize(val)
		@val=val
	end
	def to_s
		if @val>0
			return DateTime.jd(@val + DateTime.new(1899,12,30,0).jd.to_f).to_s
		else
			@val=-@val.to_i
			seconds=@val%60
			mins=(@val/60)%60
			hours=(@val/3600)%24
			days=@val/86400
			return sprintf("0000-00-%2.3dT%2.2d:%2.2d:%2.2d+00:00",days,hours,mins,seconds)
		end
	end
end

class ICMBinaryUtil
	def ICMBinaryUtil.readlong(f)
		blah=f.read(4)
		return blah.unpack('l')[0]
	end
	def ICMBinaryUtil.readdouble(f)
		blah=f.read(8)
		return blah.unpack('d')[0]
	end
	def ICMBinaryUtil.readdate(f)
		blah=f.read(8)
		simtime=blah.unpack('d')[0]	
		return SimTime.new(simtime)
	end
	def ICMBinaryUtil.readstring(f)
		blah=f.read(1)
		bytes=blah.unpack('C')[0]
		if bytes>0
			ret=f.read(bytes)
		else
			ret=''
		end
		if (bytes+1)%4!=0
			padding=4-((bytes+1)%4)
			f.read(padding)
		end
		return ret
	end
	def ICMBinaryUtil.words(s)
		len=s.length
		len+=1
		if(len%4!=0)
			len+=(4-len%4)
		end
		return len/4
	end
end

class ICMBinaryAttributes
	attr_reader :name, :desc, :unit, :precision
	def init(f)
		@name=ICMBinaryUtil.readstring(f)
		@desc=ICMBinaryUtil.readstring(f)
		@unit=ICMBinaryUtil.readstring(f)
		@precision=ICMBinaryUtil.readlong(f)
		return ICMBinaryUtil.words(@name)+ICMBinaryUtil.words(@desc)+ICMBinaryUtil.words(@unit)+1
	end
	def dump
		puts "#{name} '#{desc}' #{unit} #{precision}"
	end
end
class ICMBinaryTable
	attr_reader :name,:desc
	def init(f,b_max,object_offset)
		@b_max=b_max
		@objectHash=Hash.new
		header_size=0
		object_count=ICMBinaryUtil.readlong(f)
		non_blob_attribute_count=ICMBinaryUtil.readlong(f)
		float_blob_attributes_count=ICMBinaryUtil.readlong(f)	
		if @b_max
			double_blob_attributes_count=ICMBinaryUtil.readlong(f)
		else
			double_blob_attributes_count=0
		end
		header_size+=3
		if @b_max
			header_size+=1
		end
		@name=ICMBinaryUtil.readstring(f)
		@desc=ICMBinaryUtil.readstring(f)
		header_size+=ICMBinaryUtil.words(@name)
		header_size+=ICMBinaryUtil.words(@desc)
		@non_blob_attributes=Array.new
		(0...non_blob_attribute_count).each do |i|
			temp=ICMBinaryAttributes.new
			header_size+=temp.init(f)
			@non_blob_attributes << temp
		end
		@float_blob_attributes=Array.new
		(0...float_blob_attributes_count).each do |i|
			temp=ICMBinaryAttributes.new
			header_size+=temp.init(f)
			@float_blob_attributes << temp			
		end
		@double_blob_attributes=Array.new
		(0...double_blob_attributes_count).each do |i|
			temp=ICMBinaryAttributes.new
			header_size+=temp.init(f)
			@double_blob_attributes << temp			
		end		
		@objects=Array.new
		(0...object_count).each do |i|
			name=ICMBinaryUtil.readstring(f)
			header_size+=ICMBinaryUtil.words(name)
			float_blob_attributes_for_object=nil
			double_blob_attributes_for_object=nil
			size_of_results_for_object=non_blob_attribute_count
			if(float_blob_attributes_count>0)
				float_blob_attributes_for_object=Array.new
				(0...float_blob_attributes_count).each do |j|
					temp2=ICMBinaryUtil.readlong(f)
					float_blob_attributes_for_object << temp2
					header_size+=1
					size_of_results_for_object+=temp2
				end
			end
			if(double_blob_attributes_count>0)
				double_blob_attributes_for_object=Array.new
				(0...double_blob_attributes_count).each do |j|
					temp2=ICMBinaryUtil.readlong(f)
					double_blob_attributes_for_object << temp2
					header_size+=1
					size_of_results_for_object+=(temp2*2)
				end
			end			
			obj=ICMBinaryObject.new(name,object_offset,float_blob_attributes_for_object,double_blob_attributes_for_object)
			object_offset+=size_of_results_for_object
			@objects << obj
			@objectHash[name]=obj
		end
		temp=Array.new
		temp << header_size
		temp << object_offset
		return temp
	end
	def get_object(name)
		return @objectHash[name]
	end
	def get_attribute_info(name)
		(0...@non_blob_attributes.size).each do |i|
			if @non_blob_attributes[i].name==name
				ret = Array.new
				ret << i
				ret << 0
				return ret
			end
		end
		(0...@float_blob_attributes.size).each do |i|
			if @float_blob_attributes[i].name==name
				ret=Array.new
				ret << i 
				ret << 1
				return ret
			end
		end
		(0...@double_blob_attributes.size).each do |i|
			if @double_lob_attributes[i].name==name
				ret=Array.new
				ret << i 
				ret << 2
				return ret
			end
		end		
		return nil
	end
	def get_non_blob_attribute_count
		return @non_blob_attributes.size
	end
	def get_non_blob_attribute_name(n)
		return @non_blob_attributes[n].name
	end
	def get_non_blob_attribute_desc(n)
		return @non_blob_attributes[n].desc
	end
	def get_float_blob_attribute_count
		return @float_blob_attributes.size
	end
	def get_float_blob_attribute_name(n)
		return @float_blob_attributes[n].name
	end
	def get_float_blob_attribute_desc(n)
		return @float_blob_attributes[n].desc
	end
	def get_double_blob_attribute_count
		return @double_blob_attributes.size
	end
	def get_double_blob_attribute_name(n)
		return @double_blob_attributes[n].name
	end
	def get_double_blob_attribute_desc(n)
		return @double_blob_attributes[n].desc
	end	
	def list_attributes
		@non_blob_attributes.each do |a|
			puts "#{a.name} '#{a.desc}'"
		end
		@float_blob_attributes.each do |a|
			puts "#{a.name} '#{a.desc}' (blob)"
		end
		@double_blob_attributes.each do |a|
			puts "#{a.name} '#{a.desc}' (double blob)"
		end		
	end
	def list_objects
		@objects.each do |o|
			puts o.name
		end
	end
	def get_blob_sizes(name)
		obj=@objectHash[name]
		if obj.nil?
			raise "invalid object"
		end
		(0...@float_blob_attributes.size).each do |i|
			puts "#{@float_blob_attributes[i].name} '#{@float_blob_attributes[i].desc}' #{obj.get_float_blob_size(i)}"
		end
		(0...@double_blob_attributes.size).each do |i|
			puts "#{@double_blob_attributes[i].name} '#{@double_blob_attributes[i].desc}' #{obj.get_double_blob_size(i)}"
		end		
	end
	def dump
		puts '----'
		puts @name
		puts @non_blob_attributes.size
		@non_blob_attributes.each do |a|
			a.dump
		end
		puts @float_blob_attributes.size
		@float_blob_attributes.each do |a|
			a.dump
		end
		puts @double_blob_attributes.size		
		@double_blob_attributes.each do |a|
			a.dump
		end		
		puts @objects.size
		@objects.each do |o|
			o.dump
		end
	end
end

class ICMBinaryReader
	def init(binary_file,risk)
		@f=File.open binary_file, 'rb'
		version=ICMBinaryUtil.readlong(@f)
		if version==20151009
			@max=true
		elsif version==20110922
			@max=false
		else
			puts 'invalid file type'
			return false
		end
		if @max
			@timestep_count=1
		else
			@timestep_count=ICMBinaryUtil.readlong(@f)
			#puts @timestep_count
			@timesteps=Array.new
			(0...@timestep_count).each do |i|
				if risk
					timestep=ICMBinaryUtil.readdouble(@f)
				else
					timestep=ICMBinaryUtil.readdate(@f)
				end
				@timesteps << timestep
			end
		end
		table_count=ICMBinaryUtil.readlong(@f)
		#puts table_count
		skipped_words=ICMBinaryUtil.readlong(@f)
		#puts "expected #{skipped_words}"
		found_words=0
		tables=Array.new
		@tables_hash=Hash.new
		object_offset=0
		(0...table_count).each do |i|
			table=ICMBinaryTable.new
			temp=table.init(@f,@max,object_offset)
			found_words+=temp[0]
			object_offset=temp[1]
			tables << table
			@tables_hash[table.name]=table
			#table.dump
		end
		@timestep_size = object_offset
		@data_offset= found_words + 3
		if !@max
			@data_offset+= 1 + (2 * @timestep_count)
		end
		if skipped_words != found_words
			puts "expected #{skipped_words} found #{found_words}"
			return false
		end
		#puts "data size per timestep #{@timestep_size}"
		expected_file_size=((@timestep_size * @timestep_count)+@data_offset)*4;
		actual_file_size=@f.size;
		if(expected_file_size!=actual_file_size)
			puts "expected file size = #{expected_file_size} found file size = #{actual_file_size}"
			return false
		end
		return true

		#@f.close
	end
	def timesteps
		return @timesteps.size
	end
	def timestep(i)
		return @timesteps[i]
	end
	def get_table(name)
		return @tables_hash[name]
	end
	def get_value(timestep,table_name,object_id,attribute,index)
		#puts "getting #{timestep} #{table_name} #{object_id} #{attribute} #{index}"
		if timestep<0 || timestep>= @timestep_count
			raise "invalid timestep"
		end
		table=get_table(table_name)
		if table.nil?
			raise "invalid table"
		end
		object=table.get_object(object_id)
		if object.nil?
			raise 'invalid object'
		end
		attribute_info=table.get_attribute_info(attribute)
		if attribute_info.nil?
			raise 'invalid attribute'
		end
		#puts "data offset = #{@data_offset}"
		#puts "object offset = #{object.offset}"
		if attribute_info[1]==1
			blob_size = object.get_float_blob_size(attribute_info[0])
			if index < 0 || index >= blob_size
				return "XXXXX"
				#raise 'index out of range for blob attribute'
			else
				#puts "blob offset = #{object.get_float_blob_offset(attribute_info[0])}"
				offset=@data_offset + (@timestep_size * timestep) + object.offset + object.get_float_blob_offset(attribute_info[0])+index+ table.get_non_blob_attribute_count
			end
		elsif attribute_info[1]==2
			blob_size = object.get_double_blob_size(attribute_info[0])
			if index < 0 || index >= blob_size
				return "XXXXX"
				#raise 'index out of range for blob attribute'
			else
				#puts "blob offset = #{object.get_double_blob_offset(attribute_info[0])}"
				offset=@data_offset + (@timestep_size * timestep) + object.offset + object.get_double_blob_offset(attribute_info[0])+(index*2)+ table.get_non_blob_attribute_count
			end			
		else
			if index!=0
				raise 'non zero index for non blob attribute'
			else
				#puts "non blob offset = #{attribute_info[0]}"
				offset=@data_offset + (@timestep_size * timestep) + (object.offset + attribute_info[0]) 
			end
		end
		#puts "offset #{offset}"
		@f.seek(offset * 4,IO::SEEK_SET)		
		if(attribute_info[1]==2)
			blah=@f.read(8)
			return blah.unpack('d')[0]		
		else
			blah=@f.read(4)
			return blah.unpack('f')[0]	
		end
	end
	def get_results(obj_type,id,attribute)
		(0...@timesteps.size).each do |i|
			puts "#{@timesteps[i]},#{get_value(i,obj_type,id,attribute,0)}"
		end
	end
	def get_all_results(obj_type,id)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end	
		l=''
		l2=''
		(0...table.get_non_blob_attribute_count).each do |i|
			l+=','
			l2+=','
			l+=table.get_non_blob_attribute_name(i)
			l2+=table.get_non_blob_attribute_desc(i)
		end
		puts l
		puts l2
		if @timesteps.nil?
			l=''
			(0...table.get_non_blob_attribute_count).each do |j|
				l+=','
				l+="#{get_value(0,obj_type,id,table.get_non_blob_attribute_name(j),0)}"
			end
			puts l
		else
			(0...@timesteps.size).each do |i|
				l="#{@timesteps[i]}"
				(0...table.get_non_blob_attribute_count).each do |j|
					l+=','
					l+="#{get_value(i,obj_type,id,table.get_non_blob_attribute_name(j),0)}"
				end
				puts l
			end
		end
	end
	def get_blob_sizes(obj_type,id)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end
		table.get_blob_sizes(id)
	end	
	def get_all_blob_results(obj_type,id,index)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end	
		l=''
		l2=''
		(0...table.get_float_blob_attribute_count).each do |i|
			l+=','
			l2+=','
			l+=table.get_float_blob_attribute_name(i)
			l2+=table.get_float_blob_attribute_desc(i)
		end
		(0...table.get_double_blob_attribute_count).each do |i|
			l+=','
			l2+=','
			l+=table.get_double_blob_attribute_name(i)
			l2+=table.get_double_blob_attribute_desc(i)
		end		
		puts l
		puts l2
		if @timesteps.nil?
			l=''
			(0...table.get_float_blob_attribute_count).each do |j|
				l+=','
				l+="#{get_value(0,obj_type,id,table.get_float_blob_attribute_name(j),index)}"
			end
			(0...table.get_double_blob_attribute_count).each do |j|
				l+=','
				l+="#{get_value(0,obj_type,id,table.get_double_blob_attribute_name(j),index)}"
			end			
			puts l		
		else
			(0...@timesteps.size).each do |i|
				l="#{@timesteps[i]}"
				(0...table.get_float_blob_attribute_count).each do |j|
					l+=','
					l+="#{get_value(i,obj_type,id,table.get_float_blob_attribute_name(j),index)}"
				end
				(0...table.get_double_blob_attribute_count).each do |j|
					l+=','
					l+="#{get_value(i,obj_type,id,table.get_double_blob_attribute_name(j),index)}"
				end				
				puts l
			end
		end
	end	
	def list_tables
		@tables_hash.keys.sort.each do |k|
			puts k
		end
	end
	def list_attributes(obj_type)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end
		table.list_attributes
	end
	def list_objects(obj_type)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end
		table.list_objects
	end
end
	
	
usage=false
if ARGV.count<2 
	usage=true
else
	icmbr=ICMBinaryReader.new
	if !icmbr.init ARGV[0],(ARGV[1]=='RR')
		puts "failed to initialise"
	else
		if ARGV.count==2 && ARGV[1]=='T'
			icmbr.list_tables
		elsif ARGV.count==3 && ARGV[1]=='A'
			icmbr.list_attributes(ARGV[2])
		elsif ARGV.count==3 && ARGV[1]=='O'
			icmbr.list_objects(ARGV[2])
		elsif ARGV.count==4 && (ARGV[1]=='R' || ARGV[1]=='RR')
			icmbr.get_all_results ARGV[2],ARGV[3]			
		elsif ARGV.count==4 && ARGV[1]=='S'
			icmbr.get_blob_sizes ARGV[2],ARGV[3]
		elsif ARGV.count==5 && ARGV[1]=='BR'
			icmbr.get_all_blob_results ARGV[2],ARGV[3],ARGV[4].to_i
		else
			usage=true
		end
	end
end
if usage
	puts "usage - <filename> T = lists tables"
	puts "        <filename> A <table> = lists attributes for table"
	puts "	      <filename> O <table> = lists objects in table"
	puts "        <filename> R <table> <object> =  all (non blob) results for object"
	puts "        <filename> RR <table> <object> =  all (non blob) results for object (for risk results)"
	puts "        <filename> S <table> <object> = sizes of blobs for that object"
	puts "        <filename> BR <table> <object> <index> = blob results for that index into the blob array for that object"
end
