def meth(hash={}, &block)
  start = hash[:start]
  finish = start + hash[:batch_size]
  (start...finish).each do |x|
    yield (x)
  end
end

meth(start: 57, batch_size: 15) do |y|
  puts y
end
