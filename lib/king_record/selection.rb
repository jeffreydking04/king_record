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
# sqlite3 does not raise an error if any of the inputs are invalid.
# It either returns nil if no record matching the id is found, or
# it returns the records that are matched if not all ids are present.
# But apparently Rails will raise an error, but only in its #find method.
# My research suggests that Rails will return nil if no records are found
# or return the set of records that were found if some of the parameters wer
# valid and others were not.
# I am going to take Rails' lead here and raise an error if there are fewer rows
# than there were paramters passed.  The application developer needs to 
# decide how to write his/her code so that user input will not result in this error.
# I will also raise this error in find_one if no record is found.  
# In all other selection methods, I will return the sql return, just as Rails does.

      raise "Invalid id present" if !rows || rows.size != ids.size

      rows_to_array(rows)
    end
  end

  def find_one(id)
    row = connection.get_first_row <<~SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL

    raise "Invalid id" if !row

    init_object_from_row(row)
  end

# Neat stuff.  Because we cannot write methods such as #find_by_favorite_football_coach
# (Pete Carroll, of course) for every conceivable attribute that a model might have, but
# we still want to provide a way for the user to have access to #find_by_attribute methods
# for all the attributes associated with a model, we can use this little mind blowing method.
# When method_missing is present in a class, if the user calls a method that does
# not exist, it and an array of the arguments passed to it are sent here.

# #find_by does not handle multiple values, but requires 1, so an error is raised
# if args is empty or if there is more than one argument.
# #method_missing passes the call method as a symbol.  So it is converted to a string, 
# which #find_by currently is expecting.  The idea is to make #find_by dynamic, so 
# the string is checked to be sure its first 8 chars are "find_by_". An error is raised 
# otherwise.  Then the part of the string following "find_by_" is checked to ensure that
# it is an attribute of the Model calling the method.  An error is raised if not.  If it
# is, then a call to #find_by with the string and the value as parameters is made.

  def method_missing(symbol, *args)
    raise "Unexpected number of arguments" if args.empty? || args.size > 1
    str = symbol.to_s
    raise "No method found: #{str}" if str.slice(0..7) != "find_by_"
    attribute = str.slice(8..-1)
    raise "No method found #{str}" if !columns.include?(attribute)
    find_by(attribute, args[0])
  end

# #find_each takes a hash with an empty default.  The method assigns start and batch_size
# variables if they exist.  If one or the other is not present, then the entire table is 
# selected and assigned to rows.  Then rows is cycled through and each row is instantiated 
# and yielded to the block, if given.  Otherwise, it returns an array of objects. If there are any issues with start value
# or batch size, the method returns yields or returns instances of all records..

  def find_each(hash={}, &block)
    if hash[:start].is_a?(Integer)
      start = hash[:start] - 1
    else
      start = hash[:start]
    end 
    start = 0 if !start
    batch_size = hash[:batch_size]
    if ( !batch_size || 
         !start.is_a?(Integer)  || 
          start >= count || 
          start < 0 || 
         !batch_size.is_a?(Integer) || 
          batch_size < 1
       )
            rows = connection.execute("select * from #{table}")
    else
      batch_size = count - start if count - start < batch_size
      rows = connection.execute("select * from #{table} limit #{batch_size} offset #{start}")
    end
    if block_given?
      rows.each { |row| yield(new(Hash[columns.zip(row)])) }
    else
      rows_to_array(rows)
    end
  end

# This one is a little weird.  I am not sure exactly what was wanted.  The assignment
# says to yield batches to a block as an array of models.  Then it shows a block that
# takes two arugments, but I only see the need for one.  I took this to mean that we wanted
# to query the database from a given start value in batches, yielding an array of x objects 
# repeatedly until the end of the table.  So that is how I wrote it.  If there are errors
# in the inputs, the method returns or yields one array of objects representng all the records in the 
# table.  Otherwise, it queries the database in batches, and pushes those batches (instantiated)
# to an array, which is then cycled through and each batch is yielded to the block if given, else
# the entire array of batches is returned.

# Update: Looking up the Rails' #find_in_batches, I see that it is as I wrote it.  It yields
# a single array, but if you call Class.find_in_batches.with_index, then your block will have
# two block arguments.  I believe this is straight out of the Ruby on Rails 5.0.0.1 docs.

# With the #find_each and #find_in_batches, I attempted to gracefully handle bad input.

  def find_in_batches(hash={}, &block)
    if hash[:start].is_a?(Integer)
      start = hash[:start] - 1
    else
      start = hash[:start]
    end 
    start = 0 if !start
    batch_size = hash[:batch_size]
    if ( !batch_size || 
         !start.is_a?(Integer)  || 
          start >= count || 
          start < 0 || 
         !batch_size.is_a?(Integer) || 
          batch_size < 1
       )  
            rows = connection.execute("select * from #{table}")
            rows = rows_to_array(rows)

            if block_given?
              yield rows
            else
              return rows
            end
    else
      batch = []
      while(start < count)
        batch_size = count - start if count - start < batch_size
        rows = connection.execute("select * from #{table} limit #{batch_size} offset #{start}")
        batch << rows_to_array(rows)
        start += batch_size
      end
      if block_given?
        batch.each { |records| yield records }
      else
        return batch
      end
    end
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
