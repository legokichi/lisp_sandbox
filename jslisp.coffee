init = ->
  str = """
    (Number 0)
  """
  console.log "==========="
  console.log "input: #{str}"
  sExp = new Lisp(str)
  console.log "S-Exp: " + sExp.toString()
  console.log "result: " + sExp.eval()

class Lisp
  constructor: (str)->
    return parser tokenize str

  tokenize = (str)->
    str = str.split("(").join(" ( ")
    str = str.split(")").join(" ) ")
    str = str.split("'").join(" ' ")
    str = str.split(".").join(" . ")
    if str.split("(").length isnt str.split(")").length
      throw "Syntax error. '(' or ')' count wrong."
    tokens = str.split(/\s+/).filter (token)-> token isnt ""
    console.log "tokens: " + tokens
    tokens

  class SExpression
    isLiteral: -> @instOf(Nil) or @instOf(T)
    isList:    -> @instOf(Nil) or @instOf(Cons)
    instOf: (ctr)-> @ instanceof ctr
    eval: -> evaluate @
  
  class Cons extends SExpression
    constructor: (@car, @cdr)->
    last: ->
      if @cdr.instOf(Nil) then @car
      else                     @cdr.last()
    toString: (parent)->
      str = ""
      if parent is undefined  then str += "("
      if @car.instOf Cons    then str += "("
      str += @car.toString(@)
      if          @cdr.instOf Nil  then str += ")"
      else if not @cdr.instOf Cons then str += " . " + @cdr.toString(@) + ")"
      else                              str += " "   + @cdr.toString(@)
      str
    toArray: ->
      if not @cdr.isList()     then throw "cannot convert purelist to array."
      else if @cdr.instOf(Nil) then [@car]
      else                          [@car].concat @cdr.toArray()
  
  class Atom extends SExpression
    constructor: (@val)->
    toString: -> @val
  
  class Numerals extends Atom

  class String extends Atom

  class Object extends Atom

  class Array extends Atom

  class Symbol extends Atom
  
  class Bool extends Atom
  
  class T extends Bool
    constructor: -> @val = true
    toString: -> "T"
  
  class Nil extends Bool
    constructor: ->  @val = false
    toString: -> "nil"
  
  class Lambda extends Atom
    constructor: (@val, @sExp="(lambda (sExp) {native code})")->
    toString: -> @sExp.toString()

  parser = (tokens, token)->
    step = (fn)->
      if tokens.length is 0 then throw "Syntax Error. Something wrong."
      token = tokens.shift()
      fn()
    sExp = ->
      switch token
        when "(" then step list
        when "'" then new Cons(atom("quote"),
                               new Cons(step(sExp), atom("nil")))
        else          atom token
    list = ->
      switch token
        when ")" then atom "nil"
        when "."
          tmp = step sExp
          tokens.shift()
          tmp
        else
          tokens = [token].concat tokens
          new Cons(step(sExp), step(list))
    atom = (token)->
      if      token is "T"             then new T
      else if token is "nil"           then new Nil
      else if isFinite Number token    then new Numerals Number token
      else if isFinite Number token    then new Numerals Number token
      else if typeof token is "string" then new Symbol(token)
      else                                  throw token + "is strange type."
    tree = step sExp
    console.log "tree: ", tree
    tree

  evaluate = do ->
    _init = ->
      (sExp)->
        env = Object.create(window)
        env = extend env, funcs
        env = Object.create(env)
        _eval env, sExp
        true
    funcs = {}
    stack = (env, vars, args)->
      log 1, "stack", env, vars, args
      newEnv = Object.create(env)
      newEnv[vars[i]] = args[i] for i in [0..vars.length-1]
      log -1, "=>", newEnv
      newEnv
    find = (env, symbolName)->
      log 1, "find", env, symbolName
      sExp = env[symbolName] or throw symbolName + "is undefined"
      log -1, "=>", sExp.toString()
      sExp
    apply = (env, lambda, sExp)->
    evalAll = (env, sExp)->
    _eval = (env, sExp)->
      log 1, "eval", env, sExp.toString()
      if sExp.instOf(Cons)
        if sExp.car.instOf(Symbol)
        else     apply(env, _eval(env, sExp.car),     sExp.cdr)
      else if sExp.instOf(Symbol) then find(env, sExp.val)
      else if sExp.isLiteral()    then sExp
      else throw sExp + " is unkown expression."
      rslt = true
      log -1, "=>", rslt.toString()
      rslt
    _init()

  extend = (newer, origin)->
    newer[key] = val for key,val of origin
    newer

log = do ->
  space = 1
  (i, str, args...)->
    if      i>0 then space++
    else if i<0 then space--
    console.log Array(space).join("|") + str, if args? then args else null

init()