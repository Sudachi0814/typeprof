## update: test.rbs
module Vec[Elem, Size < Integer]
  def initialize: (Elem val, Size size) -> void
  def self.new2: [E, S] (E val, S size) -> Vec[E, S]
                
  def test: [U] () { (Elem arg0) -> U } -> Vec[U, Plus[Size, 1]]
  
         
  def size: -> Size

  def self.f: (Elem val) -> Vec[Elem, Integer]
end

module Test
  def self.test: () -> Vec[Integer, Plus[1, 1]]
end

module Plus[L, R]
end


## update: test.rb

def test6()
  Test.test()
end

# def foo()
#   Vec.new2("foo", 2)
# end

def foo2()
  Vec.new2("foo", 2).test() {|elem| elem}
end

# def test0()
#   Vec.f("foo")
# end

# def test2()
#   a = [1,2,3]
#   a.map {|s| 42 }
# end

# def test3
#   if true
#     1 + 1
#   else 
#     "foo"
#   end
# end

# def test4
#   1 + 1
# end




## diagnostics: test.rb