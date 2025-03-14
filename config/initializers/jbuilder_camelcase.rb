module JbuilderCamelCase
  def set!(key, value = nil, *args, **kwargs, &block)
    key = key.to_s.camelize(:lower) # Convert to lowerCamelCase
    super(key, value, *args, **kwargs, &block)
  end
end

Jbuilder.prepend(JbuilderCamelCase)
