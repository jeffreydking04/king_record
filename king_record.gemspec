Gem::Specification.new do |s|
  s.name          = 'king_record'
  s.version       = '0.0.0'
  s.date          = 2016-12-5
  s.summary       = 'A Learnin ORM'
  s.description   = 'A Slimmed Down ActiveRecord Clone For Learning Purposes Only'
  s.authors       = ['jdking']
  s.email         = 'jdking33@aol.com'
  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.license       = 'MIT'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
end