module Readthis
  # The `Scripts` class is used to conveniently execute lua scripts. The first
  # time a command is run it is stored on the server and subsequently referred
  # to by its SHA. Each instance tracks SHAs separately, they are not global.
  class Scripts
    attr_reader :loaded

    # Creates a new Readthis::Scripts instance.
    def initialize
      @loaded = {}
    end

    # Run a named lua script with the provided keys and arguments.
    #
    # @param [String] The script to run, without a `.lua` extension
    # @param [#Store] A Redis client for storing and evaluating the script
    # @param [Array] One or more keys to pass to the command
    # @param [Array] One or more args to pass to the command
    #
    # @return [Any] The Redis converted value returned on the script
    #
    # @example
    #
    #   scripts.run('mexpire', store, %w[a b c], 1) # => 'OK'
    #
    def run(command, store, keys, args = [])
      store.evalsha(
        sha(command, store),
        Array(keys),
        Array(args)
      )
    end

    private

    def sha(command, store)
      loaded[command] ||= load_script!(command, store)
    end

    def load_script!(command, store)
      path = File.join('script', "#{command}.lua")

      File.open(path) do |file|
        loaded[command] = store.script(:load, file.read)
      end
    rescue Errno::ENOENT
      raise Readthis::UnknownCommandError, "unknown command '#{command}'"
    end
  end
end
