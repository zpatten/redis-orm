module Redis::Relations::BelongsTo
  def belongs_to_references
    @belongs_to_references ||= {}
  end

  def set_belongs_to_reference(name, a)
    belongs_to_references[name] = a
    @attributes.merge!("#{name}_id" => a.id)
  end

  def get_belongs_to_reference(name)
    if belongs_to_references.key?(name)
      belongs_to_references[name]
    else
      item = connection.zscore(belongs_to_relation_key(name), id.to_i).to_i
      result = name.to_s.classify.constantize.find(item)
      belongs_to_references[name] = result
    end
  end

  def belongs_to_relation_key(name)
    "#{self.class.to_s.pluralize.downcase}:references:#{belongs_to_relations[name][:relation].to_s}"
  end

  def save_belongs_to_references
    belongs_to_references.each do |relation_name, reference|
      reference and (reference = reference.id)
      connection.zadd(belongs_to_relation_key(relation_name), reference.to_i, id.to_i)
    end
  end

  def self.included(base)
    base.class_eval do
      add_relation :belongs_to

      class << self
        def belongs_to(relation_name, options = {})
          belongs_to_relations[relation_name] = options.reverse_merge({ :relation => relation_name })

          define_method relation_name do
            get_belongs_to_reference(relation_name)
          end

          define_method "#{relation_name}=" do |a|
            set_belongs_to_reference(relation_name, a)
          end

          self.model_attributes.merge!("#{relation_name}_id" => nil)
          define_method "#{relation_name}_id" do
            attributes["#{relation_name}_id"]
          end

          define_method "#{relation_name}_id=" do |value|
            if value != attributes["#{relation_name}_id"]
              attributes["#{relation_name}_id"] = value
            else
              value
            end
          end

        end
      end
    end
  end
end
