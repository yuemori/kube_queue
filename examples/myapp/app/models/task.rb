class Task < ApplicationRecord
  enum state: { todo: 0, doing: 1, done: 2 }
end
