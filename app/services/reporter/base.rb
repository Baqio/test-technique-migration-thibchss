module Reporter
  class Base
    def initialize(record, report, source, **datas)
      @record = record
      @report = report
      @source = source
      @datas = datas
    end
  
    private
  
    attr_reader :record, :report
  
    def locator
      raise NotImplementedError
    end
  
    def warning(message:, **details)
      report.warn(source: @source, locator: locator, message: message, **details)
    end
  
    def error(message:, **details)
      report.error(source: @source, locator: locator, message: message, **details)
    end
  end
end