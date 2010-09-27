
module Inspectable

  def matches_condition? (condition)
    Inspectable::matches_condition?(self, condition)
  end

  def self.matches_condition? (obj, condition)
    eval_str = condition.gsub(/\B\.\b/, "obj.")
    if eval(eval_str)
      return true
    end
    return false
  end
end

module Enumerable

  def where (condition)
    if is_a?(Array)
      s = select do |v|
        Inspectable::matches_condition?(v, condition)
      end
      return s
    end

    if is_a?(Hash)
      s = select do |k, v|
        Inspectable::matches_condition?(v, condition)
      end
      return s
    end
    
    raise "Unknown enumerable"
  end

  def first_where (condition)
    where(condition).first
  end
end

