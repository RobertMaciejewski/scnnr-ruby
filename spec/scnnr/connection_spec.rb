# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Scnnr::Connection do
  before { stub_request(method, uri).to_return(body: expected_body, status: 200) }

  let(:connection) { described_class.new(uri, method, api_key, logger) }
  let(:uri) { URI.parse('https://dummy.scnnr.cubki.jp') }
  let(:logger) { Logger.new('/dev/null') }
  let(:api_key) { nil }
  let(:expected_body) { fixture('queued_recognition.json').read }

  describe '#send_request' do
    subject { connection.send_request(&block) }

    let(:method) { %i[get post].sample }
    let(:block) { nil }

    context 'when the api_key is not set' do
      it do
        is_expected.to be_a Net::HTTPSuccess
        expect(subject.body).to eq expected_body
        expect(WebMock).to have_requested(method, uri)
      end
    end

    context 'when the api_key is set' do
      let(:api_key) { 'dummy_key' }
      let(:requested_options) { { headers: { 'x-api-key' => api_key } } }

      it do
        is_expected.to be_a Net::HTTPSuccess
        expect(subject.body).to eq expected_body
        expect(WebMock).to have_requested(method, uri).with(requested_options)
      end
    end

    context 'when passing block' do
      let(:block) { ->(request) { request.content_type = requested_content_type } }
      let(:requested_content_type) { 'application/json' }
      let(:requested_options) do
        { headers: { 'Content-Type' => requested_content_type } }
      end

      it do
        is_expected.to be_a Net::HTTPSuccess
        expect(subject.body).to eq expected_body
        expect(WebMock).to have_requested(method, uri).with(requested_options)
      end
    end
  end

  describe '#send_stream' do
    subject { connection.send_stream(image) }

    let(:method) { :post }
    let(:api_key) { 'dummy_key' }
    let(:image) { fixture('images/sample.png') }
    let(:requested_content_type) { 'application/octet-stream' }
    let(:requested_options) do
      {
        headers: { 'x-api-key' => api_key, 'Content-Type' => requested_content_type, 'Transfer-Encoding' => 'chunked' },
      }
    end

    it do
      # can not test checking requested body_stream with WebMock, so instead.
      expect_any_instance_of(Net::HTTP::Post).to receive(:body_stream=).with(image)
      is_expected.to be_a Net::HTTPSuccess
      expect(subject.body).to eq expected_body
      expect(WebMock).to have_requested(method, uri).with(requested_options)
    end
  end

  describe '#send_json' do
    subject { connection.send_json(data) }

    let(:method) { :post }
    let(:api_key) { 'dummy_key' }
    let(:data) { { data: 'dummy_data' } }
    let(:requested_content_type) { 'application/json' }
    let(:requested_options) do
      {
        headers: { 'x-api-key' => api_key, 'Content-Type' => requested_content_type },
        body: data.to_json,
      }
    end

    it do
      is_expected.to be_a Net::HTTPSuccess
      expect(subject.body).to eq expected_body
      expect(WebMock).to have_requested(method, uri).with(requested_options)
    end
  end
end
