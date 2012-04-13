module Furnace::AVM2::Tokens
  class MetadataToken < Furnace::Code::TerminalToken
    def initialize(origin, options={})
      super(origin, options)
    end

    def to_text
      if @origin.metadata?
        elements = []

        @origin.metadata.each do |datum|
          values = datum.to_hash.map do |key, value|
            %Q[#{key || '*'}="#{value}"]
          end

          elements << "#{datum.name}(#{values.join(",")})"
        end

        "[#{elements.join(",")}]\n"
      else
        ""
      end
    end
  end
end