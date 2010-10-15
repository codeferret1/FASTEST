#
# Based on raggi's refactored version of the FollowingHook module's code.
# http://refactormycode.com/codes/656-method-hooks-in-ruby-any-cleaner
#
# Main changes:
# - Removed Ruby version test (Ruby 1.8 and 1.9 both work).
# - Support not only "after" but also "before" hooks.
# - Transformed "hooks" into "filters" (allow changing of args, and return values).
# - Allow multiple filters to be installed and uninstalled.
#
module MethodFilter
  module ClassMethods
    def remove_filter (type, *syms)
      syms.each { |sym| __filters__[type][sym] = [] }
    end

    def __filters__
      return class_variable_get(:@@__filters__) if class_variable_defined?(:@@__filters__)
      class_variable_set(:@@__filters__, {:before => {}, :after => {}})
    end

    private

    def filter (type, *syms, &block)
      syms.each do |sym|
        __filters__.each_key { |k| __filters__[k][sym] ||= [] }
        __filters__[type][sym] << block
        filter = "__#{sym}__filter__".to_sym
        next if private_instance_methods.map { |m| m.to_sym }.include?(filter)
        alias_method filter, sym
        private filter
        define_method sym do |*args|
          call = { :method => sym, :args => args, :instance => self }
          self.class.__filters__[:before][sym].each do |b|
            send :execute_filter, :before, call, &b
            break if call.has_key?(:return)
          end
          unless call.has_key?(:return)
            call[:return] = send filter, *call[:args] 
            self.class.__filters__[:after][sym].each { |b| send :execute_filter, :after, call, &b }
          end
          call[:return]
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
