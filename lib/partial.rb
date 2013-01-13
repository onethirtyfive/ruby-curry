class Partial
  class TooManyArguments < ArgumentError; end

  attr_reader :_method, :args, :lazy

  def initialize(_method, *args, lazy: false)
    @_method = _method
    @args    = args
    @lazy    = lazy
  end

  def supply(*addl_args)
    all_args = args + addl_args
    return new_from(_method, *all_args, lazy: true) if lazy

    begin
      call(*all_args)
    rescue ArgumentError
      new_from(_method, *all_args)
    end
  end

  def evaluate
    call(*args)
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
  def partial(_method, lazy: false)
    Partial.new(method(_method.to_sym), lazy: lazy)
  end
end
