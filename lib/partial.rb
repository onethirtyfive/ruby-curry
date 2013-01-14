class Partial
  class TooManyArguments < ArgumentError; end

  attr_reader :name, :_method, :args, :lazy

  def initialize(name, _method, args, lazy: false)
    @name    = name.to_sym
    @_method = _method
    @args    = args
    @lazy    = !!lazy
  end

  def supply(*addl_args)
    all_args = args + addl_args
    return new_from(name, _method, all_args, lazy) if lazy

    begin
      call(*all_args)
    rescue ArgumentError
      new_from(name, _method, all_args, lazy)
    end
  end

  def evaluate
    call(*args)
  end

  def bound_to(obj)
    new_from(name, _method.bind(obj), args, lazy)
  end

  private

  def call(*args)
    _method.call(*args)
  end

  def new_from(name, meth, args, lazy)
    self.class.new(name, meth, args, lazy: lazy)
  end
end

module Curryable
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:extend,  ClassMethods)
  end

  def self.global!
    Object.send(:include, self)
  end

  module InstanceMethods
    def curry(method_name, **options)
      _method = method(method_name.to_sym)
      Partial.new(method_name, _method, [], options)
    end

    def method_missing(name, *args, &blk)
      if partial = self.class.partials.find {|p| p.name == name}
        bound = partial.bound_to(self).supply(*args)
        bound.is_a?(Partial) ? bound.evaluate : bound
      else
        super
      end
    end
  end

  module ClassMethods
    def partials
      @partials ||= []
    end

    def def_partial(name, _method, *args)
      _method = instance_method(_method.to_sym)
      partial = Partial.new(name, _method, args)
      
      partials << partial
    end
  end
end
