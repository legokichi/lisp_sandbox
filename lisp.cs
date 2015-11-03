
lisp = do ->

 see = (x)->
  if   ! isArray x
   if ! isFunction x then x
   else                   "(lambda ...)"
  else                  "(#{(see i for i in x).join(" ")})"

 log = do ->
  space = 1
  (str,i=0)->
   if      i>0 then console.log Array(space++).join(" ") + str
   else if i<0 then console.log Array(--space).join(" ") + str
   else             console.log Array(space  ).join(" ") + str

 global = [{
  car: (envs,[lst])->
   if ! isArray lst then throw lst + " is not list."
   else                  lst[0]
  cdr: (envs,[lst])->
   if ! isArray lst then throw lst + " is not list."
   else                  lst.slice 1
  cons: (envs,[car,cdr])->
   if ! isArray cdr then throw cdr + " is not list."
   else                  [].concat [car],cdr
  atom: (envs,[x])->            isAtom x
  eq: (envs,[a,b])->            a is b
  if: (envs,[bool,t,f])->       if bool then t else f
  eval: (envs,[exp])->            _eval  exp, envs
  apply: (envs,[fn,args...])->    _apply fn,  envs, args
  define: (envs,[symbol,value])-> _define envs, symbol, value
 }]

 _eval = (x,envs=global)->
  log "eval(#{see x},env)",1
  val = if isArray x
   if      x[0] is "quote"  then x[1]
   else if x[0] is "lambda"
                                 do ->
                                  letEnvs=envs
                                  (envs=letEnvs,args...)-> _eval x[2], _stack envs, x[1], args
   else                          _apply x[0], envs, x.slice 1
  else # isAtom x
   if      isSymbol  x      then _find envs,x
   else if isLiteral x      then x
  log "=#{see val}",-1
  val

 _apply = (head, envs, tail)->
  log "apply(#{head},env,#{see tail})",1
  fn   = _eval head, envs
  args = (_eval exp,  envs for exp in tail)
  val = if ! isFunction fn then throw fn + " is not function."
  else                    fn envs,args
  log "apply(#{head},env,#{see args})=#{val}",-1
  val

 isSymbol = (x)-> /^[^0-9].*?$/.test x
 isLiteral = (x)-> (/^-?[0-9]+?(?:\.?[0-9]+?)?$/.test x) or (/^\".*?\"$/.test x)

 _find = (envs,symbol)->
  env     = envs[envs.length-1]
  nxtEnvs = envs.slice(0,envs.length-1)
  if      envs.length is 0 then throw symbol + " is not defined."
  else if env[symbol]?     then env[symbol]
  else                          _find nxtEnvs, symbol

 _define = (envs,symbol,val)->
  env = envs[envs.length-1]
  if   env[symbol]? then throw symbol + " is allready defined."
  else                   env[symbol] = val

 _stack = (envs,vars,args)->
  env = {}
  vars.map (symbol,i)-> env[symbol] = args[i]
  envs.push env
  envs

 isArray    = (x)-> Object.prototype.toString.call(x) is "[object Array]"
 isFunction = (x)-> Object.prototype.toString.call(x) is "[object Function]"

 (lst)-> _eval lst

console.log lisp ["eval",["quote",["cons",0,["quote",[1]]]]]