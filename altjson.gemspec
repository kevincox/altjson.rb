require_relative 'lib/altjson'

Gem::Specification.new do |s|
	s.name = 'altjson'
	s.version = AltJSON::VERSION
	s.authors = ['Kevin Cox']
	s.email = ['kevincox@kevincox.ca']
	s.homepage = 'https://github.com/kevincox/altjson.rb'
	s.summary = 'An alternate, efficient encoding for JSON data.'
	s.description = 'AltJSON is an encoding with the same data model as JSON designed to be efficient.'
	s.licenses = ['zlib']
	
	s.files = Dir['lib/**/*.rb', 'LICENSE', '*.md']
	s.test_files = Dir['test/**/*.rb']
	s.require_path = 'lib'
	
	s.add_development_dependency 'minitest', '~>5'
end
