module TypeProf
  class Type
    include StructuralEquality

    class Untyped < Type
      def inspect
        "<untyped>"
      end
    end

    class Module < Type
      def initialize(cpath)
        # TODO: type_param
        @cpath = cpath
      end

      attr_reader :cpath

      def show
        "singleton(#{ @cpath.join("::" ) })"
      end
    end

    class Class < Module
      def initialize(cpath)
        # TODO: type_param
        @cpath = cpath
      end

      attr_reader :kind, :cpath

      def get_instance_type
        raise "cannot instantiate a module" if @kind == :module
        Instance.new(@cpath)
      end
    end

    class Instance < Type
      def initialize(cpath)
        raise unless cpath.is_a?(Array)
        @cpath = cpath
      end

      attr_reader :cpath

      def get_class_type
        Class.new(:class, @cpath)
      end

      def show
        "#{ @cpath.join("::" )}"
      end
    end

    class RBS < Type
      def initialize(rbs_type)
        @rbs_type = rbs_type
      end

      def inspect
        "#<Type::RBS ...>"
      end
    end
  end

  class ReadSite
    def initialize(genv, node, cref, cbase, cname)
      @node = node
      @cref = cref
      @cbase = cbase
      @cname = cname
      @ret = Vertex.new("cname:#{ cname }", node)
      genv.add_readsite(self)
      genv.add_run(self)
      @cbase.add_edge(genv, self) if @cbase
      @edges = Set.new
    end

    def on_type_added(genv, src_tyvar, added_types)
      genv.add_run(self)
    end

    def on_type_removed(genv, src_tyvar, removed_types)
      genv.add_run(self)
    end

    attr_reader :node, :cref, :cbase, :cname, :ret

    def run(genv)
      destroy(genv)

      resolve(genv).each do |cds|
        cds.each do |cd|
          case cd
          when ConstDecl
            # TODO
            raise
          when ConstDef
            @edges << [cd.val, @ret]
          end
        end
      end

      @edges.each do |src_tyvar, dest_tyvar|
        src_tyvar.add_edge(genv, dest_tyvar)
      end
    end

    def destroy(genv)
      @edges.each do |src_tyvar, dest_tyvar|
        src_tyvar.remove_edge(genv, dest_tyvar)
      end
      @edges.clear
    end

    def resolve(genv)
      ret = []
      if @cbase
        @cbase.types.each do |ty, source|
          case ty
          when Type::Class
            cds = genv.resolve_const(ty.cpath, @cname)
            ret << cds if cds
          else
            puts "???"
          end
        end
      else
        cref = @cref
        while cref
          cds = genv.resolve_const(cref.cpath, @cname)
          if cds && !cds.empty?
            ret << cds
            break
          end
          cref = cref.outer
        end
      end
      ret
    end

    @@new_id = 0

    def to_s
      "R#{ @id ||= @@new_id += 1 }"
    end

    alias inspect to_s

    def long_inspect
      "#{ to_s } (cname:#{ @cname }, #{ @node.lenv.text_id } @ #{ @node.code_range })"
    end
  end

  class CallSite
    def initialize(genv, node, recv, mid, args)
      raise mid.to_s unless mid
      @node = node
      @recv = recv
      @mid = mid
      @args = args
      @ret = Vertex.new("ret:#{ mid }", node)
      @edges = Set.new
      genv.add_callsite(self)
      genv.add_run(self)
      @recv.add_edge(genv, self)
      @args.add_edge(genv, self)
    end

    attr_reader :node, :recv, :mid, :args, :ret

    def on_type_added(genv, src_tyvar, added_types)
      genv.add_run(self)
    end

    def on_type_removed(genv, src_tyvar, removed_types)
      genv.add_run(self)
    end

    def run(genv)
      destroy(genv)

      resolve(genv).each do |ty, mds|
        mds.each do |md|
          case md
          when MethodDecl
            if md.builtin
              md.builtin[ty, @mid, @args, @ret].each do |src, dest|
                @edges << [src, dest]
              end
            else
              ret_types = md.resolve_overloads(genv, @args)
              # TODO: handle Type::Union
              ret_types.each do |ty|
                @edges << [Source.new(ty), @ret]
              end
            end
          when MethodDef
            @edges << [@args, md.arg] << [md.ret, @ret]
          end
        end
      end

      @edges.each do |src_tyvar, dest_tyvar|
        src_tyvar.add_edge(genv, dest_tyvar)
      end
    end

    def destroy(genv)
      @edges.each do |src_tyvar, dest_tyvar|
        src_tyvar.remove_edge(genv, dest_tyvar)
      end
      @edges.clear
    end

    def resolve(genv)
      ret = []
      @recv.types.each do |ty, source|
        # TODO: resolve ty#mid
        # assume ty is a Type::Instnace or Type::Class
        mds = genv.resolve_method(ty.cpath, ty.is_a?(Type::Class), @mid)
        ret << [ty, mds] if mds
      end
      ret
    end

    @@new_id = 0

    def to_s
      "C#{ @id ||= @@new_id += 1 }"
    end

    alias inspect to_s

    def long_inspect
      "#{ to_s } (mid:#{ @mid }, #{ @node.lenv.text_id } @ #{ @node.code_range })"
    end
  end
end
