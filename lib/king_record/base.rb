require 'king_record/utility'
require 'king_record/schema'
require 'king_record/persistence'
require 'king_record/selection'
require 'king_record/connection'

module KingRecord
  class Base
    include Persistence
    extend Selection
    extend Schema
    extend Connection

    def initialize(options={})
      options = KingRecord::Utility.convert_keys(options)

      self.class.columns.each do |col|
        self.class.send(:attr_accessor, col)
        self.instance_variable_set("@#{col}", options[col])
      end
    end
  end
end
