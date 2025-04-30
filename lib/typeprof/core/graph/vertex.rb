module TypeProf::Core
  class BasicVertex
    # 型のハッシュとこれから追加される予定の型のハッシュを持つ
    def initialize(types)
      @types = types
      @types_to_be_added = {}
    end

    attr_reader :types

    def each_type(&blk)
      @types.each_key(&blk)

      until @types_to_be_added.empty?
        h = @types_to_be_added.dup
        h.each do |ty, source|
          @types[ty] = source
        end
        @types_to_be_added.clear
        h.each_key(&blk)
      end
    end

    def check_match(genv, changes, vtx)
      vtx.each_type do |ty|
        if ty.is_a?(Type::Var)
          changes.add_edge(genv, self, ty.vtx) if self != ty.vtx
          return true
        end
      end

      return true if vtx.types.empty?

      each_type do |ty|
        return true if vtx.types.include?(ty) # fast path
        if ty.check_match(genv, changes, vtx)
          return true
        end
      end

      return false
    end

    #エディタ上への表示
    def show
      Fiber[:show_rec] ||= Set[]
      if Fiber[:show_rec].include?(self)
        "untyped"
      else
        begin
          Fiber[:show_rec] << self
          types = [] #typesは型の表示する時の文字列のリスト
          bot = @types.keys.any? {|ty| ty.is_a?(Type::Bot) }
          optional = true_exist = false_exist = false
          each_type do |ty|
            if ty.is_a?(Type::Instance)
              case ty.mod.cpath
              when [:NilClass] then optional = true
              when [:TrueClass] then true_exist = true
              when [:FalseClass] then false_exist = true
              end
            end
          end
          bool = true_exist && false_exist
          types << "bool" if bool
          each_type do |ty, _source|
            if ty.is_a?(Type::Instance)
              next if ty.mod.cpath == [:NilClass]
              next if bool && (ty.mod.cpath == [:TrueClass] || ty.mod.cpath == [:FalseClass])
            end
            next if ty.is_a?(Type::Bot)
            types << ty.show
          end
          types = types.uniq.sort #ここで重複を取り除いてる？単純な型の集合
          # 表示
          case types.size # typesのsizeで場合分けして表示
          when 0
            optional ? "nil" : bot ? "bot" : "untyped"
          when 1
            types.first + (optional ? "?" : "")
          else
            "(#{ types.join(" | ") })" + (optional ? "?" : "")
          end
        ensure
          Fiber[:show_rec].delete(self) || raise
        end
      end
    end
  end

  # 例えばArrayNodeのinstall0から初期化として生成される
  class Source < BasicVertex
    def initialize(*tys) #可変長でリスト型を受け取って初期化
      types = {}
      #受け取った型のそれぞれがTypeProf内のTypeにマッチしているか検査し、型：tureというペアでハッシュに追加していく（なぜtrue？）
      tys.each do |ty|
        raise ty.inspect unless ty.is_a?(Type)
        types[ty] = true
      end
      super(types)
    end

    def on_type_added(genv, src_var, added_types)
      # TODO: need to report error?
    end

    def on_type_removed(genv, src_var, removed_types)
    end

    def new_vertex(genv, origin)
      nvtx = Vertex.new(origin)
      add_edge(genv, nvtx)
      nvtx
    end

    def add_edge(genv, nvtx)
      nvtx.on_type_added(genv, self, @types.keys)
    end

    def remove_edge(genv, nvtx)
      nvtx.on_type_removed(genv, self, @types.keys)
    end

    def show
      Fiber[:show_rec] ||= Set[]
      if Fiber[:show_rec].include?(self)
        "...(recursive)..."
      else
        begin
          Fiber[:show_rec] << self
          @types.empty? ? "untyped" : @types.keys.map {|ty| ty.show }.sort.join(" | ")
        ensure
          Fiber[:show_rec].delete(self) || raise
        end
      end
    end

    def to_s
      "<src:#{ show }>"
    end

    alias inspect to_s
  end

  class Vertex < BasicVertex
    def initialize(origin)
      # Note that origin is just for debug.
      # When an AST node is reused, the value of the origin will be invalid.
      case origin
      when AST::Node
      when RBS::AST::Declarations::Base
      when ValueEntity
      when ActualArguments
      when Array
      when Symbol
      else
        raise "unknown class: #{ origin.class }"
      end
      @next_vtxs = Set[]
      @origin = origin
      super({})
    end

    attr_reader :next_vtxs, :types

    def on_type_added(genv, src_var, added_types)
      new_added_types = []
      added_types.each do |ty|
        if @types[ty]
          @types[ty] << src_var
        else
          set = Set[]
          begin
            @types[ty] = set
          rescue
            @types_to_be_added[ty] = set
          end
          set << src_var
          new_added_types << ty
        end
      end
      unless new_added_types.empty?
        @next_vtxs.each do |nvtx|
          nvtx.on_type_added(genv, self, new_added_types)
        end
      end
    end

    def on_type_removed(genv, src_var, removed_types)
      new_removed_types = []
      removed_types.each do |ty|
        raise "!!! not implemented" if @types_to_be_added[ty]
        @types[ty].delete(src_var) || raise
        if @types[ty].empty?
          @types.delete(ty) || raise
          new_removed_types << ty
        end
      end
      unless new_removed_types.empty?
        @next_vtxs.each do |nvtx|
          nvtx.on_type_removed(genv, self, new_removed_types)
        end
      end
    end

    def new_vertex(genv, origin)
      nvtx = Vertex.new(origin)
      add_edge(genv, nvtx)
      nvtx
    end

    def add_edge(genv, nvtx)
      @next_vtxs << nvtx
      nvtx.on_type_added(genv, self, @types.keys) unless @types.empty?
    end

    def remove_edge(genv, nvtx)
      @next_vtxs.delete(nvtx) || raise
      nvtx.on_type_removed(genv, self, @types.keys) unless @types.empty?
    end

    $new_id = 0 # TODO: Use class variable

    def to_s
      id = "v#{ @id ||= $new_id += 1 }"
      "v#{id}:"
    end

    alias inspect to_s
  end
end
