## update: test.rb

# できそう？
def matmul(a)
  b = [[0, 1], [2, 3]]
  result = Array.new(2) { Array.new(2, 0) }

  2.times do |i|
    2.times do |j|
      2.times do |k|
        result[i][j] += a[i][k] * b[k][j]
      end
    end
  end
  result
end

# 呼び出し元のコンテキストがなかったらどうする（symbolicな解析？）
def mymap1(array)
  result = Array.new(array.size)  
  array.each_with_index do |element, i|
    result[i] = yield(element)
  end
  result
end

# 難しそう
def mymap2(array)
  result = [] 
  array.each do |element|
    result << yield(element)  
  end
  result
end

