require File.expand_path('../redis-orm', File.dirname(__FILE__))
require 'active_support/core_ext'
require 'active_model'
require 'redis/relations'
require 'redis/validations'
require 'redis/orm/attributes'
require 'redis/actions'

class Redis::ORM
  class_attribute :serializer
  self.serializer ||= Marshal
  delegate :model_name, :to => "self.class"
  delegate :connection, :to => :Redis

  extend ActiveModel::Callbacks
  extend ActiveModel::Naming
  include ActiveModel::Validations

  define_model_callbacks :initialize

  include Redis::ORM::Attributes
  include Redis::Actions
  include Redis::Relations
  include Redis::Validations

  attribute :id
  validates_uniqueness_of :id

  class << self
    delegate :connection, :to => :Redis
  end

  def to_key
    persisted? ? id : nil
  end

  def to_param
    persisted? ? File.join(model_name, id) : nil
  end

  def persisted?
    !new_record? && !changed?
  end

  def initialize(attributes = {})
    run_callbacks :initialize do
      self.attributes = attributes
      @previous_attributes = nil
    end
  end

  def transaction(&block)
    connection.multi &block
  end

  def ==(other)
    other && id == other.id
  end
end
