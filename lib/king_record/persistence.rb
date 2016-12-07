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
end
