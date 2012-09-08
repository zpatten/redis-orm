require 'yajl'

class Redis::ORM
  class Serializer

    class << self
      def load(json)
        Yajl::Parser.parse(json, :symbolize_keys => true)
      end

      def dump(data)
        Yajl::Encoder.encode(data)
      end
    end

  end
end
