Gem::Specification.new do |s|
  s.name        = 'i2c'
  s.version     = '0.0.1'
  s.date        = '2012-08-03'
  s.summary     = "I2C access library."
  s.description = "Interface to Linux I2C (a.k.a. TWI) implementations."
  s.authors     = ["Christoph Anderegg"]
  s.email       = 'christoph@christoph-anderegg.ch'
  s.files       = ["lib/i2c.rb", 
  		   "lib/i2c/i2c.rb", 
		   "lib/i2c/backends/i2c-dev.rb", 
  		   "lib/i2c/drivers/mcp17026.rb",
		   "rules/88-i2c.rules"  ]
#  s.homepage    = 'http://rubygems.org/gems/i2c'
end