require 'spec_helper'
require 'webmock/rspec'
require 'active_support/core_ext/hash/deep_merge.rb'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

require 'prepare_indices/close_index'

describe PrepareIndices::CloseIndex do
  let(:month) { Time.now.next_month.strftime('%Y%m') }
  let(:ok_response){ JSON.dump('acknowledged' => true) }
  let(:es_host) { { host: 'localhost:9200', log: true } }
  let(:args) do
    {
      connect: es_host,
      index: 'article_index',
      rotate: true,
      type: 'document',
      close_older_indices: true }
  end

  describe 'wrong params' do
    context 'raise error with wrong params' do
      subject(:response) { PrepareIndices::RotationIndex.perform(params: {}) }

      it 'should has raise exception' do
        expect { response }.to raise_error(ArgumentError, /missing es/i)
      end
    end
  end

  describe '#perform' do
    subject { described_class.perform(params: args) }

    context 'close_older_indices is false' do
      let(:args) { { close_older_indices: false, connect: es_host } }
      it { is_expected.to be(nil) }

      it 'not call elasticsearch' do
        subject
        expect(WebMock).not_to have_requested(:any, /#{es_host[:host]}/)
      end
    end

    context 'older index with newest alias' do
      before do
        stub_request(:get, %r{#{es_host[:host]}/article_index_}).to_return(
          status: 200,
          headers: { content_type: :json },
          body: JSON.dump('article_index' => { 'aliases' =>
            ["article_index_#{Time.now.strftime('%Y%m')}"]}))
      end

      it 'not to call elasticsearch' do
        subject
        expect(WebMock).not_to have_requested(:delete, /#{es_host[:host]}/)
      end
    end

    context 'one older and one newer index' do
      before do
        stub_request(:get, %r{#{es_host[:host]}/article_index_}).to_return(
          status: 200,
          headers: { content_type: :json },
          body: JSON.dump(
            { 'article_index_1' => { 'aliases' =>
                ["article_index_#{Time.now.months_ago(1).strftime('%Y%m')}"] },
              'article_index_2' => { 'aliases' =>
                ["article_index_#{Time.now.months_ago(2).strftime('%Y%m')}"] },
              'article_index_3' => { 'aliases' =>
                ["article_index_#{Time.now.months_ago(3).strftime('%Y%m')}"] }
            } ))
        stub_request(:post,  /_close/).to_return(body: ok_response)
      end

      it 'delete right index' do
        subject
        expect(WebMock).to have_requested(
          :post, %r{#{es_host[:host]}/article_index_3/_close})
      end

      it 'ignore ok indices' do
        subject
        expect(WebMock).not_to have_requested(
          :any, %r{#{es_host[:host]}/article_index_(?:1|2)\z})
      end

      it 'contains array of deleted indices' do
        expect(subject[:response]).to eq(['article_index_3'])
      end

      it 'has set status to true' do
        expect(subject[:status]).to be(true)
      end
    end
  end
end
