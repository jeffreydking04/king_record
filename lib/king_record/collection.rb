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
  end
end