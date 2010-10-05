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
    def private_method_defined? (method)
      private_instance_methods.map { |m| m.to_sym }.include?(method)
    end

    def filter_name (sym, type, counter)
      "__#{sym}__#{type}_filter_#{counter}__".to_sym
    end

    def filter (type, *syms, &block)
      syms.each do |sym|
        cnt += 1 while private_method_defined?(filter = filter_name(sym, type, cnt ||= 0))
        backup = (cnt != 0) ? filter_name(sym, type, cnt - 1) : sym
        alias_method filter, backup 
        private filter
        puts "#{backup} will now call #{filter}"
        define_method backup do |*args|
          send type, sym, filter, *args, &block
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

  def before (method, filter, *args)
    puts "before"
    call = { :type => :before, :method => method, :args => args }
    yield call, *args
    return call[:return] if call.has_key?(:return)
    send(filter, *call[:args])
  end

  def after (method, filter, *args)
    puts "after"
    call = { :type => :after, :method => method, :args => args, :return => send(filter, *args) }
    yield call, *args
    call[:return]
  end

  def self.included (base)
    base.extend(ClassMethods)
  end
end
