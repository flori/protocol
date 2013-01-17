#!/usr/bin/env ruby

require 'protocol'

Assignable = Protocol do
  def assign_to(assignee)
    Assignee =~ assignee
  end
end

Assignee = Protocol do
end

Assignments = Protocol do
  implementation

  def assignments
    @assignable ||= []
  end

  def add(assignable)
    Assignable =~ assignable
    assignments << assignable
  end

  def assign(assignable, assignee)
    Assignable =~ assignable
    Assignee =~ assignee
    assignable.assign_to(assignee)
    add(assignable)
  end
end

class Task
  def assign_to(assignee)
    @assignee = assignee
  end

  conform_to Assignable
end

class Project
  conform_to Assignments
  conform_to Assignee
end

class User
  conform_to Assignments
  conform_to Assignee
end

Project.new.assign(Task.new, User.new)
