require 'spec_helper'
require 'webmock/rspec'
require 'active_support/core_ext/hash/deep_merge.rb'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

require 'spec_helper'

describe 'RotationIndex' do
  def es_host
    'localhost:9200'
  end

  def month
    Time.now.next_month.strftime('%m')
  end

  def ok_response
    JSON.dump("acknowledged" => true)
  end

  before :context do
    @params = {
      mention: {
        rotate: true,
        every: :month,
        base_index: 'base',
        type: 'document',
        file: File.join(__dir__, 'example.json'),
        close: false,
        aliases: true },
      node: {} }
    @es = ini_es(es_host)
  end

  context 'wrong params' do
    context 'raise error with wrong params' do
      let(:response) { PrepareIndices::RotationIndex.perform(es: nil, params: {}) }

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /missing es/i)
      end
    end

    context 'raise error with missing file' do
      let(:response) do
        PrepareIndices::RotationIndex.perform(
          es: @es, params: @params[:mention].deep_merge(file: nil))
      end

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /missing file/i)
      end
    end

    context 'raise error with non exist file' do
      let(:response) do
        PrepareIndices::RotationIndex.perform(
          es: @es, params: @params[:mention].deep_merge(file: 'bullshit.json'))
      end

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /unexists file/i)
      end
    end

    context 'raise error with missing type' do
      let(:response) do
        PrepareIndices::RotationIndex.perform(
          es: @es, params: @params[:mention].deep_merge(type: nil))
      end

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /missing type/i)
      end
    end

    context 'raise error with missing base index' do
      let(:response) do
        PrepareIndices::RotationIndex.perform(
          es: @es, params: @params[:mention].deep_merge(base_index: nil))
      end

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /missing base index/i)
      end
    end
  end

  context 'default params' do
    let(:response_params) do
      PrepareIndices::RotationIndex.send(
        :check_params!,
        @params[:mention].deep_merge(every: nil))
    end

    it 'should has mention.every set as :month' do
      expect(response_params[:every]).to be(:month)
    end
  end

  context 'methods' do
    context 'rotate_index?' do
      context 'true' do
        let(:response) do
          PrepareIndices::RotationIndex.send(:rotate_index?, rotate: true)
        end

        it 'should be true' do
          expect(response).to be(true)
        end
      end

      context 'false' do
        let(:response) do
          PrepareIndices::RotationIndex.send(:rotate_index?, rotate: false)
        end

        it 'should be false' do
          expect(response).to be(false)
        end
      end
    end

    context 'rotate_index' do
      context 'errors' do
        context 'exists alias' do
          before :context do
            stub_request(:head,
              %r{#{Regexp.escape(es_host)}/base_#{month}}).to_return(
                status: 200,
                body: ok_response)
          end

          let(:response) do
            PrepareIndices::RotationIndex.perform(es: @es, params: @params[:mention])
          end

          it 'should return error hash' do
            expect(response[:status]).to be(false)
          end
        end

        context 'exists index' do
          before :context do
            tail = Time.now.strftime("%Y%m%d%H%M%S")
            stub_request(:head,
              /base_#{month}/).to_return(
                status: 404)
            stub_request(:head, /#{tail}/i).to_return(
                status: 200,
                body: JSON.dump("acknowledged" => true))
          end

          let(:response) do
            PrepareIndices::RotationIndex.perform(es: @es, params: @params[:mention])
          end

          it 'should returns error hash' do
            expect(response[:error]).to match(/exists index/i)
          end
        end

        context 'exists during creation' do
          before :context do
            tail = Time.now.strftime("%Y%m%d%H%M%S")
            stub_request(:head,
              /base_#{month}/).to_return(
                status: 404)
            stub_request(:head, /#{tail}/i).to_return(
              status: 404)
            stub_request(:put, /#{tail}/i).to_return(
              status: 400,
              body: JSON.dump(
                "error" => "IndexAlreadyExistsException[ already exists]",
                "status" => 400))
          end

          let(:response) do
            PrepareIndices::RotationIndex.perform(es: @es, params: @params[:mention])
          end

          it 'should returns error hash' do
            expect(response[:error]).to match(/already/i)
          end
        end
      end

      context 'ok' do
        context 'exists during creation' do
          before :context do
            tail = Time.now.strftime("%Y%m%d%H%M%S")
            stub_request(:head,
              /base_#{month}/).to_return(
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

          let(:response) do
            PrepareIndices::RotationIndex.perform(es: @es, params: @params[:mention])
          end

          it 'should returns error hash' do
            p response
            expect(response[:status]).to be(true)
          end
        end
      end
    end
  end
end
