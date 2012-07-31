module Redis::Actions::Creating
  def self.included(base)
    base.send :extend, Redis::Actions::Creating::ClassMethods
    base.define_model_callbacks :create
    base.around_save :create_if_new
  end

  def create_if_new
    if new_record?
      run_callbacks(:create) do
        yield
      end
    else
      yield
    end
  end

  module ClassMethods

    def create(attributes = {}, options = {}, &block)
      create_record(attributes, options, &block)
    end

    def create!(attributes = {}, options = {}, &block)
      create_record(attributes, options, true, &block)
    end

  private

    def create_record(attributes, options, raise = false, &block)
      if attributes.is_a?(Array)
        attributes.collect{ |attr| create_record(attr, options, raise, &block) }
      else
        record = new(attributes)
        yield(record) if block_given?
        saved = record.save
        raise RecordInvalid.new(record) if !saved && raise_error
        record
      end
    end

  end
end
