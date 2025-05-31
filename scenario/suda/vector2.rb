## update: test.rbs
module Vec[Elem, Size < Integer]
  def initialize: (Elem val, Size size) -> void
  def self.new2: [E, S] (E val, S size) -> Vec[E, S]

  def self.new3: [E, S1, S2] (E val, S1 size1, S2 size2) -> Vec[E, Plus[S1, S2]]
                
  def test: [U] () { (Elem arg0) -> U } -> Vec[U, Plus[Size, 1]]
end


module Plus[L, R]
end


## update: test.rb

# [suda]bug: IntegerSingletonのUnionがPlusの要素になると全て足し合わされてしまう
# [X] (X, Plus[X, 1]) -> Vec[String, Plus[X, 1]] 
def foo(l, m)
  Vec.new3("hello", l, m)
end

foo(2,3)
foo(1,3) # [suda]: TODO:これはエラーにしたい
# とりあえず↑が同じ型変数で動くところから
# 他の試みのケースは本研究では実現できそうかどうか定性的に評価する(星取表)