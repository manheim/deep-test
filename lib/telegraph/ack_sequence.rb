module Telegraph
  class AckSequence
    MUTEX_FOR_ACK = Mutex.new

    def initialize
      @value = 0
    end

    def next
      MUTEX_FOR_ACK.synchronize do
        @value += 1
      end
    end
  end
end

