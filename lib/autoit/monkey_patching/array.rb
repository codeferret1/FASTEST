class Array
  def to_hash(&block)
    Hash[*self.collect { |k, v|
      [k, v]
    }.flatten]
  end
end
