#
# Based on raggi's refactored version of the FollowingHook module's code.
# http://refactormycode.com/codes/656-method-hooks-in-ruby-any-cleaner
#
# Main changes:
# - Removed Ruby version test (still works for Ruby 1.8 and 1.9)
# - Support not only "after" but also "before" hooks.%
# - Allow multiple filters to be installed (no support for uninstalling)
# - Transformed "hooks" into "filters"
#
module MethodFilter
  module ClassMethods
    private

    def filter (type, *syms, &block)
      syms.each do |sym|
        @@__filters__ ||= { :before => {}, :after => {} }
        @@__filters__.each_key { |k| @@__filters__[k][sym] ||= [] }
        @@__filters__[type][sym] << block
        filter = "__#{sym}__filter__".to_sym
        return if private_instance_methods.map { |m| m.to_sym}.include?(filter)
        alias_method filter, sym
        private filter
        define_method sym do |*args|
          call = { :method => sym, :args => args }
          @@__filters__[:before][sym].each do |b|
            send :execute_filter, :before, call, &b
            return call[:return] if call.has_key?(:return)
          end
          call[:return] = send filter, *call[:args] 
          @@__filters__[:after][sym].each { |b| send :execute_filter, :after, call, &b }
          return call[:return]
        end
      end
    end

    def before_filter (*syms, &block)
      filter(:before, *syms, &block)
    end

    def after_filter (*syms, &block)
      filter(:after, *syms, &block)
    end
  end

  def execute_filter (type, call)
    call[:type] = type
    yield call, *call[:args]
  end

  def self.included (base)
    base.extend(ClassMethods)
  end
end
