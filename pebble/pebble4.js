"use strict"

var init = function(){
  var code = PebbleLisp.compile("0");
  console.log(code);
};

var PebbleLisp = (function(){

  var call = function(name, arg, fn){
    log(1);
    log("@" + name + JSON.stringify(
        Array.prototype.slice.call(arg)
      ));
    var result = fn();
    log("@" + name + "->" + JSON.stringify(result));
    log(-1)
    return result;
  };

  var log = (function(){
    var indent = 0;
    var max = 80;
    var write = function(str){
      var _str = Array(indent).join("| ") + str;
      if(_str.length > max){
        _str = _str.slice(0, max)+"...";
      }
      console.log(_str);
    };
    return function(n, str){
      if(isFinite(n)) indent += n;
      if(typeof(n) === "string") str = n;
      if(str != null) write(str);
    };
  }());

  var parse = (function(){

    var parse = function(str){
      return call("parse", arguments, function(){
        var tree = new Tree();
        return root(str, tree);
      });
    };

    var space = function(str){
      if(/^\S/.test(str) || str.length === 0){
        return str;
      }else{
        var spc = /^\s+/.exec(str)[0];
        return str.slice(spc.length);
      }
    };

    var root = function(str, tree){
      return call("root", arguments, function(){
        var _str = space(str);
        if(_str.length === 0){
          return tree;
        }else if(/^\S/.test(_str)){
          var tmp = sExp(_str);
          var cstr = tmp[0];
          var sexp = tmp[1];
          tree.add(sexp);
          return root(cstr, tree);//次の式へ
        }
      });
    };

    var sExp = function(str){
      return call("sExp", arguments, function(){
        var _str = space(str);
        var head = _str[0];
        var tail = _str.slice(1);
        if(head === "("){//ここからリスト
          var tmp = list(tail);
        }else if(/^\S/.test(head)){//リスト以外のアトム
          var tmp = atom(_str);
        }
        var cstr = tmp[0];
        var sexp = tmp[1];
        return [cstr, sexp];
      });
    };

    var list = function(str){
      return call("list", arguments, function(){
        var _str = space(str);
        var head = _str[0];
        var tail = _str.slice(1)
        if(head === ")"){
          return [tail, new Nil()];
        }
        var tmp1  = sExp(_str);
        var cstr1 = tmp1[0];
        var fst   = tmp1[1];
        var tmp2  = list(cstr1);
        var cstr2 = tmp2[0];
        var scd   = tmp2[1];
        return [cstr2, new Cons(fst, scd)];
      });
    };

    var atom = function(str){
      return call("atom", arguments, function(){
        var _str = space(str);
        if(/^\"(.*[^\\]?)\"/.test(_str)){
          var tmp = /^\"(.*[^\\]?)\"/.exec(_str);
          var mch = tmp[0];
          var val = tmp[1];
          var cstr = _str.slice(mch.length);
          return [cstr, new Text(val)];
        }else if(/^\-?\d+(?:\.\d+)?/.test(_str)){
          var val = /^\-?\d+(?:\.\d+)?/.exec(_str)[0];
          var cstr = _str.slice(val.length);
          return [cstr, new Numerals(Number(val))];
        }else if(/^[^\s\'\`\,\@\#\"\;]+/.test(_str)){
          var val = /^[^\s\'\`\,\@\#\"\;\(\)]+/.exec(_str)[0];
          var cstr = _str.slice(val.length);
          return [cstr, new Symbol(val)];
        }else{
          throw "error";
        }
      });
    };

    var Tree = (function() {
      function Tree() {
        this.lines = [];
      }
      Tree.prototype.add = function(sexp) {
        return this.lines.push(sexp);
      };
      Tree.prototype.toString = function() {
        return this.lines.map(function(sexp){
          return sexp.toString();
        }).join("\n\n");
      }
      Tree.prototype.map = function(fn){
        return this.lines.map(fn);
      };
      return Tree;
    })();

    return parse;
  }());

  var compile = (function(){

    var compile = function(str){
      var tree = parse(str);
      console.log(tree.toString());
      var env = new Environment();
      return tree.map(function(sexp){
        return evaluate(env, sexp);
      }).join("\n\n");
    };

    var evaluate = function(env, sexp){
      return call("evaluate", arguments, function(){
        if(sexp.isTypeOf(Cons)){
          var head = sexp.car;
          var tail = sexp.cdr;
          var tmp = evaluate(env, head);
          var _env = tmp[0];
          var val  = tmp[1];
          if(val.isTypeOf(SpecialForm)){
            return val.call(_env, tail);
          }else if(val.isTypeOf(Macro)){
            return val.call(_env, tail);
          }else if(val.isTypeOf(Lambda)){
            return val.call(_env, tail);
          }else{
            throw "error";
          }
        }else if(sexp.isTypeOf(Atom)){
          if(sexp.isTypeOf(Symbol)){//シンボルは値へ
            return find(env, sexp);
          }else if(sexp.isTypeOf(Numerals) ||//即値
                   sexp.isTypeOf(Text)     ||
                   sexp.isTypeOf(Lambda)   ||
                   sexp.isTypeOf(Macro)){
            return sexp;
          }
        }
        throw "error";
      });
    };

    var apply = function(env, sexp){
      return call("apply", arguments, function(){
        return [_env, rslt];
      });
    };

    var find = function(env, sexp){
      return call("find", arguments, function(){
        if(! sexp.isTypeOf(Symbol)) throw "error";
        return env.find(sexp.value);
      });
    };

    var Environment = (function() {
      var globalEnv = {
        def: new SpecialForm(function(env, sexp){
          var symbol = sexp.car;
          var value  = sexp.cdr;
          env.define(symbol.value, value.value)
          return [env, new Nil];
        })
      };
      function Environment() {
        this.stack = [globalEnv];
      }
      Environment.prototype.find = function(str){
        var resulst;
        this.stack.forEach(function(elm){
          resulst = elm[str] || resulst;
        });
        if(typeof resulst === "undefined") throw "error";
        return result;
      };
      Environment.prototype.define = function(str, val){
        return this.stack[this.stack.length-1][str] = val;
      };
      Environment.prototype.addClosure = function(){
        return this.stack.push({});
      };
      Environment.prototype.copyClosure = function(){
        return this.stack.slice();
      };
      return Environment;
    })();

    return compile;
  }());

  var __hasProp = {}.hasOwnProperty,
      __extends = function(child, parent) {
    for (var key in parent) {
      if (__hasProp.call(parent, key)) child[key] = parent[key];
    }
    function ctor() {
      this.constructor = child;
    }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.__super__ = parent.prototype;
    return child;
  };

  var Data = (function() {
    function Data(){
      this.type = "data";
    }
    Data.prototype.isTypeOf = function(cnstr) {
      return this instanceof cnstr;
    };
    Data.prototype.toString = function() {
      return "" + this.value;
    };
    return Data;
  })();

  var Cons = (function(_super) {
    __extends(Cons, _super);
    function Cons(car, cdr) {
      this.type = "cons";
      this.car = car;
      this.cdr = cdr;
    }
    Cons.prototype.toString = function(parent, str) {
      str = str || "";
      var head = this.car;
      var tail = this.cdr;
      if(parent == null)        str += "(";
      if(head.isTypeOf(Cons)) str += "(";
      str += head.toString(this);
      if(tail.isTypeOf(Nil)){
        str += ")";
      }else if(!tail.isTypeOf(Cons)){
        str += " . " + tail.toString(this) + ")";
      }else{
        str += " " + tail.toString(this);
      }
      return str;
    };
    return Cons;
  })(Data);

  var Atom = (function(_super) {
    __extends(Atom, _super);
    function Atom() {
      this.type = "atom";
    }
    return Atom;
  })(Data);

  var Nil = (function(_super) {
    __extends(Nil, _super);
    function Nil() {
      this.type = "nil";
      this.value = null;
    }
    return Nil;
  })(Atom);

  var Logical = (function(_super) {
    __extends(Logical, _super);
    function Logical() {
      this.type = "logical";
      this.value = false;
    }
    return Logical;
  })(Atom);

  var Void = (function(_super) {
    __extends(Void, _super);
    function Void() {
      this.type = "void";
      this.value = undefined;
    }
    return Void;
  })(Atom);

  var Symbol = (function(_super) {
    __extends(Symbol, _super);
    function Symbol(value) {
      this.type = "symbol";
      this.value = value;
    }
    return Symbol;
  })(Atom);

  var Numerals = (function(_super) {
    __extends(Numerals, _super);
    function Numerals(value) {
      this.type = "numerals";
      this.value = value;
    }
    return Numerals;
  })(Atom);

  var Text = (function(_super) {
    __extends(Text, _super);
    function Text(value) {
      this.type = "text";
      this.value = value;
    }
    Text.prototype.toString = function() {
      return "\"" + this.value + "\"";
    };
    return Text;
  })(Atom);

  var SpecialForm = (function(_super) {
    __extends(SpecialForm, _super);
    function SpecialForm(fn) {
      this.type = "specialform";
      this.fn = fn;
    }
    SpecialForm.prototype.call = function(env, argsexp){
      return this.fn(env, argsexp);
    };
    return SpecialForm;
  })(Atom);

  var Macro = (function(_super) {
    __extends(Macro, _super);
    function Macro(sexp) {
      this.type = "macro";
      this.sexp = sexp;
    }
    Macro.prototype.call = function(env, argsexp){
    };
    return Macro;
  })(Atom);

  var Lambda = (function(_super) {
    __extends(Lambda, _super);
    function Lambda(val) {
      this.type = "lambda";
      this.sexp = null;
      this.fn = null;
      this.closure = null;
      if(val instanceof Cons){
        this.sexp = sexp;
      }else{
        this.fn = fn;
      }
    }
    Lambda.prototype.call = function(env, argsexp){
      if(this.fn != null){
        return this.fn(env, argsexp);
      }
    };
    return Lambda;
  })(Atom);

  return {
    parse: parse,
    compile: compile
  };

}());

init();