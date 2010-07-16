#!/usr/bin/ruby -Ku

module LanguageDetector
  def self.normalize(x)
    if x[0] <= 65
      " "
    elsif x =~ /^[\xd0-\xd1][\x80-\xbf]/      # Cyrillic
      "\xd0\x96"
    elsif x =~ /^[\xd8-\xd9][\x80-\xbf]/      # Arabic
      "\xd8\xa6"
    elsif x =~ /^\xe0[\xa4-\xa5][\x80-\xbf]/  # Devanagari
      "\xe0\xa4\x85"
    elsif x =~ /^\xe0[\xb8-\xb9][\x80-\xbf]/  # Thai
      "\xe0\xb9\x91"
    elsif x =~ /^\xe1[\xba-\xbb][\x80-\xbf]/  # Latin Extended Additional(Vietnam)
      "\xe1\xba\xa1"
    elsif x =~ /^\xe3[\x81-\x83][\x80-\xbf]/  # Hiragana / Katakana
      "\xe3\x81\x82"
    elsif x =~ /^\xea[\xb0-\xbf][\x80-\xbf]/  # Hangul Syllables 1
      "\xea\xb0\x80"
    elsif x =~ /^[\xeb-\xed][\x80-\xbf]{2}/   # Hangul Syllables 2
      "\xed\x9e\x98"
    else
      x
    end
  end

  class Ngramer
    def initialize(n)
      @n = n
      clear
    end
    def clear
      @grams = [" "]
    end
    def append(x)
      clear if @grams[-1] == " "
      @grams << x
      @grams = @grams[-@n..-1] if @grams.length > @n
    end
    def get(n)
      return nil if @grams.length < n
      @grams[-n..-1].join
    end
    def each
      (1..@n).each do |n|
        x = get(n)
        yield x if x
      end
    end
  end

  class Detector
    def initialize(filename, alpha=1.0, beta=1.0)
      @n_k, @p_ik, @n = open(filename){|f| Marshal.load(f) }
      @n ||= 3
      @p_ik.default = 0
      @alpha = alpha
      @beta = beta
      @debug = false
    end
    def debug_on; @debug = true; end
    def ngramer; Ngramer.new(@n); end
    def init
      @prob = Hash.new
      LD::LANGLIST.each {|lang| @prob[lang] = 1.0 }
      @maxprob = 0
    end
    def append(x)
      return unless @p_ik.key?(x)
      freq = @p_ik[x]
      puts "#{x}: #{freq.inspect}" if @debug
      sum = 0
      LD::LANGLIST.each do |lang|
        @prob[lang] *= (freq[lang] + @alpha) / (@n_k[lang] + @beta)
        sum += @prob[lang]
      end
      @maxprob = 0
      LD::LANGLIST.each do |lang|
        @prob[lang] /= sum
        @maxprob = @prob[lang] if @maxprob < @prob[lang]
      end
      p problist(0.1) if @debug
    end
    def maxprob; @maxprob; end
    def problist(t=0.1); @prob.to_a.select{|x| x[1]>t}.sort_by{|x| -x[1]}; end
  end
end