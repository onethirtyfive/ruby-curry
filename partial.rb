class Partial
  class TooManyArguments < ArgumentError; end

  attr_reader :_method, :args

  def initialize(_method, *args)
    @_method = _method
    @args    = args

    raise TooManyArguments.new(args.inspect) if @args.size > arity
  end

  def supply(*addl_args)
    all_args = args + addl_args

    if all_args.size == arity
      call(*all_args)
    else
      new_from(_method, *all_args)
    end
  end

  private

  def call(*args)
    _method.call(*args)
  end

  def arity
    _method.arity
  end

  def new_from(method, *args)
    self.class.new(method, *args)
  end
end

class Object
  def partial(_method, *args)
    Partial.new(method(_method.to_sym), *args)
  end
end

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

  def test_that_it_can_be_supplied_remaining_arguments
    assert_equal 6, partial.supply(2, 3)
  end

  def test_that_it_returns_a_new_partial_with_partial_arguments
    assert_instance_of Partial, partial.supply(1)
  end

  def test_that_it_raises_on_excessive_arguments
    assert_raises Partial::TooManyArguments do
      partial.supply(1, 2, 3)
    end
  end

  def test_that_it_can_be_returned_from_objects
    assert_instance_of Partial, "string".partial(:chop)
  end

  def test_that_it_can_take_arguments_when_called_on_object
    assert_equal [1], [1, 2].partial(:member?, 1).args
  end

  def test_that_it_can_chain_partial_and_supply_calls
    assert_equal true, [1, 2].partial(:member?).supply(1)
  end
end
