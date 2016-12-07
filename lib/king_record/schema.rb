require 'sqlite3'
require 'king_record/utility'

module Schema
  def table
    KingRecord::Utility.underscore(name)
  end

  def columns
    schema.keys
  end

  def attributes
    columns - ["id"]
  end

  def schema
    unless @schema
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"]] = col["type"]
      end
    end
    @schema
  end

  def count
    connection.execute(<<~SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL
  end
end
