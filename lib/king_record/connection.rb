require 'sqlite3'

module Connection
  def connection
    @connection ||= SQLite3::Database.new(KingRecord.database_filename)
  end
end
