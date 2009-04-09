require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = "tokyotyrant"
  s.version = "1.5"
  s.author "Mikio Hirabayashi"
  s.email = "mikio@users.sourceforge.net"
  s.homepage = "http://tokyocabinet.sourceforge.net/"
  s.summary = "Tokyo Tyrant: network interface of Tokyo Cabinet."
  s.description = "Tokyo Tyrant is a package of network interface to the DBM called Tokyo Cabinet.  Though the DBM has high performance, you might bother in case that multiple processes share the same database, or remote processes access the database.  Thus, Tokyo Tyrant is provided for concurrent and remote connections to Tokyo Cabinet.  It is composed of the server process managing a database and its access library for client applications."
  s.files = [ "tokyotyrant.rb" ]
  s.require_path = "."
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
