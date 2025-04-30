## update: test.rb

def foo()
  lst = [1, 2, 3, 'Hello']
  new_lst1 = lst.map { |x| x }
  new_lst2 = new_lst1.map { |x| x }
  return new_lst2
end
