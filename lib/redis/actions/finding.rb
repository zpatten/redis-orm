module Redis::Actions::Finding
  def self.included(base)
    base.send :extend, Redis::ORM::Finding::ClassMethods
  end

  module ClassMethods

    def find(id)
      record = connection.get("#{self.to_s.pluralize.downcase}:#{id}")
      if record
        model = self.new(serializer.load(record))
        model.set_unchanged!
        model
      else
        nil
      end
    end

    def all(record_ids=nil)
      instances = Array.new
      if record_ids.nil?
        record_ids = connection.hgetall("#{self.to_s.pluralize.downcase}:ids").collect{ |id| "#{self.to_s.pluralize.downcase}:#{id.first}" }
      else
        record_ids = record_ids.collect{ |id| "#{self.to_s.pluralize.downcase}:#{id}" }
      end
      if (records = connection.mget(record_ids))
        records.each do |record|
          model = self.new(serializer.load(record))
          model.set_unchanged!
          instances << model
        end
      end
      instances
    end

    def first
      all.first
    end

    def last
      all.last
    end

  end
end
