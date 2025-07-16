module TypeProf::Core
  class Builtin
    # TODO: Integerで条件分岐している部分全般
    # TODO: +などの演算に対応するbuiltinでNumericSingletonの演算を実装
    def initialize(genv)
      @genv = genv
    end

    # suda: TODO: newでイニシャライズした時に型変数とマッチした値で初期化するような処理をまだやっていない。.newは返り値の型がRBSにはない！！

    def class_new(changes, node, ty, a_args, ret)
      puts 'class_new'
      if ty.is_a?(Type::Singleton)
        ty = ty.get_instance_type(@genv)
        recv = Source.new(ty)
        changes.add_method_call_box(@genv, recv, :initialize, a_args, false)
        changes.add_edge(@genv, Source.new(ty), ret)
      end
      true
    end

    def vec_new(changes, node, ty, a_args, ret)
      puts 'vec_new'
      if ty.is_a?(Type::Singleton) && ty.mod == @genv.mod_vec
        # Vec.newの場合の特別な処理
        if a_args.positionals.size == 2
          # Vec.new(size, val)の場合
          size_arg = a_args.positionals[0]
          val_arg = a_args.positionals[1]
          puts 'vec_new-vec生成'
          
          # size_argから整数値を取得
          size_value = nil
          size_arg.each_type do |size_ty|
            if size_ty.is_a?(Type::IntegerSingleton)
              size_value = size_ty.value
              break
            end
          end
          
          if size_value
            size_ty = Type::IntegerSingleton.new(@genv, size_value)
            vec_ty = @genv.gen_vec_type(val_arg, size_ty)
            changes.add_edge(@genv, Source.new(vec_ty), ret)
            return true
          end
        end

        # Vec.newの特別処理が適用されない場合、通常のclass_new処理
        class_new(changes, node, ty, a_args, ret)
      else
        # Vec以外のクラスの場合、通常のclass_new処理
        class_new(changes, node, ty, a_args, ret)
      end
    end

    def array_new(changes, node, ty, a_args, ret)
      puts 'array_new'
      if ty.is_a?(Type::Singleton) && ty.mod == @genv.mod_ary
        # Array.newの場合の特別な処理
        if a_args.positionals.size == 1
          # Array.new(size)の場合
          size_arg = a_args.positionals[0]
          if size_arg.is_a?(AST::IntegerNode)
            # サイズが定数の場合、Vec型を生成
            size_ty = Type::IntegerSingleton.new(@genv, size_arg.lit)
            elem_vtx = Vertex.new(node)
            vec_ty = @genv.gen_vec_type(elem_vtx, size_ty)
            changes.add_edge(@genv, Source.new(vec_ty), ret)
            return true
          end
        elsif a_args.positionals.size == 2
          # Array.new(size, default)の場合
          size_arg = a_args.positionals[0]
          default_arg = a_args.positionals[1]
          
          # size_argから整数値を取得（定数の場合）
          size_value = nil
          size_arg.each_type do |size_ty|
            if size_ty.is_a?(Type::IntegerSingleton)
              size_value = size_ty.value
              break
            end
          end
          
          puts size_value
          if size_value
            # 定数の場合
            size_ty = Type::IntegerSingleton.new(@genv, size_value)
            vec_ty = @genv.gen_vec_type(default_arg, size_ty)
            changes.add_edge(@genv, Source.new(vec_ty), ret)
            return true
          else
            # 変数や他の型の場合、Var型を使用してサイズを表現
            size_ty = Type::Var.new(@genv, :n, size_arg)
            vec_ty = @genv.gen_vec_type(default_arg, size_ty)
            changes.add_edge(@genv, Source.new(vec_ty), ret)
            return true
          end
        end

        # Array.newの特別処理が適用されない場合、通常のclass_new処理
        class_new(changes, node, ty, a_args, ret)
      else
        # Array以外のクラスの場合、通常のclass_new処理
        class_new(changes, node, ty, a_args, ret)
      end
    end

    def object_class(changes, node, ty, a_args, ret)
      ty = ty.base_type(@genv)
      mod = ty.is_a?(Type::Instance) ? ty.mod : @genv.mod_class
      ty = Type::Singleton.new(@genv, mod)
      vtx = Source.new(ty)
      changes.add_edge(@genv, vtx, ret)
      true
    end

    # ty proc callのレシーバの型
    def proc_call(changes, node, ty, a_args, ret)
      case ty
      when Type::Proc
        ty.block.accept_args(@genv, changes, a_args.positionals, ret, false)
        true
      else
        false
      end
    end

    def array_aref(changes, node, ty, a_args, ret)
      if a_args.positionals.size == 1
        case ty
        when Type::Array
          idx = node.positional_args[0]
          idx = if idx.is_a?(AST::IntegerNode)
                  idx.lit
                else
                  nil
                end
          vtx = ty.get_elem(@genv, idx)
          changes.add_edge(@genv, vtx, ret)
          true
        else
          false
        end
      else
        false
      end
    end

    def array_aset(changes, node, ty, a_args, ret)
      if a_args.positionals.size == 2
        case ty
        when Type::Array
          val = a_args.positionals[1]
          idx = node.positional_args[0]
          if idx.is_a?(AST::IntegerNode) && ty.get_elem(@genv, idx.lit)
            changes.add_edge(@genv, val, ty.get_elem(@genv, idx.lit))
          else
            changes.add_edge(@genv, val, ty.get_elem(@genv))
          end
          true
        else
          false
        end
      else
        false
      end
    end

    def array_push(changes, node, ty, a_args, ret)
      if a_args.positionals.size == 1
        if ty.is_a?(Type::Array)
          val = a_args.positionals[0]
          changes.add_edge(@genv, val, ty.get_elem(@genv))
        end
        recv = Source.new(ty)
        changes.add_edge(@genv, recv, ret)
      else
        false
      end
    end

    def hash_aref(changes, node, ty, a_args, ret)
      if a_args.positionals.size == 1
        case ty
        when Type::Hash
          idx = node.positional_args[0]
          idx = idx.is_a?(AST::SymbolNode) ? idx.lit : nil
          changes.add_edge(@genv, ty.get_value(idx), ret)
          true
        else
          false
        end
      else
        false
      end
    end

    def hash_aset(changes, node, ty, a_args, ret)
      if a_args.positionals.size == 2
        case ty
        when Type::Hash
          val = a_args.positionals[1]
          idx = node.positional_args[0]
          if idx.is_a?(AST::SymbolNode) && ty.get_value(idx.lit)
            # TODO: how to handle new key?
            changes.add_edge(@genv, val, ty.get_value(idx.lit))
          else
            # TODO: literal_pairs will not be updated
            changes.add_edge(@genv, a_args.positionals[0], ty.get_key)
            changes.add_edge(@genv, val, ty.get_value)
          end
          changes.add_edge(@genv, val, ret)
          true
        else
          false
        end
      else
        false
      end
    end

    # 返り値のノードを作る
    # 作ったNodeを返り値のNode（ret）に繋げる（Shapeはty.shapeと等しい）
    # Block.acceptを呼び出す(Blockに対応するグラフを作る？)（おそらく従来の処理に対応）
    # issue: a_args.blockにはVertexが入っている（BlockをVertexで包んでいる？）
    # 配列の要素の型、サイズを取り出して
    # retに直接返すのだと、Blockの返り値がcollectの返り血になってしまうので、新しいVertexを作って
    # 再実行のため、add_method_call_box再実装
    # TODO: 最新版をとってくる
    def array_collect(changes, node, ty, a_args, ret)
      if ty.is_a?(Type::Array) && a_args.block
        if ty.elems.nil? || ty.elems.empty?
          puts 'check'
          # pp node
          return true
        end
        # puts ty.show
        new_vertex = Vertex.new(node)
        a_args.block.each_type do |block_type|
          if block_type.is_a?(Type::Proc)
            block_type.block.accept_args(@genv, changes, [ty.get_elem(@genv)], new_vertex, false)
          end
        end
        base_ty = @genv.gen_ary_type0(new_vertex, ty.shape)
        ret_vertex = Source.new(base_ty)
        changes.add_edge(@genv, ret_vertex, ret)
        true

      elsif ty.is_a?(Type::Instance) && a_args.block && ty.mod.cpath == [:Array]
        new_vertex = Vertex.new(node)
        # puts ty.args
        # puts ty.show
        a_args.block.each_type do |block_type|
          block_type.block.accept_args(@genv, changes, ty.args, new_vertex, false) if block_type.is_a?(Type::Proc)
        end
        base_ty = @genv.gen_ary_type0(new_vertex, ty.shape)
        ret_vertex = Source.new(base_ty)
        changes.add_edge(@genv, ret_vertex, ret)
        true
      else
        false
      end
    end

    def deploy
      {
        # TODO: Array.newはクラスメソッド
        vec_new: [[:Vec], true, :new],
        array_new: [[:Array], true, :new],
        class_new: [[:Class], false, :new],
        object_class: [[:Object], false, :class],
        proc_call: [[:Proc], false, :call],
        array_aref: [[:Array], false, :[]],
        array_aset: [[:Array], false, :[]=],
        array_push: [[:Array], false, :<<],
        # array_collect:   [[:Array], false, :collect],
        hash_aref: [[:Hash], false, :[]],
        hash_aset: [[:Hash], false, :[]=]
      }.each do |key, (cpath, singleton, mid)|
        me = @genv.resolve_method(cpath, singleton, mid)
        me.builtin = method(key)
      end
    end
  end
end
