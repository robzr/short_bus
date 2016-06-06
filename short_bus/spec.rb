require 'pp'
require 'set'

module ShortBus
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
      @specs.reduce(false) { |acc, spec| acc || match_single(spec, item) }
    end

    private

    def match_single(spec, item)
      case spec.class.name
      when 'String'
        spec == item
      when 'Regexp'
        spec.match item
      end
    end

    def process(spec, to_set = true)
      case spec.class.name
      when 'Array'
        process spec.flatten.to_set
      when 'Regexp'
        to_set ? [spec].to_set : spec
      when 'Set'
        spec.flatten
          .map { |spec| process(spec, false) }
          .to_set
      when 'String'
        to_set ? [string_to_regexp(spec)].to_set : string_to_regexp(spec)
      when 'NilClass'
        [/.*/].to_set
      end
    end

    def string_to_regexp(spec)
      if spec.include? '*'
        /^#{spec.gsub(/\*+/, '*' => '[^:]*', '**' => '.*')}/
      else
        spec
      end
    end
  end
end


