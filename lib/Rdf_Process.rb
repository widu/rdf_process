# load "../rdf_inference/rdf_inference.rb"
require 'linkeddata'
require 'rdf_to_graphviz'
require 'rdf_rules_engine'
require 'xls_to_rdf'

require 'rdf_inference'
# load "../rdf_process/lib/rdf_process/RdfProcessDefinitionLike.rb"

require 'rdf_process/RdfProcessDefinitionLike'

class RdfProcess
	include RdfProcessDefinitionLike
	attr_reader :fresh_status, :runtime_list, :runtime_variable_list, :komunikat, :progress
	attr_accessor :monitor_file_list
	def initialize
		@fresh_status = "old" #fresh  lub old
		@runtime_list = []
		@monitor_file_list = []
		@runtime_variable_list = {}
		
	end

	def reset
		@fresh_status = "old" #fresh  lub old
		@runtime_list = []
		@monitor_file_list = []
		@runtime_variable_list = {}
	end

	def fresh_status=(new_fresh_status)
		@fresh_status = new_fresh_status
		# graphviz_filtr_value.value = @fresh_status
	end

	def processing
		s = 0
		current_step = 1
		size = @runtime_list.size
		process_pass = 0.0
		@runtime_list.each do |step|
			if step[:fresh_status] == nil or step[:fresh_status] == "old" then
				s1 = Time.now
				step[:runtime_code].call
				# instance_eval(step[:runtime_code])
				s2 = Time.now - s1 
				s += s2
				log "#{step[:name]} - Elapse time: #{s2}s"
				step[:fresh_status] = "fresh"
			end		
			process_pass = current_step * 100 / size
			log("#{step[:name]} - #{process_pass} - #{current_step} - #{size} %", process_pass.round)
			current_step += 1	
		end
		@fresh_status = "fresh"
		log "Process - Elapse time: #{s}s, #{process_pass}"
		# graphviz_filtr_value.value = @fresh_status
	end

	def set_runtime_variable(name, value)
		@runtime_variable_list[name][:value] = value
		# log @runtime_variable_list.to_s
		refresh_status(@runtime_variable_list[name][:step_id])
		@fresh_status = "old"
	end

	def set_monitor_file(index, file)
		@monitor_file_list[index][:file] = file
		# log @monitor_file_list.to_s
		refresh_status(@monitor_file_list[index][:step_id])
		@fresh_status = "old"
	end

	def refresh_status(step_id)
		# puts "entry refresh_status"
		@runtime_list.each do |step|
			if step[:step_id] == step_id then
				step[:fresh_status] = "old"
			end

			st = step[:depends_on]
			if st  
				
				if st.include?(step_id) then
					# step[:fresh_status] = "old"
					# puts step[:step_id] , step[:name]
					refresh_status(step[:step_id])
					# puts step
				end
			end	
		end
		# puts @runtime_list
	end

	def get_dependent_step_from(step_id)
		dependent_steps = []
		@runtime_list.each do |step|
			st = step[:depends_on]
			if st != nil then 
				
				if st.include?(step_id) then
					# step[:fresh_status] = "old"
					# puts step[:step_id] , step[:name]
					dependent_steps << step[:step_id]
					# puts step
				end
			end	

		end
		dependent_steps
	end

	def log(komunikat, progress = nil)
		@progress = progress

		# @komunikat.disp_komunikat(komunikat, progress) 
		@komunikat = komunikat
		puts komunikat
		send_log
	end

	def send_log
		puts "send log"
	end

	def eval_file(file)
	  instance_eval File.read(file), file
	end

	def save_variables(file)
		File.open(file, "w") do |aFile|
			@runtime_variable_list.each do | name, value |
				if value[:type] != "graph" then  #.gsub!("\"",'\\"')
					# gvalue = 
				code = "addVariable '#{value[:type]}' do
					name '#{name}'
					value \"#{value[:value].gsub("\"",'\\"')}\"
					step_id '#{value[:step_id]}'
				end"
				aFile.puts code
				end
			end
		   
		    aFile.puts "# vieslav.pl "
		end
	end
	
end