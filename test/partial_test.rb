require_relative '../lib/partial.rb'
require 'minitest/autorun'

Curryable.global!

class Adder
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

  def test_that_it_is_returned_from_objects
    assert_instance_of Partial, adder.curry(:add3)
  end

  def test_that_it_chains_partial_and_supply_calls
    assert_equal true, [1, 2].curry(:member?).supply(1)
  end

  def test_that_it_tries_evaluation_if_method_has_ambiguous_arity
    assert_equal ["one", "two"], "one two".curry(:split).supply()
    assert_equal ["one", "two"], "one,two".curry(:split).supply(",")
    assert_equal ["one,two"],    "one,two".curry(:split).supply(",", 1)
  end
  
  def test_that_supply_doesnt_evaluate_if_lazy
    assert_instance_of Partial, [1, 2].curry(:member?, lazy: true).supply(1)
  end

  def test_that_it_evaluates_lazy_partials
    assert_equal true, [1, 2].curry(:member?, lazy: true).supply(1).evaluate
  end

  def test_that_it_binds_to_instances
    unbound_method  = Adder.instance_method(:add3)
    unbound_partial = Partial.new(:unbound, unbound_method, [])
    bound_partial   = unbound_partial.bound_to(adder)

    refute_respond_to unbound_partial._method, :call
    assert_respond_to bound_partial._method,   :call
  end

  def test_def_partial
    assert_equal 6, adder.add1(3)
  end
end
