
module Inspectable
  def method_missing(method, *args, &block)
    res = nil
    if method.to_s =~ /\Afind_(\S+)\Z/
      res = inspectable_delegator($1, :==, *args, &block)
    elsif method.to_s =~ /\Amatch_(\S+)\Z/
      res = inspectable_delegator($1, :=~, *args, &block)
    end
    unless res.nil?
      res.first
    else
      super
    end
  end

  private

  def inspectable_delegator (method_suffix, matcher, *args, &block)
    unless method_suffix.to_s =~ /\A((all|first|last)_)?by_(\S+)\Z/
      return nil
    end
    attributes = $3.split("_and_")
    im = self.instance_methods
    attributes.each { |a| return nil unless im.include?(a) }
    selector = $2
    selector ||= "smart"
    selector = selector.to_sym
    res = all.values.select do |w|
      not attributes.each_index do |i|
        break nil unless w.send(attributes[i]).send(matcher, args[i], &block)
      end.nil?
    end
    case selector
    when :first
      [res.first]
    when :last
      [res.last]
    when :all
      [res]
    when :smart
      case res.size
      when 0
        [nil]
      when 1
        [res.first]
      else 
        [res]
      end
    end
  end
end

