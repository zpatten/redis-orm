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
      connection.hgetall("#{self.to_s.pluralize.downcase}:ids").collect do |id|
        find(id.first)
      end
    end
  end
end
