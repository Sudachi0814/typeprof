## update: test.rbs
module Vec[Elem, Size < Integer]
  def initialize: (Size size, Elem val) -> void

  def self.new2: [E, S] (E val, S size) -> Vec[E, S]
                
  def test: [U] () { (Elem arg0) -> U } -> Vec[U, Plus[Size, 1]]
  def test2: () -> Vec[Elem, Plus[Size, 1]]
  
  def size: -> Size

  def self.f: (Elem val) -> Vec[Elem, Integer]
end

module Test
  def self.test: () -> Vec[Integer, Plus[1, 1]]
end

module Plus[L, R]
end

## update: test.rb

# Vector型のリテラルテスト
def test1()
  [1, 2, 3]
end

# def test2()
#   ["foo", "bar", "baz"]
# end

def test3()
  [1, "two", 3.0]
end

def test4()
  vec = [1, 2, 3]
  vec.test2()
end

def test5()
  vec = ["foo", "bar", "baz"]
  vec.test() {|elem| elem.length}
end

def test6()
  vec = [1, 2, 3, 4, 5]
  vec.size() 
end



def test8
  Array.new(3, "foo")
end

def test9
  Vec.new(3, "foo")
end

## diagnostics: test.rb
