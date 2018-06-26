require 'sqlite3'

module Selection
  def find(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    data = Hash[columns.zip(row)]
    new(data)
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{value};
    SQL

    data = rows.map {|row| Hash[columns.zip(row)]}
  end
end
