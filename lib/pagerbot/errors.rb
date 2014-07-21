module Pagerbot
  class QueryError < StandardError; end
  class NotFoundError < QueryError; end
  class UserNotFoundError < NotFoundError; end
  class ScheduleNotFoundError < NotFoundError; end
end