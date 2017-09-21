require 'spec_helper'

describe CounterEngine do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  shared_examples 'stats shouldnt have visits' do |period|
    let(:stats) { get_stats(page, period) }
    it "should have zero visits (#{period})" do
      expect(stats[:unique]).to eq(0)
      expect(stats[:total]).to eq(0)
    end
  end

  shared_examples 'should change after requests' do
    context 'after first request' do
      it 'should increment total visits' do
        expect{ get(url) }.to change{ get_stats(page, 'all')[:total] }.by(1)
      end

      it 'should increment unique visits' do
        expect{ get(url) }.to change{ get_stats(page, 'all')[:unique] }.by(1)
      end
    end

    context 'after 50 requests' do
      it 'should increment total visits' do
        expect{ 50.times { get(url) } }.to change{ get_stats(page, 'all')[:total] }.by(50)
      end

      it 'should increment unique visits only once' do
        expect{ 50.times { get(url) } }.to change{ get_stats(page, 'all')[:unique] }.by(1)
      end
    end
  end

  shared_examples 'should work with different time periods' do
    context 'different periods' do
      context 'travel to 2000-05-07' do
        before { travel_to Time.new(2000, 05, 07) }
        context 'without requests' do
          %w(all 2000 2000-01 2000-05 2000-05-01 2000-05-07 3000 3000-02 3000-09 3000-09-01 3000-09-12).each do |period|
            include_examples 'stats shouldnt have visits', period
          end
        end

        context 'with requests' do
          %w(all 2000 2000-05 2000-05-07).each do |period|
            it "should increment total visits for #{period}" do
              expect{ get(url) }.to change{ get_stats(page, period)[:total] }.by(1)
            end

            it "should increment unique visits for #{period}" do
              expect{ get(url) }.to change{ get_stats(page, period)[:unique] }.by(1)
            end
          end

          %w(2000-01 2000-05-01 3000 3000-02 3000-09 3000-09-01 3000-09-12).each do |period|
            it "should not change total visits for #{period}" do
              expect{ get(url) }.to_not change{ get_stats(page, period)[:total] }
            end

            it "should not change unique visits for #{period}" do
              expect{ get(url) }.to_not change{ get_stats(page, period)[:unique] }
            end
          end
        end
      end

      context 'travel to 3000-09-12' do
        before { travel_to Time.new(3000, 9, 12) }
        context 'without requests' do
          %w(all 2000 2000-01 2000-05 2000-05-01 2000-05-07 3000 3000-02 3000-09 3000-09-01 3000-09-12).each do |period|
            include_examples 'stats shouldnt have visits', period
          end
        end

        context 'with requests' do
          %w(all 3000 3000-09 3000-09-12).each do |period|
            it "should increment total visits for #{period}" do
              expect{ get(url) }.to change{ get_stats(page, period)[:total] }.by(1)
            end

            it "should increment unique visits for #{period}" do
              expect{ get(url) }.to change{ get_stats(page, period)[:unique] }.by(1)
            end
          end

          %w(2000-01 2000-05-01 3000-02 3000-09-01).each do |period|
            it "should not change total visits for #{period}" do
              expect{ get(url) }.to_not change{ get_stats(page, period)[:total] }
            end

            it "should not change unique visits for #{period}" do
              expect{ get(url) }.to_not change{ get_stats(page, period)[:unique] }
            end
          end
        end
      end
    end
  end

  describe 'counter engine' do
    let(:app) do
      Rack::Builder.new do
        use CounterEngine, stats_path: '/stats.json', redis_db: 'counter_engine_test'
        run SimpleApp.new
      end
    end

    let(:url) { '/some_url' }
    let(:another_url) { '/another_url' }
    let(:yet_another_url) { '/yet_another_url' }

    context 'site stats' do
      let(:page) { nil }

      include_examples 'should work with different time periods'

      context 'without requests' do
        include_examples 'stats shouldnt have visits', 'all'
      end

      include_examples 'should change after requests'

      context 'different urls' do
        it 'should increment total visits' do
          expect{ get(url) }.to change{ get_stats(page, 'all')[:total] }.by(1)
          expect{ get(another_url) }.to change{ get_stats(page, 'all')[:total] }.by(1)
          expect{ get(yet_another_url) }.to change{ get_stats(page, 'all')[:total] }.by(1)
        end

        it 'should increment unique visits only once' do
          expect{ get(url) }.to change{ get_stats(page, 'all')[:unique] }.by(1)
          expect{ get(another_url) }.not_to change{ get_stats(page, 'all')[:unique] }
          expect{ get(yet_another_url) }.not_to change{ get_stats(page, 'all')[:unique] }
        end
      end
    end

    context 'page stats' do
      let(:page) { url }

      include_examples 'should work with different time periods'

      context 'without requests' do
        include_examples 'stats shouldnt have visits', 'all'
      end

      include_examples 'should change after requests'

      context 'different urls' do
        context 'visit from main url' do
          it 'should increment total visits' do
            expect{ get(url) }.to change{ get_stats(page, 'all')[:total] }.by(1)
          end
          it 'should increment unique visits' do
            expect{ get(url) }.to change{ get_stats(page, 'all')[:unique] }.by(1)
          end
        end

        context 'visit from another urls' do
          it 'should not change total visits' do
            expect{ get(another_url) }.not_to change{ get_stats(page, 'all')[:unique] }
            expect{ get(yet_another_url) }.not_to change{ get_stats(page, 'all')[:unique] }
          end

          it 'should not change unique visits' do
            expect{ get(another_url) }.not_to change{ get_stats(page, 'all')[:unique] }
            expect{ get(yet_another_url) }.not_to change{ get_stats(page, 'all')[:unique] }
          end
        end
      end
    end
  end

  def get_stats(page, period)
    url = "/stats.json?page=#{page}&period=#{period}"
    body = get(url).body
    JSON.parse(body, symbolize_names: true)
  end
end