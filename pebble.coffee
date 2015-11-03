    init = ->
      str = """
        (= hoge 1 2 3)
      """
      sExp = new Pebble str
      console.log "source: "+str
      console.log "read: "+sExp.toString()
      console.log "JS: "+(js = sExp.toJavaScript())
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
            when "." then step -> space (-> a = sexp(); step(-> space ->); a)
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
        toJavaScript: (parent, str="")->
          ary = @toArray()
          if !parent?
            [head, tail...] = ary
            val = head.val
            if      val is "++" or      val is "--"
              val+tail[0].toJavaScript(@)
            else if val is "!" or       val is "~" or
                    val is "void" or    val is "typeof"
              val+"("+tail[0].toJavaScript(@)+")"
            else if val is "%" or       val is "in" or
                    val is "<<" or      val is ">>" or
                    val is "=" or       val is "+=" or
                    val is "-=" or      val is "*=" or
                    val is "/=" or      val is "%=" or
                    val is "&=" or      val is "|=" or
                    val is "^=" or      val is ">>=" or
                    val is "<<=" or     val is ">>>=" or
                    val is ">>>" or     val is "instanceof"
              "("+tail[0].toJavaScript(@)+" "+val+" "+tail[1].toJavaScript(@)+")"
            else if val is "new"
              val+" "+tail[0]+"("+tail.slice(1).map((v)->
                v.toJavaScript(@)
              ).join(",")+")"
            else if val is "var"
              "var "+tail[0]+" = "+tail[1]+";"
            else if val is "+" or       val is "-" or
                    val is "*" or       val is "/" or
                    val is "&&" or      val is "||"
              "("+tail.slice(1).map((v)->
                v.toJavaScript(@)
              ).join(val)+")"
            else if val is "<" or       val is ">" or
                    val is "<=" or      val is ">=" or
                    val is "==" or      val is "!=" or
                    val is "===" or     val is "!=="
              "("+tail.slice(1).map((v,i)->
                if tail[i+2]?
                  v+" "+val+" "+tail[i+2].toJavaScript(@)
              ).filter((v)->
                v isnt undefined
              ).join(" && ")+")"
            else if val is "label"
            else if val is "break" or   val is "throw" or
                    val is "continue"
              val + " " + tail[0].toJavaScript(@)
            else if val is "for"
              "for("+tail.slice(0,1).map((v)->
                v.toJavaScript(@)
              ).join("; ")+")"+"{"+tail[tail.length-1].toJavaScript(@)+";}"
            else if val is "forIn"
              "for("+tail[0].toJavaScript(@)+" in "+tail[1].toJavaScript(@)+"){"+tail[2].toJavaScript(@)+";}"
            else if val is "while" or
                    val is "with"
              val+"("+tail[0].toJavaScript(@)+"){"+tail[1].toJavaScript(@)+";}"
            else if val is "doWhile"
              "do{"+tail[0].toJavaScript(@)+";}while("+tail[1].toJavaScript(@)+")"
            else if val is "function" then
            else if val is "if" then
            else if val is "switch" then
            else if val is "try" then
            else if tail[0]?.car?.val is "quote"
              [hash, {cdr:{car:{val:prop}}}] = ary
              hash.toJavaScript()+"[\""+prop+"\"]"
            else
              [head, tail...] = ary.map (v)->
                if v.type Cons then v.toJavaScript()
                else                v.toJavaScript(@)
              head+"("+tail.join(", ")+")"
          else
            v.toString()
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