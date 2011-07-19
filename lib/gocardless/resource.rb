require 'date'

module GoCardless
  class Resource
    def initialize(client, hash = {})
      @client = client
      hash.each { |key,val| send("#{key}=", val) }
    end

    class << self
      attr_accessor :endpoint

      def find(client, id)
        path = endpoint.gsub(':id', id.to_s)
        data = client.api_get(path)
        self.new(client, data)
      end

      def date_writer(*args)
        args.each do |attr|
          define_method("#{attr.to_s}=".to_sym) do |date|
            date = date.is_a?(String) ? DateTime.parse(date) : date
            instance_variable_set("@#{attr}", date)
          end
        end
      end

      def date_accessor(*args)
        attr_reader *args
        date_writer *args
      end

      def reference_reader(*args)
        attr_reader *args

        args.each do |attr|
          if !attr.to_s.end_with?('_id')
            raise ArgumentError, 'reference_reader args must end with _id'
          end

          name = attr.to_s.sub(/_id$/, '')
          define_method(name.to_sym) do
            obj_id = instance_variable_get("@#{attr}")
            klass = GoCardless.const_get(name.camelize)
            klass.find(@client, obj_id)
          end
        end
      end

      def reference_writer(*args)
        attr_writer *args

        args.each do |attr|
          if !attr.to_s.end_with?('_id')
            raise ArgumentError, 'reference_writer args must end with _id'
          end

          name = attr.to_s.sub(/_id$/, '')
          define_method("#{name}=".to_sym) do |obj|
            klass = GoCardless.const_get(name.camelize)
            if !obj.is_a?(klass)
              raise ArgumentError, "Object must be an instance of #{klass}"
            end

            instance_variable_set("@#{attr}", obj.id)
          end
        end
      end

      def reference_accessor(*args)
        reference_reader *args
        reference_writer *args
      end

      def creatable(val = true)
        @creatable = val
      end

      def updatable(val = true)
        @updatable = val
      end

      def creatable?
        !!@creatable
      end

      def updatable?
        !!@updatable
      end
    end


    # @macro [attach] resource.property
    # @return [String] the $1 property of the object
    attr_accessor :id
    attr_accessor :uri

    def to_hash
      attrs = instance_variables.map { |v| v.sub(/^@/, '') }
      Hash[attrs.select { |v| respond_to? v }.map { |v| [v.to_sym, send(v)] }]
    end

    def to_json
      to_hash.to_json
    end

    def inspect
      "#<#{self.class} #{to_hash.map { |k,v| "#{k}=#{v.inspect}" }.join(', ')}>"
    end

    def persisted?
      !id.nil?
    end

    def save
      method = if self.persisted?
        raise "#{self.class} cannot be updated" unless self.class.updatable?
        'put'
      else
        raise "#{self.class} cannot be created" unless self.class.creatable?
        'post'
      end
      path = self.class.endpoint.gsub(':id', id.to_s)
      @client.send("api_#{method}", path, self.to_hash)
    end
  end
end
