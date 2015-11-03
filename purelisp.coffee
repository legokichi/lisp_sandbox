init = ->
  str = """
    (car (cons 0 1))
  """
  sExp = new Lisp str
  console.dir sExp.toJavaScript()

class Lisp
  constructor: (str)->
    console.log "==========="
    console.log "input: " + str
    return parser str

  parser = (str, chr=null)->
    step = (fn)->
      while true
        chr = str[0]
        str = str.slice(1)
        if chr isnt " " then break
      fn()
    sexp = ->
      switch chr
        when "(" then step list
        when "'" then new Cons(Symbol("quote"), new Cons(step(sexp), new Nil))
        else          atom
    list = ->
      switch chr
        when ")" then new Nil
        when "." then step -> step sexp
        else
          str = chr + str
          new Cons(step(sexp), step(list))
    atom = ->
      if ([__, token] = /^([^\S]+?)/.test(chr)) and token?
        if      token is "true"       then new Logical true
        else if token is "false"      then new Logical false
        else if token is "null"       then new Nil
        else if isFinite Number token then new Numerals Number token
        else                               new Symbol token
      else if [__, token] = /^\"(\\\"")\"/ and token? then new Text token
      
      else throw token + "is strange type."
    tree = step sExp
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
      if      @cdr.type(Nil) then [@car]
      else if @cdr.type(Cons)     [@car].concat @cdr.toArray()
      else throw "Error"
    toString: (parent)->
      str = ""
      if parent is undefined then str += "("
      if @car.type Cons      then str += "("
      str += @car.toString @
      if          @cdr.type Nil  then str += ")"
      else if not @cdr.type Cons then str += " . " + @cdr.toString(@) + ")"
      else                            str += " "   + @cdr.toString(@)
    toJavaScript: ->

  class Atom extends SExpression

  class Numerals extends Atom

  class Text extends Atom

  class Logical extends Atom

  class Symbol extends Atom

  class Nil extends Symbol
    constructor: -> @val = null

  class Void extends Symbol
    constructor: -> @val = undefined

  class Hash extends Atom

  class Vector extends Atom

  class Regex extends Atom

  class Lambda extends Atom
    constructor: (@val, @sExp="(lambda () [ native code ])")->
    toString: -> @sExp

  evaluate = do ->
    global = 
      car: new Lambda (sExp)->
        [arg0] = sExp.toArray()
        arg0.car
      cdr: new Lambda (sExp)->
        [arg0] = sExp.toArray()
        arg0.cdr
      atom: new Lambda (sExp)-> 
        [arg0] = sExp.toArray()
        if arg0.instOf(Cons) then new Nil else new T
      cons: new Lambda (sExp)->
        [arg0, arg1] = sExp.toArray()
        new Cons(arg0, arg1)
      eq: new Lambda (sExp)->
        _eq = (sExp)->
          [arg0, arg1, arg2] = sExp.toArray()
          if      arg1.instOf(Nil) then true
          else if arg2.instOf(Nil) then arg0.val is arg1.val
          else arg0.val is arg1.val and _eq(sExp.cdr)
        if _eq(sExp) then new T else new Nil
    stack = (env, vars, args)->
      newEnv = Object.create(env)
      newEnv[vars[i]] = args[i] for i in [0..vars.length-1]
      newEnv
    find = (env, symbolName)->
      if      env[symbolName]? then sExp = env[symbolName]
      else if   @[symbolName]?
        switch toStr @[symbolName]
          when "[object Function]" then sExp = new Lambda (sExp)=> @[symbolName].apply @, sExp.toArray()
          when "[object Object]"   then sExp = new Hash     @[symbolName]
          when "[object Array]"    then sExp = new Vector   @[symbolName]
          when "[object String]"   then sExp = new Text     @[symbolName]
          when "[object Number]"   then sExp = new Numerals @[symbolName]
          else                          sExp = new Nil
      else throw symbolName + " is undefined"
      log 0, symbolName + " -> " + sExp.toString()
      sExp
    apply = (env, lambda, sExp)->
      log 1, "(apply " + lambda.toString() + " " + sExp.toString() + ")"
      if not lambda.instOf(Lambda) then throw lambda.toString() " is not lambda."
      if not sExp.instOf(Cons)     then throw sExp.toString() + " is not list..."
      allrslt = evalAll(env, sExp)
      rslt = lambda.val(allrslt)
      log -1, "(apply " + lambda.toString() + " " + allrslt.toString() + " -> " + rslt.toString()
      rslt
    evalAll = (env, sExp)->
      if sExp.cdr.instOf(Nil)
           val = new Cons(_eval(env, sExp.car), new Nil(false))
      else val = new Cons(_eval(env, sExp.car), evalAll(env, sExp.cdr))
      val
    _eval = (env, sExp)->
      log 1, "(eval " + sExp.toString()
      rslt = if sExp.instOf(Cons)
        if sExp.car.instOf(Symbol)
          switch sExp.car.val
            when "quote"  then sExp.cdr
            when "if"
              [exp, t, f] = sExp.cdr.toArray()
              flag = _eval(env, exp)
              if not flag.instOf(Nil) then _eval(env, t)
              else                         _eval(env, f)
            when "define"
              [symbol, exp] = sExp.cdr.toArray()
              if not symbol.instOf(Symbol) then throw "define syntax error."
              value = _eval(env, exp)
              env[symbol.val] = value
            when "lambda"
              if not sExp.cdr.instOf(Cons) or not sExp.cdr.cdr.instOf(Cons)
                throw "lambda syntax error."
              do ->
                vars = sExp.cdr.car.toArray()
                body = sExp.cdr.cdr
                _env = env
                new Lambda(((sExp)->
                  args = sExp.toArray()
                  evalAll(stack(_env, vars, args), body).last()
                ), sExp)
            else apply(env,  find(env, sExp.car.val), sExp.cdr)
        else     apply(env, _eval(env, sExp.car),     sExp.cdr)
      else if sExp.instOf(Symbol) then find(env, sExp.val)
      else if sExp.isLiteral()    then sExp
      else throw sExp + " is unkown expression."
      log -1, "=>", rslt.toString()
      rslt
    (sExp)->
      result = _eval(global, sExp)
      console.log "result: ", result
      result

  toStr = (obj)-> Object.prototype.toString.apply(obj)

  log = do ->
    space = 1
    (i, str, args...)->
      if      i>0 then ws = space++
      else if i<0 then ws = --space
      else             ws = space
      console.log Array(ws).join("| ") + str, args

init()