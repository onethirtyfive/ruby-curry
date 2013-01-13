require_relative '../lib/partial.rb'
require 'minitest/autorun'

Curryable.global!

class Adder
  include Curryable

  def add3(x, y, z)
    x + y + z
  end

  def_partial :add1, :add3, 1, 2
end

class PartialTest < Minitest::Unit::TestCase
  def adder
    @adder ||= Adder.new
  end

  def partial
    @partial ||= Partial.new('add3', adder.method(:add3), [1])
  end

  def test_that_it_initializes
    assert_equal :add3, partial._method.name
    assert_equal [1],   partial.args
  end

  def test_that_it_returns_a_result_when_supplied_all_arguments
    assert_equal 6, partial.supply(2, 3)
  end

  def test_that_it_returns_a_new_partial_with_partial_arguments
    assert_instance_of Partial, partial.supply(1)
  end

  def test_that_it_is_immutable
    partial.supply(2)
    assert_equal [1], partial.args
  end

  def test_supply_operator
    assert_equal [1, 2], (partial << 2).args
  end

  def test_that_it_is_returned_from_objects
    assert_instance_of Partial, adder.partial(:add3)
  end

  def test_that_it_chains_partial_and_supply_calls
    assert_equal true, [1, 2].partial(:member?).supply(1)
  end

  def test_that_it_tries_evaluation_if_method_has_ambiguous_arity
    assert_equal ["one", "two"], "one two".partial(:split).supply()
    assert_equal ["one", "two"], "one,two".partial(:split).supply(",")
    assert_equal ["one,two"],    "one,two".partial(:split).supply(",", 1)
  end
  
  def test_that_supply_doesnt_evaluate_if_lazy
    assert_instance_of Partial, [1, 2].partial(:member?, lazy: true).supply(1)
  end

  def test_that_it_evaluates_lazy_partials
    assert_equal true, [1, 2].partial(:member?, lazy: true).supply(1).evaluate
  end

  def test_that_it_binds_to_instances
    unbound = Adder.instance_method(:add3)
    partial = Partial.new(:unbound, unbound, [])
    assert_instance_of UnboundMethod, partial._method
    assert_instance_of Method, partial.bound_to(adder)._method
  end

  def test_def_partial
    assert_equal 6, adder.add1(3)
  end
end
