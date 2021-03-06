// Generated by LiveScript 1.5.0
var LiveScript, path, fs, util, os, prelude, each, lines, unlines, take, fileExists, dasherize, dasherizeVars;
LiveScript = require('..');
path = require('path');
fs = require('fs');
util = require('util');
os = require('os');
prelude = require('prelude-ls'), each = prelude.each, lines = prelude.lines, unlines = prelude.unlines, take = prelude.take;
fileExists = function(path){
  try {
    fs.statSync(path);
    return true;
  } catch (e$) {}
};
dasherize = function(it){
  return it.replace(/([^-A-Z])([A-Z]+)/g, function(arg$, lower, upper){
    return lower + "-" + (upper.length > 1
      ? upper
      : upper.toLowerCase());
  }).replace(/^([A-Z]+)/, function(arg$, upper){
    if (upper.length > 1) {
      return upper;
    } else {
      return upper.toLowerCase();
    }
  });
};
dasherizeVars = function(str){
  if (/^[a-z]/.exec(str)) {
    return dasherize(str);
  } else {
    return str;
  }
};
function repl(o, stdin, stdout){
  var say, warn, die, p, pp, ppp, MAXHISTORYSIZE, homeDir, historyFile, code, cont, rl, reset, _ttyWrite, prompt, that, vm, vmError, REPLServer, serverOptions, nodeVersion, DummyStream, server, replCtx, ref$;
  stdin == null && (stdin = process.stdin);
  stdout == null && (stdout = process.stdout);
  say = function(){
    return stdout.write(util.format.apply(null, arguments) + "\n");
  };
  warn = console.error;
  die = function(message){
    console.error(message);
    process.exit(1);
  };
  p = function(){
    var args, res$, i$, to$;
    res$ = [];
    for (i$ = 0, to$ = arguments.length; i$ < to$; ++i$) {
      res$.push(arguments[i$]);
    }
    args = res$;
    each(console.dir, args);
  };
  pp = function(x, showHidden, depth){
    say(util.inspect(x, showHidden, depth, !process.env.NODE_DISABLE_COLORS));
  };
  ppp = function(it){
    pp(it, true, null);
  };
  MAXHISTORYSIZE = 500;
  homeDir = (typeof os.homedir == 'function' ? os.homedir() : void 8) || process.env.HOME || process.env.USERPROFILE;
  historyFile = path.join(homeDir, '/.lsc_history');
  code = repl.infunc ? '  ' : '';
  cont = 0;
  rl = require('readline').createInterface(stdin, stdout);
  reset = function(){
    rl.line = code = '';
    rl.prompt();
    repl.inheredoc = false;
  };
  (_ttyWrite = rl._ttyWrite, rl)._ttyWrite = function(char){
    if (char === '\n' || char === '>') {
      cont += 1;
    } else {
      cont = 0;
    }
    return _ttyWrite.apply(this, arguments);
  };
  prompt = 'ls';
  if (that = repeatString$('b', !!o.bare) + repeatString$('c', !!o.compile)) {
    prompt += " -" + that;
  }
  try {
    rl.history = lines(fs.readFileSync(historyFile, 'utf-8').trim());
  } catch (e$) {}
  if (LiveScript != null) {
    LiveScript.history = rl.history;
  }
  if (!o.compile) {
    module.paths = module.constructor._nodeModulePaths(module.filename = process.cwd() + '/repl');
    vm = require('vm');
    if (o.prelude) {
      import$(global, prelude);
    }
    REPLServer = require('repl').REPLServer;
    serverOptions = {
      useGlobal: true,
      useColors: process.env.NODE_DISABLE_COLORS,
      eval: function(code, ctx, arg$, cb){
        var res, e;
        try {
          res = vm.runInNewContext(code, ctx, 'repl');
        } catch (e$) {
          e = e$;
        }
        cb(e, res);
      }
    };
    nodeVersion = process.versions.node.split('.');
    if (+nodeVersion[0] > 6 || +nodeVersion[0] === 6 && +nodeVersion[1] >= 4) {
      DummyStream = (function(superclass){
        var prototype = extend$((import$(DummyStream, superclass).displayName = 'DummyStream', DummyStream), superclass).prototype, constructor = DummyStream;
        DummyStream.prototype.readable = true;
        DummyStream.prototype.writable = true;
        DummyStream.prototype.resume = function(){};
        DummyStream.prototype.write = function(){};
        function DummyStream(){
          DummyStream.superclass.apply(this, arguments);
        }
        return DummyStream;
      }(require('stream')));
      server = new REPLServer((serverOptions.stream = new DummyStream, serverOptions));
      replCtx = server.context;
    } else {
      replCtx = {};
      import$(replCtx, global);
      replCtx.module = module;
      replCtx.exports = exports;
      replCtx.require = require;
      server = (ref$ = import$(clone$(REPLServer.prototype), serverOptions), ref$.context = replCtx, ref$.commands = [], ref$);
    }
    replCtx.LiveScript = LiveScript;
    replCtx.path = path;
    replCtx.fs = fs;
    replCtx.util = util;
    replCtx.say = say;
    replCtx.warn = warn;
    replCtx.die = die;
    replCtx.p = p;
    replCtx.pp = pp;
    replCtx.ppp = ppp;
    rl.completer = function(line, cb){
      var that, js, lineEndsInDash, completedFrom, lastPart;
      if (that = analyzeForCompletion(line)) {
        js = that.js, lineEndsInDash = that.lineEndsInDash, completedFrom = that.completedFrom, lastPart = that.lastPart;
      } else {
        return cb(null, [[], line]);
      }
      server.complete(js, function(e, arg$){
        var matches, _, toRemove, incompleteExpr, newMatches, res$, i$, len$, m, completion, completionStartsWord;
        matches = arg$[0], _ = arg$[1];
        if (e != null) {
          return cb(e);
        }
        toRemove = js.length;
        incompleteExpr = line.substr(completedFrom);
        res$ = [];
        for (i$ = 0, len$ = matches.length; i$ < len$; ++i$) {
          m = matches[i$];
          if (m === '') {
            res$.push(m);
          } else {
            completion = m.substr(toRemove);
            if (lastPart != null) {
              completionStartsWord = /^[A-Z]/.exec(completion);
              if (lineEndsInDash) {
                if (!completionStartsWord) {
                  continue;
                }
                completion = dasherize(completion);
              } else if (!/(^[^a-z])|[a-z-][A-Z]/.test(lastPart)) {
                completion = dasherize(completion);
                if (completionStartsWord) {
                  completion = '-' + completion;
                }
              }
            } else {
              completion = dasherizeVars(completion);
            }
            res$.push(incompleteExpr + completion);
          }
        }
        newMatches = res$;
        cb(null, [newMatches, incompleteExpr]);
      });
    };
  }
  rl.on('SIGCONT', rl.prompt);
  rl.on('SIGINT', function(){
    if (this.line || code) {
      say('');
      reset();
    } else {
      this.close();
    }
  });
  rl.on('line', function(it){
    var isheredoc, ops, x, e;
    if (it.match(/^$/)) {
      repl.infunc = false;
    }
    if (it.match(/(\=|\~>|->|do|import|switch)\s*$/) || (it.match(/^!?(function|class|if|unless) /) && !it.match(/ then /))) {
      repl.infunc = true;
    }
    if (((0 < cont && cont < 3) || repl.infunc) && !repl.inheredoc) {
      code += it + '\n';
      this.output.write(repeatString$('.', prompt.length) + '. ');
      return;
    } else {
      isheredoc = it.match(/(\'\'\'|\"\"\")/g);
      if (isheredoc && isheredoc.length % 2 === 1) {
        repl.inheredoc = !repl.inheredoc;
      }
      if (repl.inheredoc) {
        code += it + '\n';
        rl.output.write(repeatString$('.', prompt.length) + '" ');
        return;
      }
    }
    repl.inheredoc = false;
    if (!(code += it)) {
      return reset();
    }
    try {
      if (o.compile) {
        say(LiveScript.compile(code, {
          bare: o.bare
        }));
      } else {
        ops = {
          'eval': 'eval',
          bare: true,
          saveScope: LiveScript
        };
        if (code.match(/^\s*!?function/)) {
          ops = {
            bare: true
          };
        }
        x = vm.runInNewContext(LiveScript.compile(code, ops), replCtx, 'repl');
        if (x != null) {
          replCtx._ = x;
        }
        pp(x);
      }
    } catch (e$) {
      e = e$;
      if (!o.compile) {
        vmError == null && (vmError = vm.runInNewContext('Error', replCtx));
        if (!(e instanceof vmError)) {
          if (typeof stdin.setRawMode === 'function') {
            stdin.setRawMode(false);
            stdin.setRawMode(true);
          }
        }
      }
      say(e);
    }
    reset();
  });
  if (stdin === process.stdin) {
    rl.on('close', function(){
      say('');
      return process.exit();
    });
    process.on('uncaughtException', function(it){
      say("\n" + ((it != null ? it.stack : void 8) || it));
    });
    process.on('exit', function(){
      if (code && rl.output.isTTY) {
        rl._ttyWrite('\r');
      }
      if (fileExists(historyFile)) {
        fs.writeFileSync(historyFile, compose$(take(MAXHISTORYSIZE), unlines)(rl.history));
      }
    });
  }
  rl.setPrompt(prompt + "> ");
  rl.prompt();
}
function analyzeForCompletion(line){
  var lineEndsInDash, completedFrom, tokens, e, js, t, lastToken, jsParts, token, lastPart;
  lineEndsInDash = line[line.length - 1] === '-';
  completedFrom = line.length;
  try {
    tokens = LiveScript.tokens(lineEndsInDash ? line + 'Z' : line);
  } catch (e$) {
    e = e$;
    return;
  }
  if (tokens.length === 0) {
    js = '';
  } else {
    if (tokens[tokens.length - 1][0] === 'NEWLINE') {
      tokens.pop();
    }
    while ((t = tokens[tokens.length - 1][0]) === 'DEDENT' || t === ')CALL') {
      tokens.pop();
    }
    lastToken = tokens[tokens.length - 1];
    if (lineEndsInDash) {
      if (lastToken[0] !== 'ID') {
        throw "unexpected token " + lastToken[0];
      }
      if (lastToken[1] === 'Z') {
        tokens.pop();
        lastToken = tokens[tokens.length - 1];
      } else {
        lastToken[1] = lastToken[1].substr(0, lastToken[1].length - 1);
      }
    }
    if (lastToken[0] === 'STRNUM') {
      return;
    }
    jsParts = [];
    token_loop: while (tokens.length) {
      switch ((token = tokens.pop())[0]) {
      case 'ID':
      case 'DOT':
        completedFrom = token[3];
        jsParts.unshift(token[0] === 'DOT'
          ? '.'
          : token[1]);
        break;
      default:
        break token_loop;
      }
    }
    js = jsParts.join('');
    if (lastToken[0] === 'ID') {
      lastPart = line.substr(lastToken[3]);
    }
  }
  return {
    lineEndsInDash: lineEndsInDash,
    completedFrom: completedFrom,
    js: js,
    lastPart: lastPart
  };
}
module.exports = repl;
function repeatString$(str, n){
  for (var r = ''; n > 0; (n >>= 1) && (str += str)) if (n & 1) r += str;
  return r;
}
function import$(obj, src){
  var own = {}.hasOwnProperty;
  for (var key in src) if (own.call(src, key)) obj[key] = src[key];
  return obj;
}
function extend$(sub, sup){
  function fun(){} fun.prototype = (sub.superclass = sup).prototype;
  (sub.prototype = new fun).constructor = sub;
  if (typeof sup.extended == 'function') sup.extended(sub);
  return sub;
}
function clone$(it){
  function fun(){} fun.prototype = it;
  return new fun;
}
function compose$() {
  var functions = arguments;
  return function() {
    var i, result;
    result = functions[0].apply(this, arguments);
    for (i = 1; i < functions.length; ++i) {
      result = functions[i](result);
    }
    return result;
  };
}