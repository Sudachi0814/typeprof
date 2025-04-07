lst = [1, 2, 3, 'Hello']
new_lst = lst.map { |x| x }
# new_lst = lst.map { |x| x.is_a?(Numeric) ? x * 2 : x }
p new_lst
y = 10 * 2 #*はメソッド　ビルドインでできる
lst = Array.new(y) # Array Any Size(x)
lst1 = Array.new(10) # Array Any Size(n*10)
lst1.zip(lst) # zip: 

drinks = ['コーヒー']
a = drinks.push('カフェラテ')

p drinks

array = [[1,1,1],[2,2,2]]

a = lst.push(5)

b = [1, 2, 3]
b[1] = 'hello'
p b

ary = [0, 1, 2, 3, 4]
ary[5]
ary1 = ary[1,3]

c = [0,1]
d = 0 + 1
c[d] = "hello"

e = c.to_a

f = [0, 1, 2]
result = f.each do |element|
    element = 'aa'  # 各要素に 1 を足す
end
p result
  
result1 = f.map { |element| element = 'a' }
p f
p result1

# これは推論できない（resultは動的に決まる）
# eachより下の解像度での推論しか不可能（mapのような返ってくる配列サイズが決まっている例）
def mymap(reciever)
    result = []
    reciever.each { |item| result << yield(item) }
    result
end
m = mymap(f) {|element| element = 'a'}
p m # ["a", "a", "a"]

# こういう例は推論したい（依存型）今のbuiltinでできる
ary = Array.new(3, "foo")

param = 3
ary = Array.new(param, "foo")

def createArray(n)
    Array.new(n, "foo")
end
createArray(3) # 上の例と同じようなグラフが生成されるはずなので可能なはず
createArray(1+2) # 難しそう


