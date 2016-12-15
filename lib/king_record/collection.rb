module KingRecord
  class Collection < Array
    def update_all(updates)
      id = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def destroy_all
      self.each do |record|
        record.destroy
      end
    end

# This is another strange implementation because we do not know which attributes we 
# selected on, do to the nature of our Collection object.  So what I did was grab the 
# the instance variables from the first object in the collection.  Then I set up an 
# array to hold all distinct sets of instance variable values from the objects in the
# Collection.  I then cycle through the objects in the collection and create an array
# of the attribute values it takes on.  If that set does not match one that is already 
# in the distinct sets array, then it is unique and the object is passed to the return 
# Collection and the set is passed to the distinct sets array.

    def distinct
      instance_variables = self[0].instance_variables
      distinct_sets_of_values = []
      return_collection = KingRecord::Collection.new
      self.each do |obj|
        set = []
        instance_variables.each do |attribute|
          set << obj.instance_variable_get(attribute)
        end
        if !distinct_sets_of_values.include?(set)
          return_collection << obj
          distinct_sets_of_values << set    
        end
      end
      return_collection
    end
  end
end