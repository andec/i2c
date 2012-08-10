Gem::Specification.new do |s|
  s.name        = 'i2c'
  s.version     = '0.1.1'
  s.date        = '2012-08-03'
  s.summary     = "I2C access library (for Linux)."
  s.description = "Interface to I2C (aka TWI) implementations. Also provides abstractions for some I2c-devices. Created with the Raspberry Pi in mind."
  s.authors     = ["Christoph Anderegg"]
  s.email       = 'christoph@christoph-anderegg.ch'
  s.files       = ["lib/i2c.rb", 
  		   "lib/i2c/i2c.rb", 
		   "lib/i2c/backends/i2c-dev.rb", 
  		   "lib/i2c/drivers/mcp23017.rb",
		   "test//mcp23017_spec.rb",
		   "rules/88-i2c.rules"]
  s.extra_rdoc_files = ['README.rdoc']
  s.homepage    = 'https://github.com/andec/i2c'
end
