require_relative 'specifiers_token'

module Furnace::AVM2::Tokens
  class MethodSpecifiersToken < SpecifiersToken
    def specifiers
      list = []
      list << "final"    if @origin.final? && !@options[:static]
      list << "override" if @origin.override?
      list.concat super
      list
    end
  end
end