require_relative 'specifiers_token'

module Furnace::AVM2::Tokens
  class FunctionSpecifiersToken < SpecifiersToken
    def specifiers
      list = super
      list << "final"     if @origin.final? && !@options[:static]
      list << "override"  if @origin.override?
      list
    end
  end
end