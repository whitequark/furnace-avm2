require_relative 'specifiers_token'

module Furnace::AVM2::Tokens
  class ClassSpecifiersToken < SpecifiersToken
    def specifiers
      list = super
      list << "final"   if @origin.final?
      list << "dynamic" unless @origin.sealed?
      list
    end
  end
end