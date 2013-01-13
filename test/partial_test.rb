require_relative '../lib/partial.rb'
require 'minitest/autorun'

def add3(x, y, z)
  x + y + z
end

class PartialTest < Minitest::Unit::TestCase
  def partial
    @partial ||= Partial.new(method(:add3), 1)
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
    assert_instance_of Partial, "string".partial(:chop)
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
end
