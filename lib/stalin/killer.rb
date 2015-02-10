module Stalin
  # Kill a process by sending SIGQUIT several times, then SIGTERM, and finally SIGKILL.
  class Killer
    # Number of cumulative tries to send SIGQUIT before we escalate to SIGTERM
    MAX_QUIT = 10
    # Number of cumulative tries before we escalate to SIGKILL
    MAX_TERM = 15

    # @param [Integer] pid target process ID
    def initialize(pid)
      @pid = pid
      @tries = 0
    end

    # Try to kill the target process by sending it a shutdown signal.
    #
    # @return [:QUIT,:TERM,:KILL] name of signal that we sent
    def kill
      case @tries
      when (0...MAX_QUIT)
        sig = :QUIT
      when (MAX_QUIT...MAX_TERM)
        sig = :TERM
      else
        sig = :KILL
      end

      @tries += 1
      Process.kill(sig, @pid)
      sig
    end
  end
end