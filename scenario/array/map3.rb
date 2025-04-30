## update: test.rb

def double_numbers()
  numbers = [1, 2, 3]
  numbers.map do |n|
    n * 2
  end
  numbers
end

def nil_map()
  numbers = []
  numbers.map do |n|
    2
  end
  2
end