module KingRecord
  class Collection < Array

# This is kind of weird, because I am writing the sorting technique myself. 
# When we use Collection to do things like a mass update, we are eventually
# doing a SQL update on each object in the Collection.  Here, we are not
# making a new SQL query with ORDER BY, we are just sorting an array.  I am
# going to implement it with one parameter only, just to make it minimally functional.

    def order(attribute)
      attribute = "@" + attribute
      attribute = attribute.to_sym
      sorted_array = KingRecord::Collection.new
      sorted_array << self[0]
      (1...self.size).each do |x|
        (0...sorted_array.size).each do |y|
          if self[x].instance_variable_get(attribute) < sorted_array[y].instance_variable_get(attribute)
            sorted_array.insert(y, self[x])
            break
          end
          sorted_array << self[x] if y == sorted_array.size
        end 
      end
      sorted_array
    end
  end
end
