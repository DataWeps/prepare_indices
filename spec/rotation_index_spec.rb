require 'spec_helper'
require 'webmock/rspec'
require 'active_support/core_ext/hash/deep_merge.rb'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

require 'spec_helper'

describe PrepareIndices::RotationIndex do
  let(:month) { Time.now.next_month.strftime('%Y%m') }
  let(:ok_response){ JSON.dump("acknowledged" => true) }
  let(:es_host) { { host: 'localhost:9200', log: true } }
  let(:params) do
    {
      connect: es_host,
      index: 'article',
      rotate: true,
      every: :month,
      base_file: false,
      type: 'document',
      file: File.join(__dir__, 'example.json'),
      close: false,
      aliases: true }
  end

  context 'wrong params' do
    context 'raise error with wrong params' do
      subject(:response) { PrepareIndices::RotationIndex.perform(params: {}) }

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /missing es/i)
      end
    end
  end

  context 'default params' do
    subject(:response_params) do
      PrepareIndices::RotationIndex.send(
        :check_params!,
        params.deep_merge(every: nil))
    end

    it 'should has mention.every set as :month' do
      expect(response_params[:every]).to be(:month)
    end
  end

  context 'methods' do
    context 'rotate_index?' do
      context 'true' do
        subject do
          described_class.send(:rotate_index?, rotate: true)
        end

        it { is_expected.to be(true) }
      end

      context 'false' do
        subject do
          PrepareIndices::RotationIndex.send(:rotate_index?, rotate: false)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'rotate_index' do
      context 'errors' do
        context 'exists alias' do
          before do
            stub_request(:head,
              %r{#{Regexp.escape(es_host[:host])}/#{params[:index]}_#{month}}).to_return(
                status: 200,
                body: ok_response)
          end

          subject(:response) do
            described_class.perform(params: params)
          end

          it 'should return error hash' do
            expect(response[:status]).to be(false)
          end
        end

        context 'exists index' do
          before do
            stub_request(:head, /#{params[:index]}\z/).to_return(status: 200)
          end

          subject(:response) do
            described_class.perform(params: params)
          end

          it 'should returns error hash' do
            expect(response.to_s).to match(/exists/i)
          end
        end
      end

      describe 'ok' do
        context 'exists during creation' do
          before do
            tail = Time.now.strftime('%Y%m%d')
            stub_request(
              :head,
              /#{params[:index]}/).to_return(
                status: 404)
            stub_request(:head, /#{tail}/i).to_return(
              status: 404)
            stub_request(:put, /#{tail}/i)
              .to_return(
                status: 200,
                body: ok_response) \
              .to_return(
                status: 200,
                body: ok_response)
          end

          subject(:response) do
            PrepareIndices::RotationIndex.perform(params: params)
          end

          it 'should returns error hash' do
            expect(response[:status]).to be(true)
          end
        end
      end
    end
  end
end
