    init = ->
      str = """
        (function () (label hoge 0 0 0 (break hoge)))
      """
      sExp = new Pebble str
      console.log "source: "+str
      console.log "read: "+sExp.toString()
      console.log "Array: "+sExp.toArray()
      console.log "JS: "+(js=sExp.toJavaScript())
      console.log "eval: "+eval js

    class Pebble
      constructor: (str)->
        console.log "==========="
        console.log "input: " + str
        return parser str

      parser = (str, chr="")->
        space = (fn)->
          if /^[^\s]/.test chr then fn()
          else                      step -> space fn
        step = (fn)->
          console.log "step", chr,str
          if str.length is 0 then throw "syntax erorr"
          chr = str[0]
          str = str.slice(1)
          fn()
        sexp = ->
          console.log "sexp",chr,str
          switch chr
            when "(" then step -> space list
            when "'" then new Cons(new Symbol("quote"),
                                   new Cons((step -> space sexp),
                                            new Nil))
            else          atom()
        list = ->
          console.log "list",chr,str
          switch chr
            when ")" then new Nil
            else          new Cons((space sexp),
                                   (step -> space list))
        atom = ->
          console.log "atom",chr,str
          switch chr
            when "\"" then a = /^(\".*[^\\]?\")/.exec(chr+str)[1]; str = str.slice (a).length-1; new Text a;
            when "\/" then
            when "\{" then
            when "\[" then
            else
              if /^([^\(\s\))]+)/.test(chr+str)
                token = /^([^\(\s\))]+)/.exec(chr+str)[1]
                rs = if token is "null"       then new Nil
                else if token is "undefined"  then new Void
                else if token is "true"       then new Logical true
                else if token is "false"      then new Logical false
                else if isFinite Number token then new Numerals Number token
                else                               new Symbol token
                console.log token
                str = str.slice (""+token).length-1
                rs
              else throw "???"
        tree = step -> space sexp
        console.log "tree: ", tree
        tree

      class SExpression
        constructor: (@val)->
        toString: -> @val
        toJavaScript: -> @val
        type: (ctr)-> @ instanceof ctr
        eval: -> evaluate @

      class Cons extends SExpression
        constructor: (@car, @cdr)->
        toArray: ->
          if !@cdr.type(Cons) then [@car]
          else                     [@car].concat @cdr.toArray()
        toString: (parent, str="")->
          if !parent?       then str += "("
          if @car.type Cons then str += "("
          str += @car.toString @
          if          @cdr.type Nil  then str += ")"
          else if not @cdr.type Cons then str += " . " + @cdr.toString(@) + ")"
          else                            str += " "   + @cdr.toString(@)
        symbols =
          ".": ([hash, prop, args...])->
            str =  hash.toJavaScript("exp")
            str += "[\""
            str += prop.toJavaScript("exp")
            str += "\"]"
            if args?
              str += "("
              str += args.map(
                (v)->v.toJavaScript("exp")
              ).join(", ")
              str += ")"
          "!": ([obj])->
            str = "!(" + obj.toJavaScript("exp") + ")"
          "%": ([a, b])->
            str =  "("
            str += a.toJavaScript("exp")
            str += " % "
            str += b.toJavaScript("exp")
            str += ")"
          "new": ([fnc, args...])->
            str =  "new " + fnc.toJavaScript("exp")
            str += "("
            str += args.map((v)->
              v.toJavaScript("exp")
            ).join(",")
            str += ")"
          "+": (args)-> @calc("+", args)
          "-": (args)-> @calc("-", args)
          "*": (args)-> @calc("*", args)
          "/": (args)-> @calc("/", args)
          "&&": (args)-> @calc("&&", args)
          "||": (args)-> @calc("||", args)
          "calc": (op, args)->
            str =  "("
            str += args.map((v)->
              v.toJavaScript("exp")
            ).join(op)
            str += ")"
          "<": (args)-> 
          ">": (args)-> 
          "<=": (args)-> 
          ">=": (args)-> 
          "===": (args)-> 
          "!==": (args)-> 
          "comp": (op, args)-> 
            str  = "("
            str += args.map((v,i)->
              if args[i+1]?
                v.toJavaScript("exp") +
                " " + val + " " +
                args[i+1].toJavaScript("exp")
            ).filter((v)->
              v isnt undefined
            ).join(" && ")
            str += ")"
          "var": ([symbol, exp])->
            str =  "var " + symbol.toJavaScript("exp")
            str += " = "  + exp.toJavaScript("exp")
          "fn": ([_args, stat..., rtn])->
            str =  "(function("
            if _args.type Cons
              str += _args.toArray().map((v)->
                v.toJavaScript()
              ).join(" ,")
            str += "){"
            stat.forEach (v)->
              str += v.toJavaScript()
              if !v.type Cons
                str += ";"
            if rtn?
              str += rtn.toJavaScript("rtn")
            else
              str += "return;"
            str += "})"
        toJavaScript: (ctx="stat", str="")->
          ary = @toArray()
          [{val:symbol}, args...] = ary
          if symbols[symbol]? then symbols[symbol](args)
          else

            
          else if val is "if"
            _args = args
            while true
              [exp, body, _args...] = _args
              if exp? and body?
                str += "if("
                str += exp.toJavaScript("exp")
                str += "){"
                str += body.toJavaScript("exp")
                str += "}else "
              else if exp?
                str += "{"
                str += exp.toJavaScript("exp")
                str += "}"
                break
              else
                str += "void 0"
                break
          else if val is "return"
            str += "return"
            if args[0]?
              str += " "
              str += args[0].toJavaScript("rtn")
          else
            [head, tail...] = ary.map (v)-> v.toJavaScript("exp")
            str += head
            str += "(" + tail.join(", ") + ")"
          if ctx is "stat"
            str += ";"
          str
      class Atom extends SExpression
      class Logical extends Atom
      class Numerals extends Atom
      class Text extends Atom
      class Symbol extends Atom
      class Nil extends Symbol
        constructor: -> @val = null
      class Void extends Symbol
        constructor: -> @val = undefined
      class Hash extends Atom
      class Vector extends Atom
      class Regex extends Atom

    init()