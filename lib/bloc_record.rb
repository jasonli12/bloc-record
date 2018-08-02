module BlocRecord
  def self.connect_to(filename, db)
    @database_filename = filename.gsub(/.db/, "." + db.to_s)
  end

  def self.database_filename
    @database_filename
  end
end
