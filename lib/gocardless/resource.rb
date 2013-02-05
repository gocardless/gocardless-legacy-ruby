require 'date'

module GoCardless
  class Resource
    def initialize(hash = {})
      # Define an object singleton method for each sub resource
      hash.delete('sub_resource_uris') { [] }.each do |name, uri|
        uri = URI.parse(uri)

        # Convert the query string to a params hash
        default_query = if uri.query.nil? || uri.query.empty?
          {}
        else
          Hash[CGI.parse(uri.query).map { |k,v| [k,v.first] }]
        end

        # Strip api prefix from path
        path = uri.path.sub(%r{^/api/v\d+}, '')

        # Modify the instance's metaclass to add the method
        metaclass = class << self; self; end
        metaclass.send(:define_method, name) do |*args|
          # 'name' will be something like 'bills', convert it to Bill and
          # look up the resource class with that name
          class_name = Utils.camelize(Utils.singularize(name.to_s))
          klass = GoCardless.const_get(class_name)
          query = default_query.merge(args.first || {})
          client.api_get(path, query).map do |attrs|
            # Convert the results to instances of the looked-up class
            klass.new_with_client(client, attrs)
          end
        end
      end

      # Set resource attribute values
      hash.each { |key,val| send("#{key}=", val) }
    end

    ##
    # parses a method call passed to method_missing
    class MethodCall
      attr_accessor :attribute
      def initialize(string)
        all, @attribute, @operation = *(/([^=!\?]+)([=!\?]?)/.match string.to_s)
      end

      def assignment?
        @operation == "="
      end

      def check?
        @operation == "?"
      end
    end

    # sets or gets an instance variable for this resource
    def method_missing(method, *args)
      op = MethodCall.new(method)
      if op.assignment?
        instance_variable_set("@#{op.attribute}", args.first)
      elsif op.check?
        check_attribute(op.attribute)
      else
        get_attribute(op.attribute)
      end
    end 

    def valid_attribute?(attr)
      instance_variables.map(&:to_s).include? "@#{attr}"
    end

    def get_attribute(attr)
      raise NoMethodError unless valid_attribute?(attr)
      instance_variable_get("@#{attr}")
    end

    def check_attribute(attr)
      !get_attribute(attr).nil?
    end

    attr_writer :client

    class << self
      attr_accessor :endpoint

      def new_with_client(client, attrs = {})
        self.new(attrs).tap { |obj| obj.client = client }
      end

      def find_with_client(client_obj, id)
        path = endpoint.gsub(':id', id.to_s)
        data = client_obj.api_get(path)
        obj = self.new(data)
        obj.client = client_obj
        obj
      end

      def find(id)
        message = "Merchant details not found, set GoCardless.account_details"
        raise Error, message unless GoCardless.client
        self.find_with_client(GoCardless.client, id)
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
            klass = GoCardless.const_get(Utils.camelize(name))
            klass.find_with_client(client, obj_id)
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
            klass = GoCardless.const_get(Utils.camelize(name))
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
      attrs = instance_variables.map { |v| v.to_s.sub(/^@/, '') }
      attrs.delete 'client'
      Hash[attrs.select { |v| respond_to? v }.map { |v| [v.to_sym, send(v)] }]
    end

    def to_json
      MultiJson.encode(Utils.stringify_times(to_hash))
    end

    def inspect
      "#<#{self.class} #{to_hash.map { |k,v| "#{k}=#{v.inspect}" }.join(', ')}>"
    end

    def persisted?
      !id.nil?
    end

    # Save a resource on the API server. If the resource already exists (has a
    # non-null id), it will be updated with a PUT, otherwise it will be created
    # with a POST.
    def save
      save_data self.to_hash
      self
    end

  protected

    def client
      @client || GoCardless.client
    end

    def save_data(data)
      method = if self.persisted?
        raise "#{self.class} cannot be updated" unless self.class.updatable?
        'put'
      else
        raise "#{self.class} cannot be created" unless self.class.creatable?
        'post'
      end
      path = self.class.endpoint.gsub(':id', id.to_s)
      response = client.send("api_#{method}", path, data)
      response.each { |key,val| send("#{key}=", val) if respond_to?("#{key}=") } if response.is_a? Hash
    end
  end
end
