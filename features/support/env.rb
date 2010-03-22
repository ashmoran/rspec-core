$LOAD_PATH << File.expand_path("../../../../rspec-expectations/lib", __FILE__)
require 'rspec/expectations'
require 'aruba'

module ArubaOverrides
  def detect_ruby_script(cmd)
    if cmd =~ /^rspec /
      # TODO figure out why `-r rubygems` became necessary - it's not ideal either,
      # as it means that Cucumber is loading rspec/expectations from gems
      "ruby -r rubygems -I../../lib -S ../../bin/#{cmd}"
    else
      super(cmd)
    end
  end
end

World(ArubaOverrides)

