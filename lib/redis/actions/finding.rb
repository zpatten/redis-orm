module Redis::Actions::Finding
  def self.included(base)
    base.send :extend, Redis::ORM::Finding::ClassMethods
  end

  module ClassMethods
    def find(id)
      data = connection.get("#{self.to_s.pluralize.downcase}:#{id}")
      if data
        instance = self.new(serializer.load(data))
        instance.set_unchanged!
        instance
      else
        nil
      end
    end

    def all
      instances = Array.new
      record_ids = connection.hgetall("#{self.to_s.pluralize.downcase}:ids").collect{ |id| "#{self.to_s.pluralize.downcase}:#{id.first}" }
      if (records = connection.mget(record_ids))
        records.each do |record|
          instances << self.new(serializer.load(record))
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
