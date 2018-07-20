module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(limit = 1)
      self.length > limit ? self.slice(0, limit) : self
    end

    def where(criteria)
      subcollection = []
      criteria_key = criteria.keys[0]
      criteria_value = criteria.values[0]
      self.each do |record|
        subcollection.push(record) if record[criteria_key] == criteria_value
      end
      subcollection
    end

    def not(criteria)
      subcollection = []
      criteria_key = criteria.keys[0]
      criteria_value = criteria.values[0]
      self.each do |record|
        subcollection.push(record) if record[criteria_key] != criteria_value
      end
      subcollection
    end
  end
end
