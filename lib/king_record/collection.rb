module KingRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

# Assignment Problem 3 (#take): Assuming #take is supposed to be like Rails' version.

    def take(num)
      return_collection = Collection.new
      return_collection = self[0...num]
    end

# Assignment Problem 3 (#where): 

    def where(options)
      return_collection = Collection.new
      k = "@" + options.keys[0].to_s
      self.each { |obj| return_collection << obj if obj.instance_variable_get(k) == options.values[0] }
      return_collection
    end
  end
end