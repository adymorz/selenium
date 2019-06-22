# frozen_string_literal: true

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module Selenium
  module WebDriver
    #
    # Base class implementing default behavior of service object,
    # responsible for storing a service manager configuration.
    #

    class Service
      class << self
        attr_reader :driver_path

        def chrome(**opts)
          Chrome::Service.new(**opts)
        end

        def firefox(**opts)
          binary_path = Firefox::Binary.path
          args = opts.delete(:args)
          case args
          when Hash
            args[:binary] ||= binary_path
            opts[:args] = args
          when Array
            opts[:args] = ["--binary=#{binary_path}"]
            opts[:args] += args
          else
            opts[:args] = ["--binary=#{binary_path}"]
          end

          Firefox::Service.new(**opts)
        end

        def ie(**opts)
          IE::Service.new(**opts)
        end
        alias_method :internet_explorer, :ie

        def edge(**opts)
          Edge::Service.new(**opts)
        end

        def edge_chrome(**opts)
          EdgeChrome::Service.new(**opts)
        end

        def edge_html(**opts)
          EdgeHtml::Service.new(**opts)
        end

        def safari(**opts)
          Safari::Service.new(**opts)
        end

        def driver_path=(path)
          Platform.assert_executable path if path.is_a?(String)
          @driver_path = path
        end
      end

      attr_accessor :host
      attr_reader :executable_path, :port, :extra_args

      #
      # End users should use a class method for the desired driver, rather than using this directly.
      #
      # @api private
      #

      def initialize(path: nil, port: nil, args: nil)
        path ||= self.class.driver_path
        port ||= self.class::DEFAULT_PORT
        args ||= []

        @executable_path = binary_path(path)
        @host = Platform.localhost
        @port = Integer(port)

        @extra_args = args.is_a?(Hash) ? extract_service_args(args) : args

        raise Error::WebDriverError, "invalid port: #{@port}" if @port < 1
      end

      protected

      def extract_service_args(driver_opts)
        driver_opts.key?(:args) ? driver_opts.delete(:args) : []
      end

      private

      def binary_path(path = nil)
        path = path.call if path.is_a?(Proc)
        path ||= Platform.find_binary(self.class::EXECUTABLE)

        raise Error::WebDriverError, self.class::MISSING_TEXT unless path

        Platform.assert_executable path
        path
      end
    end # Service
  end # WebDriver
end # Selenium
