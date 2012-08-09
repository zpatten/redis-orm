class Redis::ORM
  module Attributes

    def self.included(base)
      base.class_eval do
        base.extend(Redis::ORM::Attributes::ClassMethods)
      end
    end

    def attributes
      @attributes ||= self.model_attributes.dup
    end

    def set_unchanged!
      @previous_attributes = self.attributes.dup
    end

    def attribute_names
      @attribute_names ||= attributes.keys
    end

    def attributes=(changed_attributes)
      changed_attributes.each do |key, value|
        send("#{key}=", value)
      end
    end

    def previous_attributes
      # note we do NOT assign here, this is because #changed?
      # and #new_record? rely on @previous_attributes to be nil
      @previous_attributes || self.attributes.dup
    end

    def new_record?
      @previous_attributes.nil?
    end

    def changed?
      new_record? || attributes != @previous_attributes
    end

    def update_attribute(name, value)
      send("#{name.to_s}=", value)
      save
    end

    def update_attributes(attribs, options = {})
      attribs = attribs.is_a?(Array) ? attribs : [attribs]
      attribs.each do |attributes_group|
        attributes_group.each do |key, value|
          update_attribute(key, value)
        end
      end
    end

    protected

      def read_attribute(name)
        @attributes[name]
      end

      def write_attribute(name, value)
        @attributes[name] = value
      end

    module ClassMethods
      def attribute_names
        model_attributes.keys
      end

      def attribute(key, default_value = nil)
        self.model_attributes.merge!(key => default_value)

        define_method key do
          attributes[key]
        end

        define_method "#{key}?" do
          %w( 1 y yes t true ).include?(attributes[key].downcase)
        end

        define_method "#{key}=" do |value|
          if value != attributes[key]
            attributes[key] = value
          else
            value
          end
        end

      end

    end

  end
end
