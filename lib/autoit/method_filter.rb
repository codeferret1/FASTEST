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
      @@__filters__ ||= { :before => {}, :after => {} }
      syms.each { |sym| @@__filters__[type][sym] = [] }
    end

    private

    def filter (type, *syms, &block)
      syms.each do |sym|
        @@__filters__ ||= { :before => {}, :after => {} }
        @@__filters__.each_key { |k| @@__filters__[k][sym] ||= [] }
        @@__filters__[type][sym] << block
        filter = "__#{sym}__filter__".to_sym
        next if private_instance_methods.map { |m| m.to_sym }.include?(filter)
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
