module Furnace::AVM2::Tokens
  class SupplementaryCommentToken < Furnace::Code::SurroundedToken
    def initialize(origin, content, children, options={})
      super(origin, children, options)
      @content = content
    end

    def text_before
      if @options[:commented]
        "* #{@content} * "
      else
        "/* #{@content} */ "
      end
    end
  end
end