module DeepTest
  class ListenerList
    attr_reader :listeners

    def initialize(listeners)
      @listeners = listeners
    end

    NullListener.instance_methods(false).each do |event|
      class_eval <<-end_src, __FILE__, __LINE__
        def #{event}(*args)
          @listeners.each {|l| l.#{event}(*args)}
        end
      end_src
    end
  end
end
