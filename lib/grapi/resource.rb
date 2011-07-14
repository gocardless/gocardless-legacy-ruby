require 'date'

module Grapi
  class Resource
    def initialize(client)
      @client = client
    end

    class << self
      def from_hash(client, hash)
        obj = self.new(client)
        hash.each { |key,val| obj.send("#{key}=", val) }
        obj
      end

      def find(client, id)
        path = self::ENDPOINT.gsub(':id', id.to_s)
        data = client.api_get(path)
        self.from_hash(client, data)
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
            klass = Grapi.const_get(name.camelize)
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
            klass = Grapi.const_get(name.camelize)
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
    end

    attr_accessor :id, :uri
  end
end
