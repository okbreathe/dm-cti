
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/autorun'
require 'minitest-rg'
require 'rr'
require 'dm-migrations'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dm-cti'

class MiniTest::Unit::TestCase
  include RR::Adapters::MiniTest

  def assert_same_elements(a1, a2, msg = nil)
    [:select, :inject, :size].each do |m|
      [a1, a2].each {|a| assert_respond_to(a, m, "Are you sure that #{a.inspect} is an array?  It doesn't respond to #{m}.") }
    end

    assert a1h = a1.inject({}) { |h,e| h[e] = a1.select { |i| i == e }.size; h }
    assert a2h = a2.inject({}) { |h,e| h[e] = a2.select { |i| i == e }.size; h }

    assert_equal(a1h, a2h, msg)
  end

  def assert_does_not_contain(collection, x, extra_msg = "")
    collection = [collection] unless collection.is_a?(Array)
    msg = "#{x.inspect} found in #{collection.to_a.inspect} " + extra_msg
    case x
    when Regexp
      assert(!collection.detect { |e| e =~ x }, msg)
    else
      assert(!collection.include?(x), msg)
    end
  end

  def assert_contains(collection, x, extra_msg = "")
    collection = [collection] unless collection.is_a?(Array)
    msg = "#{x.inspect} not found in #{collection.to_a.inspect} #{extra_msg}"
    case x
    when Regexp
      assert(collection.detect { |e| e =~ x }, msg)
    else
      assert(collection.include?(x), msg)
    end
  end

  def new_canine
    @canine = Canine.new(:name => 'canine', :legs => 4, :color => 'grey')
  end

  def new_wolf
    @wolf = Wolf.new(:name => 'wolf', :legs => 4, :color => 'black', :power_level => 9001)
  end

  def new_dog
    @dog = Dog.new(:name => 'dog', :legs => 4, :color => 'brown', :owner => "bob")
  end
end

MiniTest::Unit.autorun

require 'data.rb'
