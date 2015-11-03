init = ->
  str = "((fn (a) a) a)"
  parser str

parser = (str, chr="")->
  space = (fn)->
    if /^[^\s]/.test chr then fn()
    else                      step -> space fn
  step = (fn)->
    if str.length is 0 then throw "syntax erorr"
    chr = str[0]
    str = str.slice(1)
    fn()
  sexp = ->
    console.log "sexp",chr,str
    switch chr
      when "(" then step -> space list
      when "'" then [new Symbol("quote")].concat (step -> space sexp)
      else          atom()
  list = ->
    console.log "list",chr,str
    switch chr
      when ")" then []
      else          [(space sexp)].concat (step -> space list)
  atom = ->
    console.log "atom",chr,str
    switch chr
      when "\""
        a = /^(\".*[^\\]?\")/.exec(chr+str)[1]
        str = str.slice (a).length-1
        new Text a
      when "\/" then
      when "\{" then 
      when "\[" then [new Symbol("list"), (space sexp)].concat (step -> space list)
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

class Atom
  constructor: (@val)->
  toString: -> @val
  type: (ctr)-> @ instanceof ctr
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