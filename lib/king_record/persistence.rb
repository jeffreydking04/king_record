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

    def update(ids, updates)
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

      true    
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*ids)
      if ids.length > 1
        where_clause = "WHERE id IN (#{ids.join(",")});"
      else
        where_clause = "WHERE id = #{ids.first};"
      end

      connection.execute <<~SQL
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end

# Assignment Problems 2 and 3: Assuming that if args is size 1, it is a hash or a string.
# If mas, then it is an array.

    def destroy_all(*args)
      if args.size == 1
        case args.first
        when Hash
          conditions_hash = KingRecord::Utility.convert_keys(args.first)
          conditions = conditions_hash.map { |key, value| "#{key}=#{KingRecord::Utility.sql_strings(value)}" }.join(" and ")

          connection.execute <<~SQL
            DELETE FROM #{table}
            WHERE #{conditions};
          SQL
        when String
          connection.execute <<~SQL
            DELETE FROM #{table} 
            WHERE #{args.first};
          SQL
        else
          raise "Invalid input"
        end
      elsif args.size > 1
        expression = args.shift
        params = args

        sql = <<~SQL
          DELETE FROM #{table}
          WHERE #{expression};
        SQL

        connection.execute(sql, params)       
      else
        connection.execute <<~SQL
          DELETE FROM #{table};
        SQL
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

  def destroy
    self.class.destroy(self.id)
  end
end
