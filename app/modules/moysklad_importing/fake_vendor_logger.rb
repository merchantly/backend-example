module MoyskladImporting
  class FakeVendorLogger < VendorLogger
    include Singleton

    def update_data!(_data); end

    def create!(*_args); end

    def warn(*_args); end

    def error(*_args); end

    def into(*_args); end

    def debug(*_args); end

    def fatal_error(*_args); end

    def flush!; end

    def finish!; end
  end
end
