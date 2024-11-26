#!/usr/bin/env ruby
# This example is loosely based on a joke posted by MillionthMonkey on
# slashdot: http://ask.slashdot.org/comments.pl?sid=250311&cid=19862863
# Nonetheless, it demonstrates some features of the protocol library pretty
# nicely.

require 'protocol'
require 'singleton'

MessageStrategyProtocol = Protocol do
  def send_message() end
end

MessageBodyProtocol = Protocol do
  attr_reader :payload

  def configure(obj)
    precondition { obj.respond_to? :to_str }
  end

  def send(message_strategy)
    MessageStrategyProtocol =~ message_strategy
    precondition { payload.respond_to? :to_str }
    postcondition { result == :done }
  end
end

class MessageBody
  attr_reader :payload

  def configure(obj)
    @payload = obj
  end

  def send(message_strategy)
    message_strategy.send_message
    :done
  end

  conform_to MessageBodyProtocol
end

StrategyFactoryProtocol = Protocol do
  def create_strategy(message_body)
    MessageBodyProtocol =~ message_body
  end
end

class DefaultFactory
  include Singleton

  def create_strategy(message_body)
    Class.new do
      define_method(:send_message) do ||
        puts message_body.payload
      end

      conform_to MessageStrategyProtocol
    end.new
  end

  conform_to StrategyFactoryProtocol
end

class HelloWorld
  def self.main(*args)
    message_body = MessageBody.new
    message_body.configure "Hello World!"
    factory = DefaultFactory.instance
    strategy = factory.create_strategy message_body
    message_body.send strategy
  end
end

HelloWorld.main(*ARGV)
