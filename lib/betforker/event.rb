module Betforker
  class Event
    attr_reader :addresses, :forks
    attr_accessor :webpages, :parsed_webpages

    def initialize(addresses, sport = 'tennis')
      @sport = sport
      @addresses = addresses || []
      @webpages = {}
      @parsed_webpages = []
      @forks = []
    end

    def find_forks
      get_webpages
      parse_webpages all_bookmakers
      print_parsed_webpages if $config[:log]
      forking
      @forks.flatten!
      print_forks if $config[:log]
      @forks
    end

    def get_webpages
      @webpages = Betforker::Downloader.download_event_pages(addresses)
    end

    def parse_webpages(bookmakers)
      bookmakers.each do |bookie|
	b = eval bookie
	b.parse_event(self, @sport)
      end
    end

    def forking
      while @parsed_webpages.size > 1
	first = @parsed_webpages.shift
	@parsed_webpages.each do |second|
	  @forks << Betforker::Comparer.compare(first, second)
	end
      end
    end

    def all_bookmakers
      $config[:bookmakers]
    end

    def print_message_about_event(total_count, number)
      puts "\n\n#{'*' * 20} work with #{number}/#{total_count} #{'*' * 20}"
    end

    def print_parsed_webpages
      puts "\n#{'-' * 20} Parsed event"
      @parsed_webpages.each do |parsed|
	puts <<-EOF
#{parsed.bookie}, score: #{parsed.score}
HomePlayer: #{parsed.home_player}
AwayPlayer: #{parsed.away_player}

	EOF
      end
    end

    def print_forks
      if @forks.empty?
	puts "#{'-' * 20} No forks"
      else
	puts "#{'!' * 20}   Forks   #{'!' * 20}"
	@forks.each { |f| puts f.show }
	puts '!' * 51
      end
    end
  end
end
