# frozen_string_literal: true

module Rdawn
  module Tasks
    class DirectHandlerTask < Rdawn::Task
      attr_accessor :handler

      def initialize(task_id:, name:, handler:, input_data: {}, **options)
        super(task_id: task_id, name: name, input_data: input_data, **options)
        
        @handler = handler
        validate_handler!
      end

      def to_h
        super.merge(
          handler: handler_description,
          task_type: 'direct_handler'
        )
      end

      def handler_description
        case @handler
        when Proc
          if @handler.lambda?
            "Lambda with #{@handler.arity} parameters"
          else
            "Proc with #{@handler.arity} parameters"
          end
        else
          "Callable object (#{@handler.class})"
        end
      end

      private

      def validate_handler!
        unless handler_valid?
          raise ArgumentError, "Handler must be a Proc, lambda, or respond to :call"
        end
      end

      def handler_valid?
        @handler.is_a?(Proc) || @handler.respond_to?(:call)
      end


    end
  end
end 