require 'pp'
require 'set'

module ShortBus
  ##
  # Used for message_specs and publisher_specs
  class Spec
    attr_reader :specs

    def initialize(spec = nil)
      @specs = process(spec)
    end

    def <<(spec)
      @specs += process(spec)
    end

    def delete(spec)
      @specs.delete spec
    end

    def match(item)
      @specs.reduce(false) { |a, e| a || match_single(e, item) }
    end

    private

    def match_single(spec, item)
      if spec.is_a? String
        spec == item
      elsif spec.is_a? Regexp
        spec.match item
      end
    end

    def process(spec, to_set = true)
      if spec.is_a? Array
        process spec.flatten.to_set
      elsif spec.is_a? Regexp
        to_set ? [spec].to_set : spec
      elsif spec.is_a? Set
        spec.flatten
            .map { |spec| process(spec, false) }
            .to_set
      elsif spec.is_a? String
        to_set ? [string_to_regexp(spec)].to_set : string_to_regexp(spec)
      elsif spec.is_a? NilClass
        [/.*/].to_set
      end
    end

    def string_to_regexp(spec)
      if spec.include? '*'
        /^#{spec.gsub(/\*+/, '*' => '[^/]*', '**' => '.*')}/
      else
        spec
      end
    end
  end
end
