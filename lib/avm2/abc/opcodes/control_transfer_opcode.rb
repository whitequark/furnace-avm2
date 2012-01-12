module AVM2::ABC
  class ControlTransferOpcode < Opcode
    define_property :conditional

    attr_accessor :target

    def resolve!
      @target = @sequence.opcode_at(offset + byte_length + body.jump_offset)

      if !@target
        # Probably, we're in the middle of invalid code emitted by this fucking braindead
        # compiler. Do something equally insane.
        @target = self
      end
    end

    def lookup!
      #p self if @target.offset.nil? || offset.nil?
      body.jump_offset = @target.offset - offset - byte_length
    end
  end
end