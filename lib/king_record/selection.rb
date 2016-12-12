require 'sqlite3'

module Selection
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<~SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL
      
      rows_to_array(rows)
    end
  end

  def find_one(id)
    row = connection.get_first_row <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{KingRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<~SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<~SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    if args.count > 1
      expression = arg.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = KingRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key}=#{KingRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

# Okay, because we never checked the #order method in the checkpoint, 
# I never caught that I had missed the splat operator, so that needed to be
# added.  Also, the checkpoint did not write it to handle hashes, so I 
# implemented that, per the examples on the assignment.  Each form is now
# processed correctly.

  def order(*args)
    if args.count > 1
      case args.last
      when Hash
        hash = args.pop
        order = args.join(",")
        order << ","
        hash.each do |key, value|
          order = order + key.to_s + " " + value.to_s + ","
        end
        order.slice!(-1)
      else
        order = args.join(",")
      end
    else
      case args.first
      when String
        order = args.first
      when Symbol
        order = args.first.to_s
      when Hash
        order = ""
        args.first.each do |key, value|
          order = order + key.to_s + " " + value.to_s + ","
        end
        order.slice!(-1)
      end
    end
    rows = connection.execute <<~SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    rows_to_array(rows)
  end

# For testing the #joins method, I added a comment table (and Comment Class) that references
# entry_id as a foreign key.

# The way this was written in the checkpoint does not work correctly when a string is entered.
# I went to the Rails docs to figure out what was supposed to be returned and changed it.
# If a single string is entered, we assume that it is a proper inner join sql string and 
# append it to "SELECT * FROM #{table}" WITHOUT sending it through #sql_strings, which places
# single quotes around the string entered and is NOT processed by sql and thus sql returns
# ALL records from the calling Model, not just the ones who match the join condition.

# Also, the way this is written in the checkpoint will not work with calls such as 
# AddressBook.joins(:entry, :comment), where comment references entry as a foreign key.
# It produces the following append as written:

# INNER JOIN entry ON entry.address_book_id = address_book.id 
# JOIN comment ON comment.address_book_id = address_book.id

# But that is not what is wanted.  Per the the Rails' docs and common sense about what is 
# desired, Article.joins(:category, :comments) produces:

# SELECT articles.* FROM articles
#  INNER JOIN categories ON articles.category_id = categories.id
#  INNER JOIN comments ON comments.article_id = articles.id

# Of course, the difference is that the method, as written in the checkpoint, is
# designed to write the join condition of each successive table as if it were
# referencing the calling Model, instead of, appropriately, chaining the condition
# to the previous table chained.

# So I fixed that.

# Finally, I was able to address the assignment problem #2, nested associations.  
# I consulted the Rails's docs and see that AddressBook.joins(:entry, :comment)
# should produce the same sql query as AddressBook.joins(entry: :comment) and that
# it is a "single level" query, which I take to mean that if we want to join
# more than two tables to the calling Model, we should use the former format.

# So, yeah, done.

  def joins(*args)
    if args.count > 1
      joins = "INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id"
      (1...args.size).each do |index|
        joins << " INNER JOIN #{args[index]} ON #{args[index]}.#{args[index - 1]}_id = #{args[index - 1]}.id"
      end
      rows = connection.execute <<~SQL
        SELECT * FROM #{table} #{joins};
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<~SQL
          SELECT * FROM #{table} #{args.first};
        SQL
      when Symbol
        rows = connection.execute <<~SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id;
        SQL
      when Hash
        joins = <<~SQL
          INNER JOIN #{args[0].keys[0]} ON #{args[0].keys[0]}.#{table}_id = #{table}.id
          INNER JOIN #{args[0].values[0]} ON #{args[0].values[0]}.#{args[0].keys[0]}_id = #{args[0].keys[0]}.id
        SQL
        rows = connection.execute <<~SQL
          SELECT * FROM #{table} #{joins};
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
    collection = KingRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
