
Gem::Specification.new do |s|
	s.name = 'rdf_process'
	s.version = '0.0.3'
	s.date = '2020-10-01'
	s.executables << 'rdf_process'
	s.summary = "Process engine"
	s.description = "Process engine. New step: RdfToTurtleFile"
	s.authors = ["WiDu"]
	s.email = 'wdulek@gmail.com'
	s.files = ["lib/rdf_process.rb", "lib/rdf_process/RdfProcessDefinitionLike.rb"]
	s.homepage = 'https://github.com/widu/rdf_process'
	s.license = 'MIT'
	s.add_runtime_dependency "linkeddata"
	s.add_runtime_dependency "sparql"
	s.add_runtime_dependency "rdf_to_graphviz"
	s.add_runtime_dependency "rdf_rules_engine"
	s.add_runtime_dependency "xls_to_rdf"
	s.add_runtime_dependency "rdf_inference"
end

