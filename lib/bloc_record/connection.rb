require 'sqlite3'
require 'pg'

module Connection
  def connection
    if @connection
      @connection
    elsif BlocRecord.database_filename.include?("sqlite")
      SQLite3::Database.new(BlocRecord.database_filename)
    elsif BlocRecord.database_filename.include?("pg")
      PG::Connection.new(BlocRecord.database_filename)
    end
  end
end
