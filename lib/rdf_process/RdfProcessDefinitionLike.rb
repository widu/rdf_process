module RdfProcessDefinitionLike

	def calculate_depends_on(variables)
		depended_steps = []
		@runtime_list.each do |step|
			if variables.include?(step[:output_vrbl]) then
				depended_steps << step[:step_id]
			end
		end
		depended_steps
	end

	class ProcessVariable
		attr_reader  :parameters

		def initialize(type) 
			@parameters = {}
			@parameters[:type] = type
		end

		def name(name)
			@name = name
		end

		def getName
			@name
		end

		def method_missing(method, arg)
			@parameters[method] = arg
		end

	end

	def addVariable(type, &block)
		# puts self
		variable = ProcessVariable.new(type)
		variable.instance_eval(&block)
		# proc = self
		puts "check #{type}"
		@runtime_variable_list[variable.getName] = variable.parameters
		# puts @runtime_variable_list[variable.name]
	end

	class ProcessStep
		attr_reader :type, :vrbls 
		attr_accessor :parameters

		def initialize( type ) 
			@parameters = {}
			@parameters[:type] = type
			@vrbls = {}
		end

		def depends_on(*args)
			@parameters[:depends_on] = args
		end

		def sheets(*args)
			@parameters[:sheets] = args
		end

		def output_vrbl(name)
			@parameters[:output_vrbl] = name
			@vrbls[name] = {:type => 'graph', :value => nil}
		end

		def input_vrbl(name)
			@parameters[:input_vrbl] = name
			@vrbls[name] = {:type => 'graph', :value => nil}
		end

		def file_vrbl(name, type=nil, value=nil)
			@parameters[:file_vrbl] = name
			@vrbls[name] = {:type => type, :value => value}
		end

		def input_file_vrbl(name, value=nil)
			@parameters[:input_file_vrbl] = name
			@vrbls[name] = {:type => "input_file", :value => value}
		end

		def output_file_vrbl(name, value=nil)
			@parameters[:output_file_vrbl] = name
			@vrbls[name] = {:type => "output_file", :value => value}
		end

		def filtr_vrbl(name, value=nil)
			@parameters[:filtr_vrbl] = name
			@vrbls[name] = {:type => "filtr", :value => value}
		end

		def prefix_vrbl(name, value=nil)
			@parameters[:prefix_vrbl] = name
			@vrbls[name] = {:type => "prefix", :value => value}
		end

		def method_missing(method, arg)
			@parameters[method] = arg
		end
	end


	def addStep( type, &block)
		depends = []
		step = ProcessStep.new(type)
		puts "check #{type}"
		step.instance_eval(&block)
		depends << step.parameters[:input_vrbl] if step.parameters[:input_vrbl]
		depends << step.parameters[:rule_graph_vrlb] if step.parameters[:rule_graph_vrlb]
		depends << step.parameters[:presentation_vrlb] if step.parameters[:presentation_vrlb]
		step.parameters[:depends_on] = calculate_depends_on(depends)
		step.vrbls.each do |key, value|
			if @runtime_variable_list[key] == nil then
				addVariable value[:type] do
					name key
					value value[:value]
					step_id step.parameters[:step_id]
				end
			end
		end
		# step.prepare
		if type == "GraphLoader" then          # GraphLoader step definition________________________________________________________________
			if step.parameters[:file_vrbl] == nil then
				ttl_file = step.parameters[:file] 
				unless File::exists?( ttl_file )
					raise "Graph loader - ttl file: #{ttl_file} - doesn't exist"
				end

				runtime_code = -> {
					 @runtime_variable_list[step.parameters[:output_vrbl]][:value]  = RDF::Graph.load(ttl_file)
					 puts "step graphloader"
					}
			else
				ttl_file = step.parameters[:file_vrbl]
				runtime_code = -> {
					 @runtime_variable_list[step.parameters[:output_vrbl]][:value]  = RDF::Graph.load(@runtime_variable_list[ttl_file][:value])
					 puts "step graphloader"
					}
			end
			
		elsif type == "Filtr" then            # Filtr step definition________________________________________________________________________
			runtime_code = -> {
				puts @runtime_variable_list[step.parameters[:filtr_vrbl]][:value]
				query = @runtime_variable_list["prefix"][:value] + @runtime_variable_list[step.parameters[:filtr_vrbl]][:value] 
				inputt = step.parameters[:input_vrbl]
				puts step.parameters[:input_vrbl]
				@runtime_variable_list[step.parameters[:output_vrbl]][:value] = SPARQL.execute(query,  @runtime_variable_list[inputt][:value])
			}

			runtime_code = -> {
				if step.parameters[:filtr_vrbl]
					query2 =  @runtime_variable_list[step.parameters[:filtr_vrbl]][:value]
					puts @runtime_variable_list[step.parameters[:filtr_vrbl]][:value]
				else
					query2 = step.parameters[:filtr]
				end
				query = @runtime_variable_list["prefix"][:value] + query2
				inputt = step.parameters[:input_vrbl]
				puts step.parameters[:input_vrbl]
				@runtime_variable_list[step.parameters[:output_vrbl]][:value] = SPARQL.execute(query,  @runtime_variable_list[inputt][:value])
			}

		elsif type == "RdfToGraphviz" then    # RdfToGraphviz step definition_________________________________________________________________
			@konwerter = RdfToGraphviz.new
			


			runtime_code = -> {
				paramiters = {}
				if step.parameters[:presentation_vrlb] 
					paramiters[:presentation_attr] = @runtime_variable_list[step.parameters[:presentation_vrlb]][:value]
				end
				puts step.parameters
				if step.parameters[:output_format]
					paramiters[:format] = step.parameters[:output_format]
					puts 'format'
				end
				paramiters[:file_name] = @runtime_variable_list[step.parameters[:output_file_vrbl]][:value]
				puts "RdfToGraphviz"
				puts step.parameters[:presentation_vrlb]
				puts @runtime_variable_list[step.parameters[:presentation_vrlb]]
				puts paramiters
				@konwerter.save_rdf_graph_as(@runtime_variable_list[step.parameters[:input_vrbl]][:value], paramiters)
				# tag <img>
				if paramiters[:format] == 'html' then
					file_png = paramiters[:file_name].gsub(/\.\w+$/, ".png")
					File.open(paramiters[:file_name], "a") do |aFile|
						hmlt_tag = "<IMG SRC='#{file_png}' USEMAP='#G' />"
						aFile.puts hmlt_tag
					end
				end
			}
		elsif type == "ExcelLoader" then         # XlsToRdfConwerter step definition_______________________________________________________________
			@XlsToRdfConwerter = XlsToRdf.new
			# @xls_options = { :sheets => ["Makiety", "Zrodlo_danych", "Mapowanie_Makieta_Dane", "Legacy", "IPI", "Microservices", "Zaleznosci_Microservice_Legacy", "BackLog"] }
			@xls_options = { :sheets => step.parameters[:sheets]}
			runtime_code = -> {
				puts "ExcelLoader"
				puts step.parameters
				@runtime_variable_list[step.parameters[:output_vrbl]][:value] = @XlsToRdfConwerter.xls_to_rdf(@runtime_variable_list[step.parameters[:input_file_vrbl]][:value], @xls_options)
			}
		elsif type == "RuleEngine" then       # RdfRulesEngine step definition__________________________________________________________________
			@RdfRulesEngine = RdfRulesEngine.new
			@RdfRulesEngine.prefix = @runtime_variable_list[step.parameters[:prefix_vrbl]][:value]
			runtime_code = -> {
				@runtime_variable_list[step.parameters[:output_vrbl]][:value] = @RdfRulesEngine.execute(step.parameters[:rule_family], @runtime_variable_list[step.parameters[:input_vrbl]][:value], @runtime_variable_list[step.parameters[:rule_graph_vrlb]][:value])
				puts "RuleEngine"
				puts step.parameters[:output_vrbl]
				puts @runtime_variable_list[step.parameters[:output_vrbl]][:value].inspect
			}
		elsif type == "+" then       # Graph + Graph step definition_____________________________________________________________________________
			runtime_code = -> {
				@runtime_variable_list[step.parameters[:output_vrbl]][:value] << @runtime_variable_list[step.parameters[:input_vrbl]][:value]
			}
		elsif type == "Inference" then       # RdfInference step definition__________________________________________________________________
			@RdfInference = RdfInference.new
			runtime_code = -> {
				@runtime_variable_list[step.parameters[:output_vrbl]][:value] = @RdfInference.inference(@runtime_variable_list[step.parameters[:input_vrbl]][:value])
				puts "RdfInference"
				puts step.parameters[:output_vrbl]
				puts @runtime_variable_list[step.parameters[:output_vrbl]][:value].inspect
			}
		end
		step.parameters[:runtime_code] = runtime_code
		puts step.parameters
		@runtime_list << step.parameters
	end
end