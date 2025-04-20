## update: test.rb

# できそう　aの型の推論は？
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
#: (Array[Integer, n:Integer]) -> Array[Integer] size=3|4
def mymap1(array) # Array[n] -> Array[n]
  result = Array.new(array.size)
  array.each_with_index do |element, i|
    result[i] = yield(element)
  end
  result
end
# array = [1,2,3]

def create_array(elem, n)
  result = [elem] * n
  result
end

# 難しい（pushがむずかしいだけ）
def mymap2(array)
  result = [] 
  array.each do |element|
    result << yield(element) 
  end
  result
end

# 次元レベルでの解析

