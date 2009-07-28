require 'protocol'

Locking = Protocol do
  specification # not necessary, because Protocol defaults to specification
                # mode already

  def lock() end
  
  def unlock() end

  implementation

  def synchronize
    lock
    begin
      yield
    ensure
      unlock
    end
  end
end

if $0 == __FILE__
  require 'thread'
  require 'tempfile'

  class FileMutex
    def initialize
      @tempfile = Tempfile.new 'file-mutex'
    end

    def path
      @tempfile.path
    end

    def lock
      puts "Locking '#{path}'."
      @tempfile.flock File::LOCK_EX
    end

    def unlock
      puts "Unlocking '#{path}'."
      @tempfile.flock File::LOCK_UN
    end

    conform_to Locking
  end

  FileMutex.conform_to? Locking     # => true
  FileMutex.new.conform_to? Locking # => true

  # Outputs something like:
  #  Locking '...'.
  #  Synchronized with '...'..
  #  Unlocking '...'.
  mutex = FileMutex.new
  mutex.synchronize do
    puts "Synchronized with '#{mutex.path}'."
  end

  class MemoryMutex
    def initialize
      @mutex = Mutex.new
    end

    def lock
      @mutex.lock
    end

    def unlock
      @mutex.unlock
    end

    conform_to Locking # actually Mutex itself would conform as well ;)
  end

  mutex = MemoryMutex.new
  mutex.synchronize do
    puts "Synchronized in memory."
  end

  MemoryMutex.conform_to? Locking     # => true
  MemoryMutex.new.conform_to? Locking # => true

  class MyClass
    def initialize
      @mutex = FileMutex.new
    end

    attr_reader :mutex

    def mutex=(mutex)
      Locking.check mutex
      @mutex = mutex
    end
  end

  obj = MyClass.new
  obj.mutex # => #<FileMutex:0xb788f9ac @tempfile=#<File:/tmp/file-mutex.26553.2>>
  begin
    obj.mutex = Object.new
  rescue Protocol::CheckFailed => e
    e # => #<Protocol::CheckFailed: #<Protocol::NotImplementedErrorCheckError: Locking#lock(0): method 'lock' not responding in #<Object:0xb788f59c>>|#<Protocol::NotImplementedErrorCheckError: Locking#unlock(0): method 'unlock' not responding in #<Object:0xb788f59c>>
  end
  obj.mutex = MemoryMutex.new # => #<MemoryMutex:0xb788f038 @mutex=#<Mutex:0xb788eea8>>
  # This works as well:
  obj.mutex = Mutex.new       # => #<Mutex:0xb788ecc8>
  Locking.check Mutex         # => true
  Mutex.conform_to? Locking   # => true
end
# >> "Locking '/tmp/file-mutex.26553.1'.\nSynchronized with '/tmp/file-mutex.26553.1'.\nUnlocking '/tmp/file-mutex.26553.1'.\nSynchronized in memory.\n"
