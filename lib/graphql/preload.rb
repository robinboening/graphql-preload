require 'graphql'
require 'graphql/batch'
require 'promise.rb'

GraphQL::Field.accepts_definitions(
  preload: ->(type, *args) do
    type.metadata[:preload] ||= []
    type.metadata[:preload].concat(args)
  end,
  preload_scope: ->(type, arg) { type.metadata[:preload_scope] = arg }
)

GraphQL::Schema.accepts_definitions(
  enable_preloading: ->(schema) do
    schema.instrument(:field, GraphQL::Preload::Instrument.new)
  end
)

module GraphQL
  # Provides a GraphQL::Field definition to preload ActiveRecord::Associations
  module Preload
    autoload :Instrument, 'graphql/preload/instrument'
    autoload :Loader, 'graphql/preload/loader'
    autoload :VERSION, 'graphql/preload/version'

    module SchemaMethods
      def enable_preloading
        instrument(:field, GraphQL::Preload::Instrument.new)
      end
    end

    module FieldMetadata
      def initialize(*args, preload: nil, preload_scope: nil, **kwargs, &block)
        if preload
          @preload ||= []
          @preload.concat Array.wrap preload
        end
        if preload_scope
          @preload_scope = preload_scope
        end
        super(*args, **kwargs, &block)
      end

      def to_graphql
        field_defn = super
        field_defn.metadata[:preload] = @preload
        field_defn.metadata[:preload_scope] = @preload_scope
        field_defn
      end
    end
  end

  Schema.extend Preload::SchemaMethods
  Schema::Field.prepend Preload::FieldMetadata
end
