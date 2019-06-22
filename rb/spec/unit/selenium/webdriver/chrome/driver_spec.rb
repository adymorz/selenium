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

require File.expand_path('../spec_helper', __dir__)

module Selenium
  module WebDriver
    module Chrome
      describe Driver do
        let(:resp)    { {'value' => {'sessionId' => 'foo', 'capabilities' => Remote::Capabilities.chrome.as_json}} }
        let(:service) { instance_double(Service) }
        let(:service_manager) { instance_double(ServiceManager, start: true, uri: 'http://example.com') }
        let(:caps)    { Remote::Capabilities.new }
        let(:http)    { instance_double(Remote::Http::Default, call: resp).as_null_object }

        before do
          allow(Remote::Capabilities).to receive(:chrome).and_return(caps)
          allow(Service).to receive_messages(binary_path: '/foo', new: service, executable_path: nil)
          allow(ServiceManager).to receive(:new).and_return(service_manager)
        end

        it 'sets the proxy capabilitiy' do
          proxy = Proxy.new(http: 'localhost:1234')
          Driver.new(http_client: http, proxy: proxy)

          expect(caps[:proxy]).to eq(proxy)
        end

        it 'does not set goog:chromeOptions by default' do
          Driver.new(http_client: http)

          expect(caps['goog:chromeOptions']).to be nil
        end

        it 'does not set the chrome.detach capability by default' do
          Driver.new(http_client: http)

          expect(caps['chrome.detach']).to be nil
        end

        it 'lets the user override chrome.detach' do
          Driver.new(http_client: http, detach: true)

          expect(caps['goog:chromeOptions']['detach']).to be true
        end

        it 'raises an ArgumentError if args is not an Array' do
          expect { Driver.new(args: '--foo=bar') }.to raise_error(ArgumentError)
        end

        it 'uses the given profile' do
          profile = Profile.new

          profile['some_pref'] = true

          Driver.new(http_client: http, profile: profile)

          profile_data = profile.as_json
          expect(caps['goog:chromeOptions']['args'].first).to include(profile_data['directory'])
        end

        context 'with custom desired capabilities' do
          subject(:build_new_driver) do
            Driver.new(http_client: http, desired_capabilities: custom_caps)
          end

          let(:custom_caps) { Remote::Capabilities.new(cap_opts) }
          let(:cap_opts) { {chrome_options: {'foo' => 'bar'}} }

          it 'takes desired capabilities' do
            expect(http).to receive(:call) do |_, _, payload|
              expect(payload[:capabilities][:firstMatch][0][:chrome_options]).to include('foo' => 'bar')
              resp
            end

            build_new_driver
          end

          context 'with empty driver options' do
            let(:cap_opts) { {'goog:chromeOptions' => {args: %w[foo bar]}} }

            it 'does not merge empty options' do
              expect(http).to receive(:call) do |_, _, payload|
                expect(payload[:capabilities][:firstMatch][0]['goog:chromeOptions'][:args]).to eq(%w[foo bar])
                resp
              end

              build_new_driver
            end
          end
        end
      end
    end # Chrome
  end # WebDriver
end # Selenium
