class Position
  attr_accessor :expent, :custody, :avg_price

  def initialize(expent: 0.0, custody: 0.0, avg_price: nil)
    @custody = custody
    if avg_price
      @expent = round(custody * avg_price)
      @avg_price = round(avg_price)

      return
    end

    @expent = round(expent)
    @avg_price = calculate_avg_price(@expent, @custody)
  end

  def calculate_avg_price(expent, custody)
    round(expent/custody)
  end

  def calculate_custody(cost, price)
    round(cost.to_f / price)
  end

  def buy(current_price, capital)
    custody = round(@custody + calculate_custody(capital, current_price))
    expent = round(@expent + capital)
    
    Position.new(expent: expent, custody: custody)
  end

  def buy!(current_price, capital)
    @custody = round(@custody + calculate_custody(capital, current_price))
    @expent = round(@expent + capital)
    @avg_price = calculate_avg_price(@expent, @custody)
  end

  def stop_loss(current_price)
    (current_price * @custody) - @expent
  end

  def calculate_recovery_bid_iterate(current_price, target_price: nil, increment: 10.0)
    target_price = current_price unless target_price
    avg_price = @avg_price
    bid_cost = 0.0
    bid_custody = 0.0

    puts "Avg Price: #{avg_price}, bid_cost: #{@expent}, custody: #{@custody}" 
    while (avg_price - target_price) > (target_price * 0.03) do
      bid_cost = bid_cost + increment
      bid_custody = calculate_custody(bid_cost, target_price)
      avg_price = calculate_avg_price(@expent + bid_cost, @custody + bid_custody)

      puts "Avg Price: #{avg_price}, Bid cost: #{bid_cost}, Bid custody: #{bid_custody}" if bid_cost / 50 > 1
    end
    {avg_price: avg_price, bid_cost: bid_cost, bid_custody: bid_custody}
  end

  def calculate_recovery_bid(current_price:, max_deviation: 0.05)
    target_price = current_price * (1 + max_deviation)
    bid_qty = (@avg_price * @custody - target_price * current_price) / (target_price - current_price)
    bid_price = bid_qty * current_price

    total_avg_price = calculate_avg_price(@expent + bid_price, @custody + bid_qty)

    { avg_price: total_avg_price, bid_cost: round(bid_price), bid_custody: round(bid_qty) }
  end
  private

  def round(value)
    return 0.0 if value.nan?

    value.round(8, half: :even)
  end
end
