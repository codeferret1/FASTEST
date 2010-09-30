class Array
  # to hash from key-value pairs
  def to_h_from_kv
    Hash[*self.flatten(1)]
  end
end
