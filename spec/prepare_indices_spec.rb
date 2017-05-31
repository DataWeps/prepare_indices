require 'spec_helper'
require 'webmock/rspec'

describe 'PrepareIndices' do
  context 'check_params' do
    context 'not error with all params' do
      let(:response) { PrepareIndices::CreateIndices.send(:check_params!, all_params) }

      it 'should not raise exception' do
        expect(response).to eq(all_params)
      end
    end

    context 'not error with some params' do
      let(:response) { PrepareIndices::CreateIndices.send(:check_params!, params_miss_del) }

      it 'should not raise exception' do
        params = params_miss_del
        params[:delete] = false
        expect(response).to eq(params)
      end
    end

    context 'raise error' do
      let(:response) { PrepareIndices::CreateIndices.send(:check_params!, error_params) }

      it 'should has raise exception' do
        expect { response }.to raise_error(/Missing params key/)
      end
    end
  end

  context 'perform' do
    context 'raise error with wrong params' do
      let(:response) { PrepareIndices::CreateIndices.perform({}) }

      it 'should has raise exception' do
        expect { response }.to raise_error(/Missing params key/)
      end
    end
  end
end
