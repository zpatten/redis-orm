module Redis::Relations::HasMany
  def has_many_references
    @has_many_references ||= {}
  end

  def singularize(str)
    if str =~ /s$/
      str = str[0..-2]
    end
    str
  end

  def get_has_many_reference(relation_name)
    if has_many_references.key?(relation_name)
      has_many_references[relation_name]
    else
      items = connection.zrange(has_many_relation_id(relation_name), 0, -1, withscores: true).select{ |i| i.last.to_i == id.to_i }.collect{ |i| i.first.to_i }
      result = items.collect{ |item| eval("#{singularize(relation_name.to_s).capitalize}.find(item)") }
      has_many_references[relation_name] = result
    end
  end

  def save_has_many_references
    has_many_references.each do |relation_name, array|
      array.each do |aid|
        connection.zadd(has_many_relation_id(relation_name), id.to_i, aid.to_i)
      end
    end
  end

  def has_many_relation_id(name)
    "#{has_many_relations[name][:relation].to_s.pluralize}:references:#{self.class.to_s.downcase}"
  end

  def self.included(base)
    base.class_eval do
      add_relation :has_many

      class << self
        def has_many(relation_name, options = {})
          has_many_relations[relation_name] = options.reverse_merge({ :relation => relation_name })

          define_method relation_name do
            get_has_many_reference(relation_name)
          end

          define_method "#{relation_name}=" do |array|
            target = get_has_many_reference(relation_name)
            target.clear
            target.concat array
          end
        end
      end
    end
  end
end
