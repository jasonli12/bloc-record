require 'sqlite3'

module Selection
  def find(*ids)
    if ids.all? {|i| i.is_a? Integer && i >= 0}
      if ids.length == 1
        find_one(ids.first)
      else
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
        SQL

        rows_to_array(rows)
      end
    else
      p "Invalid id"
    end
  end

  def find_one(id)
    if id.is_a? Integer && id >= 0
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    else
      p "Invalid id"
    end
  end

  def find_by(attribute, value)
    if attributes.include?(attribute)
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
      SQL

      rows_to_array(rows)
    else
      p "Invalid attribute"
    end
  end

  def take_one
    row = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row
  end

  def take(num=1)
    if num > 1 && num.is_a? Integer
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    elsif num == 1
      take_one
    else
      p "Invalid value"
    end
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
    SQL

    rows_to_array(rows)
  end

  def find_each(start: 0, batch_size: all.length, &block)
    all.slice!(start, batch_size)
    all.each do |record|
      yield(self.class.new(record)) #assuming that the subclass is implementing an initialize function that accepts the record
    end
  end

  def find_in_batches(start: 0, batch_size: all.length, &block)
    all.length % batch_size > 0 ? number_of_batches = all.length / batch_size + 1 : number_of_batches = all.length / batch_size
    batch_number = 1
    all_records = all
    while batch_number <= number_of_batches
      batch_models = []
      if batch_number != number_of_batches
        batch_records = all_records.slice!(start, batch_size)
      else
        batch_records = all_records.slice!(start, all_records.length)
      end
      batch_records.each do |record|
        batch_models.push(self.class.new(record))
      end
      yield(batch_models, batch_number)
      start += batch_size
      batch_number += 1
    end
  end

  def method_missing(m, *args, &block)
    attribute = m.to_s.gsub(/find_by_/,'')
    if attributes.include?(attribute)
      if args.length = 1
        find_by(attribute, args[0])
      else
        sql_args = args.map {|i| BlocRecord::Utility.sql_strings(i) }
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          WHERE #{attribute} IN (#{sql_args.join(",")});
        SQL

        rows_to_array(rows)
      end
    else
      p "Invalid attribute"
    end
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")}
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = args.first.to_s
    end
    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      elsif Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      end
    end
    rows_to_array(rows)
  end

  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
