require_relative 'specifiers_token'

module Furnace::AVM2::Tokens
  class MethodSpecifiersToken < SpecifiersToken
    def specifiers
      list, super_list = [], super
      list << "final"    if @origin.final? && !@options[:static]
      list << "override" if @origin.override? && !super_list.include?("private")
      list.concat super_list
      list << "native"   if @origin.body.nil? && @options[:environment] != :interface
      list
    end
  end
end