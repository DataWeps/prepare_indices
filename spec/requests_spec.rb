require 'spec_helper'
require 'prepare_indices/requests'
require 'webmock/rspec'

describe 'Requests' do
  context 'open_mappings' do
    let(:response) do
      file = File.join(__dir__, "test_file.json")
      PrepareIndices::Requests.load_mappings(file: file, index: 'muj')
    end

    it 'should has be hash' do
      expect(response.class).to be(Hash)
    end

    it 'should has be hash' do
      expect(response[:mappings]).not_to be(nil)
    end

    it 'should has be specific hash' do
      expect(response[:mappings]).to eq(JSON.parse(File.read(
        File.join(__dir__, "test_file.json")))["muj"]['mappings'])
    end
  end

  context 'create_index' do
    context 'right request' do
      before :context do
          stub_request(:put, %r{http://localhost:9200}).to_return(
          status: 200,
          body: JSON.dump("acknowledged" => true))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.create_index(
        es: es, index: 'pokus', settings: {}) }

      it 'return true if success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(false)
        expect(response[:index]).to match(/pokus/)
      end
    end

    context 'bad request' do
      before :context do
        stub_request(:put, %r{http://localhost:9200}).to_return(
          status: 400,
          body: JSON.dump('error' => {}))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.create_index(
        es: es, index: 'pokus', settings: {}) }

      it 'return hash if not succes' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(true)
      end
    end
  end

  context 'put_mappings' do
    context 'right request' do
      before :context do
        stub_request(:put, %r{http://localhost:9200}) .to_return(
          status: 200,
          body: JSON.dump("acknowledged" => true))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.put_mappings(
        es: es, mappings:
        { "document": {
            "properties": {
              "title": {
                "type": "multi_field",
                "fields": {
                    "title":  { "type": "string" },
                    "exact":  { "type": "string"}
                }
              }
            }
          }
        },
          index: 'pokus', type: 'document') }

      it 'return true if success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(false)
      end
    end

    context 'bad request' do
      before :context do
        stub_request(:put, %r{http://localhost:9200}) .to_return(
          status: 400,
          body: JSON.dump('error' => {}))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.put_mappings(
        es: es, mappings:
        { "document": {
            "properties": {
              "title": {
                "type": "multi_field",
                "fields": {
                    "title":  { "type": "string" },
                    "exact":  { "type": "string"}
                }
              }
            }
          }
        },
        index: 'pokus', type: 'document') }

      it 'return hash if not success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(true)
      end
    end
  end

  context 'delete_index' do
    context 'right request' do
      before :context do
        stub_request(:delete, %r{http://localhost:9200}) .to_return(
          status: 200,
          body: JSON.dump("acknowledged" => true))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.delete_index(
        es: es, index: 'pokus') }

      it 'return true if success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(false)
      end
    end

    context 'bad request' do
      before :context do
        stub_request(:delete, %r{http://localhost:9200}) .to_return(
          status: 404,
          body: JSON.dump('error' => {}))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.delete_index(
        es: es, index: 'pokus') }

      it 'return hash if not success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(true)
      end
    end
  end

  context 'put_setting' do
    context 'right request' do
      before :context do
        stub_request(:put, %r{http://localhost:9200}) .to_return(
          status: 200,
          body: JSON.dump("acknowledged" => true))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.put_settings(
        es: es, settings: {"settings" => 'test'}, index: 'pokus', type: 'document') }

      it 'return true if success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(false)
      end
    end

    context 'bad request' do
      before :context do
        stub_request(:put, %r{http://localhost:9200}) .to_return(
          status: 400,
          body: JSON.dump('error' => {}))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.put_settings(
        es: es, settings: {"settings" => 'test'}, index: 'pokus', type: 'document') }

      it 'return hash if not success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(true)
      end
    end
  end

  context 'put_aliases' do
    context 'right request' do
      before :context do
        stub_request(:put, %r{http://localhost:9200}) .to_return(
          status: 200,
          body: JSON.dump("acknowledged" => true))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.put_aliases(
        es: es, index: 'pokus', aliases: ['pokus1', 'pokus2', 'pokus3']) }

      it 'return true if success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(false)
      end
    end

    context 'bad request' do
        before :context do
        stub_request(:put, %r{http://localhost:9200}) .to_return(
          status: 404,
          body: JSON.dump('error' => {}))
      end

      let(:es) { ini_es('localhost:9200') }
      let(:response) { PrepareIndices::Requests.put_aliases(
        es: es, index: 'pokus', aliases: ['pokus1', 'pokus2']) }

      it 'return hash if not success' do
        expect(response.class).to be(Hash)
        expect(response[:errors]).to be(true)
      end
    end
  end



end