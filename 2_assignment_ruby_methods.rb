# This file has the convert_to_camel_case and find_by methods.
# I am assuming that all snake_case values are lower case alpha numeric
# that do not begin with numeric and underscores are obviously allowed.

require 'sqlite3'

def convert_to_camel_case(snake)
    snake.gsub(/(^|_)(\w)/) { $2.upcase }
end

def find_by(attribute, value)
  connection.execute <<~SQL
    SELECT * FROM #{table}
    WHERE #{attribute} = #{value};
  SQL
end
