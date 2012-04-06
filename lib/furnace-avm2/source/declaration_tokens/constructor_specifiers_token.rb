require_relative 'specifiers_token'

module Furnace::AVM2::Tokens
  class ConstructorSpecifiersToken < SpecifiersToken
    def specifiers
      list = []
      list << "static" if @options[:static]
      list << "public"
      list
    end
  end
end