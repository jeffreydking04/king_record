require 'sqlite3'
require 'king_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def create(attrs)
      attrs = KingRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| KingRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<~SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

# Assignment Problem 1:  This is a quick and painless way to accomplish what the problem
# asks for.  Check the updates parameter.  If it is a hash, then operate normally.  If it
# is an array, then it should be an array of hashes, each corresponding to an id in the 
# ids array.  We simply recursively call update with each set.

    def update(ids, updates)
      if updates.class == Hash
        updates = KingRecord::Utility.convert_keys(updates)
        updates.delete "id"
        updates_array = updates.map { |key, value| "#{key}=#{KingRecord::Utility.sql_strings(value)}"}

        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause == ";"
        end

        connection.execute <<~SQL
          UPDATE #{table}
          SET #{updates_array * ","} #{where_clause}
        SQL
      else
        (0...ids.size).each do |index|
          self.update(ids[index], updates[index])
        end
      end

      true    
    end
  end

  def save!
    if !self.id
      self.id = self.class.create(KingRecord::Utility.instance_variables_to_hash(self)).id
      KingRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{KingRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}"}.join(",")

    self.class.connection.execute <<~SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    true
  end

  def save 
    self.save! rescue false
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  def update_all(updates)
    update(nil, updates)
  end

# Assignment Problem 2:  Assuming a call in the form of p.update_attribute("value")

  def method_missing(method_given, value)
    raise "No method found." if method_given.slice(0, 7) != "update_"
    attribute = method_given.slice(7, method_given.length - 7)
    raise "No method found." if !self.class.attributes.include?(attribute)
    self.class.update(self.id, { attribute => value })
  end
end
