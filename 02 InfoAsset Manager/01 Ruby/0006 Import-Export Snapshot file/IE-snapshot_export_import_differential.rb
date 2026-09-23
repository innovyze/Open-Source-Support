## Differential snapshot export from one Collection network and import into another.
## Tracks the last exported commit ID in a text file (same pattern as ODEC differential exports).
## On first run, or when the tracking file is missing, ChangesFromVersion is 0 (full export).

begin

	currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
	puts "#{currtime} Starting differential snapshot export / import"

	## Database connection (Exchange)
	db = WSApplication.open('localhost:40000/IA_NEW', false)

	## Source network (export) and target network (import)
	source_network_id = 4
	target_network_id = 8
	network_type = 'Collection Network'

	## Snapshot cache folder and files (folder must exist)
	snapshot_directory = 'C:\\TEMP\\SnapshotScript\\'
	snapshot_file = snapshot_directory + 'network1_differential.isfc'
	version_tracking_file = snapshot_directory + 'network1_previous_export_commit_id.txt'

	#####################################################
	## Export options — ChangesFromVersion set from tracking file below
	exp_options = Hash.new
	exp_options['SelectedOnly'] = false
	exp_options['IncludeImageFiles'] = false
	exp_options['IncludeGeoPlanPropertiesAndThemes'] = false
	# exp_options['Tables'] = ['cams_cctv_survey', 'cams_manhole_survey']

	#####################################################
	## Import options
	imp_options = Hash.new
	imp_options['AllowDeletes'] = true
	imp_options['ImportGeoPlanPropertiesAndThemes'] = false
	imp_options['UpdateExistingObjectsFoundByID'] = true
	imp_options['UpdateExistingObjectsFoundByUID'] = true
	imp_options['ImportImageFiles'] = false

	#####################################################
	## Source network — read last exported commit, update, export if changed
	source_nw = db.model_object_from_type_and_id(network_type, source_network_id)

	previous_export_commit_id = 0
	if File.exist?(version_tracking_file)
		previous_export_commit_id = File.read(version_tracking_file).strip.to_i
	end

	current_commit_id = source_nw.current_commit_id
	latest_commit_id = source_nw.latest_commit_id

	currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
	if latest_commit_id > current_commit_id
		puts "#{currtime} Updating source from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
		source_nw.update
		current_commit_id = source_nw.current_commit_id
	else
		puts "#{currtime} Source network working copy is up to date (Commit ID #{current_commit_id})"
	end

	currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
	puts "#{currtime} Previous export Commit ID: #{previous_export_commit_id} | Current Commit ID: #{current_commit_id}"

	if previous_export_commit_id >= current_commit_id
		puts "#{currtime} No changes since last export — skipping export and import"
	else
		exp_options['ChangesFromVersion'] = previous_export_commit_id

		currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
		puts "#{currtime} Exporting differential snapshot (ChangesFromVersion #{previous_export_commit_id})"

		source_on = source_nw.open
		source_on.snapshot_export_ex(snapshot_file, exp_options)
		source_on.close

		#####################################################
		## Target network — import snapshot and commit
		target_nw = db.model_object_from_type_and_id(network_type, target_network_id)

		currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
		puts "#{currtime} Updating target network before import"
		target_nw.update

		target_on = target_nw.open
		target_on.snapshot_import_ex(snapshot_file, imp_options)
		target_on.close

		target_nw.commit('Network updated from differential snapshot')

		File.write(version_tracking_file, current_commit_id.to_s)

		currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
		puts "#{currtime} Import complete; recorded export Commit ID #{current_commit_id}"
	end

	currtime = Time.now.strftime('%Y-%m-%d %H:%M:%S')
	puts "#{currtime} Script complete"

rescue Exception => exception
	puts "[#{exception.backtrace}] #{exception.to_s}"
end
