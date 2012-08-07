class Redis::ORM
  module Attributes
    def self.included(base)
      base.class_eval do
        extend Redis::ORM::Attributes::ClassMethods
        class_attribute :model_attributes
        self.model_attributes ||= HashWithIndifferentAccess.new
      end
    end

    def attributes
      @attributes ||= model_attributes.clone
    end

    def set_unchanged!
      @previous_attributes = attributes.clone
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
      @previous_attributes || attributes.clone
    end

    def new_record?
      @previous_attributes.nil?
    end

    def changed?
      new_record? || attributes != @previous_attributes
    end

    def update_attribute(name, value)
      name = name.to_s
      raise ActiveRecordError, "#{name} is marked as readonly" if self.class.readonly_attributes.include?(name)
      send("#{name}=", value)
      save(:validate => false)
    end

    def update_attributes(attributes, options = {})
      attributes = attributes.is_a?(Array) ? attributes : [attributes]
      attributes.each do |attributes_group|
        attributes_group.each do |key, value|
          update_attribute(key, value)
        end
      end
    end

    module ClassMethods
      def attribute_names
        model_attributes.keys
      end

      def attribute(key, default_value = nil)
        model_attributes.merge!({key => default_value})

        define_method key do
          attributes[key]
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
