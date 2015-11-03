globalEnv = {}
_eval = (x,env=globalEnv)->
  if isSymbol x
    env[x]
  else if !x.isArray()
    x
  else if x[0] is "quote"
    [_,exp] = x
    return exp
  else if x[0] is "if"
    [_,test,conseq,alt] = x
    _eval((if _eval(test,env) then conseq elsealt),env)
  else if x[0] is "set"
    [_,_var,exp] = x
    env[_var] = exp
  else if x[0] is "fn"
    [_,args,body] = x
  else
tokenize = (str)->
  str
    .replace(/\s/g," ")
    .split("(").join(" ( ")
    .split(")").join(" ) ")
    .split(" ").filter((v)-> v isnt "")
readFrom = (tokens)->
  if tokens.length is 0
    throw "unexpected EOF while reading"
  token = tokens.shift()
  if token is "("
    list = []
    while tokens[0] != ")"
      list.push readFrom tokens
    tokens.shift()
    list
  else if token is ")"
    throw "unexpected )"
  else
    atom token
atom = (str)->
  if isFinite Number str then Number str
  else if /^[a-z_+\-*?]+$/i.test str then str
  else throw str+" is unexpected token"
parse = (str)->
  readFrom tokenize "(do"+str+")"
console.log parse """
(set squrt (fn (i)
  (* i i)))
(set add (fn (i)
  (+ i i)))
"""