require 'spec_helper'

describe Ridley::Chef::Chefignore do
  describe '.initialize' do
    let(:path) { tmp_path.join('chefignore-test') }
    before { FileUtils.mkdir_p(path) }

    it 'finds the nearest chefignore' do
      target = path.join('chefignore').to_s
      FileUtils.touch(target)
      expect(described_class.new(path).filepath).to eq(target)
    end

    it 'finds a chefignore in the `cookbooks` directory' do
      target = path.join('cookbooks', 'chefignore').to_s
      FileUtils.mkdir_p(path.join('cookbooks'))
      FileUtils.touch(target)
      expect(described_class.new(path).filepath).to eq(target)
    end

    it 'finds a chefignore in the `.chef` directory' do
      target = path.join('.chef', 'chefignore').to_s
      FileUtils.mkdir_p(path.join('.chef'))
      FileUtils.touch(target)
      expect(described_class.new(path).filepath).to eq(target)
    end
  end
end
