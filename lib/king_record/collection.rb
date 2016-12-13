module KingRecord
  class Collection < Array
    def update_all(updates)
      id = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end
  end
end