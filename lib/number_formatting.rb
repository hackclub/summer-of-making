module NumberFormatting
  def self.pretty_round(number, precision: 1)
    # 14.12 #=> "14.1"
    # 14.02 #=> "14"
    rounded = number.round(precision)
    (rounded % 1).zero? ? rounded.to_i.to_s : rounded.to_s
  end
end
