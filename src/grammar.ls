# The LiveScript parser is generated by [Jison](http://github.com/zaach/jison)
# from this grammar file. Jison is a bottom-up parser generator, similar in
# style to [Bison](http://www.gnu.org/software/bison),
# implemented in JavaScript.
# It can recognize
# [LALR(1), LR(0), SLR(1), and LR(1)](http://en.wikipedia.org/wiki/LR_grammar)
# type grammars. To create the Jison parser, we list the pattern to match
# on the left-hand side, and the action to take (usually the creation of syntax
# tree nodes) on the right. As the parser runs, it
# shifts tokens from our token stream, from left to right, and
# [attempts to match](http://en.wikipedia.org/wiki/Bottom-up_parsing)
# the token sequence against the rules below. When a match can be made, it
# reduces into the
# [nonterminal](http://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols)
# (the enclosing name at the top), and we proceed from there.
#
# If you run the `scripts/build-parser` command, Jison constructs a parse table
# from our rules and saves it into [lib/parser.js](../lib/parser.js).

# Jison DSL
# ---------

# Our handy DSL for Jison grammar generation, thanks to
# [Tim Caswell](http://github.com/creationix). For every rule in the grammar,
# we pass the pattern-defining string, the action to run, and extra options,
# optionally. If no action is specified, we simply pass the value of the
# previous nonterminal.
ditto = {}
last  = ''

o = (patterns, action, options) ->
    patterns.=trim!.split /\s+/
    action &&= if action is ditto then last else
        "#action"
        .replace /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/ (, a) ->
            "$$ = #{ (if 'L(' is a.slice 0, 2 then '(' else "L(@1, @#{patterns.length},") }#a);"
        .replace /\b(?!Er)(?!String)[A-Z][\w.]*/g 'yy.$&'
        .replace /(\.L\()\s*(\d+\s*\,)\s*(\d+\s*\,)?/g (, a, b, c) ->
            "#a@#{ b || '1,' }@#{ c || b || "#{patterns.length}," }"
    [patterns, last := action or '', options]

# Grammatical Rules
# -----------------

# In all of the rules that follow, you'll see the name of the nonterminal as
# the key to a list of alternative matches. With each match's action, the
# dollar-sign variables are provided by Jison as references to the value of
# their numeric position, so in this rule:
#
#     Expression MATH Expression
#
# `$1` would be the value of the first _Expression_, `$2` would be the token
# value for the _MATH_ terminal, and `$3` would be the value of the second
# _Expression_.
bnf =
    # The types of things that can be accessed or called into.
    Chain:
        o 'ID'            -> Chain L 1 Var $1
        o 'KeyLike'       -> Chain $1
        o 'List'          ditto
        o 'LITERAL'       -> Chain L 1 Literal $1

        o 'Chain Index'       -> $1.add $2

        o 'Chain CALL( ArgList OptComma )CALL' -> $1.add L 2 5 Call $3

        o 'Chain ?' -> Chain L 1 2 Existence $1.unwrap!

        o 'LET CALL( ArgList OptComma )CALL Block' -> Chain L 1 5 Call.let $3, $6

        o '[ Expression LoopHeads ]'
        , -> Chain L 1 4 ($3.0.make-comprehension $2, $3.slice 1)
        o '[ Expression LoopHeads DEDENT ]'
        , -> Chain L 1 5 ($3.0.make-comprehension $2, $3.slice 1)
        o '{ [ ArgList OptComma ] LoopHeads }'
        , -> Chain L 1 7 ($6.0.add-obj-comp!.make-comprehension (L 3 Arr $3), $6.slice 1)

        o '( BIOP )'            -> Chain L 2 Binary $2
        o '( BIOP Expression )' -> Chain L 2 Binary $2, , $3
        o '( Expression BIOP )' -> Chain L 3 Binary $3,   $2

        o '( BIOPR )'
        , -> Chain L 2 if '!' is $2.char-at 0
                       then Binary $2.slice(1) .invert-it!
                       else Binary $2
        o '( BIOPR Expression )'
        , -> Chain L 2 if '!' is $2.char-at 0
                       then Binary $2.slice(1), , $3 .invert-it!
                       else Binary $2, , $3
        o '( Expression BIOPR )'
        , -> Chain L 3 if '!' is $3.char-at 0
                       then Binary $3.slice(1), $2 .invert-it!
                       else Binary $3, $2

        o '( BIOPBP )'                              -> Chain L 2 Binary $2
        o '( BIOPBP CALL( ArgList OptComma )CALL )' -> Chain L 2 Binary $2, , $4

        o '( BIOPP )'                                -> Chain L 2 Binary $2
        o '( PARAM( ArgList OptComma )PARAM BIOPP )' -> Chain L 6 Binary $6, $3

        o '( UNARY )'           -> Chain L 2 Unary $2
        o '( CREMENT )'         ditto

        o '( BACKTICK Chain BACKTICK )'            -> Chain $3
        o '( Expression BACKTICK Chain BACKTICK )' -> Chain L 2 5 $4.add L 2 Call [$2]
        o '( BACKTICK Chain BACKTICK Expression )'
        , -> Chain(L 3 Chain Var 'flip$' .add L 3 Call [$3]).flip-it!.add L 5 Call [$5]

        o '[ Expression TO Expression ]'
        , -> Chain L 2 4 new For from: $2, op: $3, to: $4, in-comprehension: true
        o '[ Expression TO Expression BY Expression ]'
        , -> Chain L 2 6 new For from: $2, op: $3, to: $4, step: $6, in-comprehension: true
        o '[ FROM Expression TO Expression ]'
        , -> Chain L 2 5 new For from: $3, op: $4, to: $5, in-comprehension: true
        o '[ FROM Expression TO Expression BY Expression ]'
        , -> Chain L 2 7 new For from: $3, op: $4, to: $5, step: $7, in-comprehension: true
        o '[ TO Expression ]'
        , -> Chain L 2 3 new For from: (Chain Literal 0), op: $2, to: $3, in-comprehension: true
        o '[ TO Expression BY Expression ]'
        , -> Chain L 2 5 new For from: (Chain Literal 0), op: $2, to: $3, step: $5, in-comprehension: true

        o 'Chain DOT [ Expression TO Expression BY Expression ]'
        , -> Chain L 1 9 new StepSlice op: $5, target: $1, from: $4, to: $6, step: $8
        o 'Chain DOT [ TO Expression BY Expression ]'
        , -> Chain L 1 8 new StepSlice op: $4, target: $1, from: (Literal 0), to: $5, step: $7
        o 'Chain DOT [ Expression TO Expression ]'
        , -> Chain L 1 7 Slice type: $5, target: $1, from: $4, to: $6
        o 'Chain DOT [ Expression TO ]'
        , -> Chain L 1 6 Slice type: $5, target: $1, from: $4
        o 'Chain DOT [ TO Expression ]'
        , -> Chain L 1 6 Slice type: $4, target: $1, to: $5
        o 'Chain DOT [ TO ]'
        , -> Chain L 1 5 Slice type: $4, target: $1

        o 'WITH Expression Block'
        , -> Chain L 1 2 Cascade $2, $3, 'with'

        # Normal loops have a block of expressions to execute and an optional
        # `else` clause.
        #
        # The grammar won't permit loop forms that end in Expression to be
        # productions in Chain, so those other loops are in Expression.
        o 'LoopHead Block Else' -> Chain($1.add-body $2 .add-else $3)

    KeyLike:
        o 'STRNUM' -> Literal $1
        o 'Parenthetical'

    Index:
        o 'DOT ID'      -> Index (L 2 Key $2), $1, true
        o 'DOT KeyLike' -> Index           $2, $1, true
        o 'DOT List'    ditto

    # An array or object
    List:
        o '[ ArgList    OptComma ]' -> Arr $2
        o '{ Properties OptComma }' -> Obj $2
      # can be labeled to perform named destructuring.
        o '[ ArgList    OptComma ] LABEL' -> Arr $2 .named $5
        o '{ Properties OptComma } LABEL' -> Obj $2 .named $5

    # **ArgList** is either the list of objects passed into a function call,
    # the parameter list of a function, or the contents of an array literal
    # (i.e. comma-separated expressions). Newlines work as well.
    ArgList:
        o ''                                                -> []
        o 'Arg'                                             -> [$1]
        o 'ArgList , Arg'                                   -> $1 ++ $3
        o 'ArgList OptComma NEWLINE Arg'                    -> $1 ++ $4
        o 'ArgList OptComma INDENT ArgList OptComma DEDENT' ditto
    Arg:
        o     'Expression'
        o '... Expression' -> Splat $2
        o '...'            -> Splat (L 1, Arr!), true

    # An optional, trailing comma.
    OptComma:
        o ''
        o ','

    # A list of lines, separated by newlines or semicolons.
    Lines:
        o ''                   -> Block!
        o 'Line'               -> Block $1
        o 'Lines NEWLINE Line' -> $1.add $3
        o 'Lines NEWLINE'

    Line:
        o 'Expression'

        # Cascade without `with`
        o 'Expression Block' -> Cascade $1, $2, 'cascade'

        o 'PARAM( ArgList OptComma )PARAM <- Expression'
        , -> Call.back $2, $6, /~/.test($5), /--|~~/.test($5), /!/.test($5), /\*/.test($5)

        o 'COMMENT' -> JS $1, true true

        # [yadayadayada](http://search.cpan.org/~tmtm/Yada-Yada-Yada-1.00/Yada.pm)
        o '...' -> Throw L 1 JS "Error('unimplemented')"

        o 'REQUIRE Chain'   -> Require $2.unwrap!

    # An indented block of expressions.
    # Note that [Lexer](#lexer) rewrites some single-line forms into blocks.
    Block:
        o 'INDENT Lines DEDENT' -> $2
        ...

    SplatChain:
        o '... Chain' -> Splat $2.unwrap!
        ...

    # All the different types of expressions in our language.
    Expression:
        o 'Chain CLONEPORT Expression'
        , -> Import (L 1 2 Unary '^^' $1, prec: 'UNARY'), $3,         false
        o 'Chain CLONEPORT Block'
        , -> Import (L 1 2 Unary '^^' $1, prec: 'UNARY'), $3.unwrap!, false

        o 'Expression BACKTICK Chain BACKTICK Expression' -> $3.add L 1 5 Call [$1, $5]

        o 'Chain' -> $1.unwrap!

        o 'Chain ASSIGN Expression'
        , -> Assign $1.unwrap!, $3           , L 2 Box $2
        o 'SplatChain ASSIGN Expression'
        , -> Assign $1, $3                   , L 2 Box $2
        o 'Chain ASSIGN INDENT ArgList OptComma DEDENT'
        , -> Assign $1.unwrap!, Arr.maybe($4), L 2 Box $2

        o 'Expression IMPORT Expression'
        , -> Import $1, $3           , $2 is '<<<<'
        o 'Expression IMPORT INDENT ArgList OptComma DEDENT'
        , -> Import $1, Arr.maybe($4), $2 is '<<<<'

        o 'CREMENT Chain' -> Unary $1, $2.unwrap!
        o 'Chain CREMENT' -> Unary $2, $1.unwrap!, true
        o 'CREMENT ... Chain' -> Unary $1, Splat $3.unwrap!
        o 'SplatChain CREMENT' -> Unary $2, $1, true

        o 'UNARY ASSIGN     Chain' -> Assign $3.unwrap!, [$1] L 2 Box $2
        o '+-    ASSIGN     Chain' ditto
        o 'CLONE ASSIGN     Chain' ditto
        o 'UNARY ASSIGN ... Chain' -> Assign Splat($4.unwrap!), [$1] L 2 Box $2
        o '+-    ASSIGN ... Chain' ditto
        o 'CLONE ASSIGN ... Chain' ditto

        o 'UNARY     Expression' -> Unary $1, $2
        o '+-        Expression' ditto, prec: 'UNARY'
        o 'CLONE     Expression' ditto, prec: 'UNARY'
        o 'UNARY ... Expression' -> Unary $1, Splat $3
        o '+-    ... Expression' ditto, prec: 'UNARY'
        o 'CLONE ... Expression' ditto, prec: 'UNARY'
        o 'UNARY ... INDENT ArgList OptComma DEDENT' -> Unary $1, Splat Arr $4

        o 'UNARY INDENT ArgList OptComma DEDENT' -> Unary $1, Arr.maybe $3

        o 'YIELD' -> Yield $1
        o 'YIELD Expression' -> Yield $1, $2

        o 'Expression +-      Expression' -> L 2 Binary $2, $1, $3
        o 'Expression COMPARE Expression' ditto
        o 'Expression LOGIC   Expression' ditto
        o 'Expression MATH    Expression' ditto
        o 'Expression POWER   Expression' ditto
        o 'Expression SHIFT   Expression' ditto
        o 'Expression BITWISE Expression' ditto
        o 'Expression CONCAT  Expression' ditto
        o 'Expression COMPOSE Expression' ditto

        # the `*if` is required for the proper compilation for use with the dsl
        o 'Expression RELATION Expression' ->
          *if '!' is $2.char-at 0 then Binary $2.slice(1), $1, $3 .invert!
                                  else Binary $2         , $1, $3

        o 'Expression PIPE     Expression' -> Block $1 .pipe $3, $2
        o 'Expression BACKPIPE Expression' -> Block $1 .pipe [$3], $2

        o 'Chain !?' -> Existence $1.unwrap!, true

        # The function literal can be either anonymous with `->`,
        o 'PARAM( ArgList OptComma )PARAM -> Block'
        , -> Fun $2, $6, /~/.test($5), /--|~~/.test($5), /!/.test($5), /\*/.test($5), />>/.test($5)
        # or named with `function`.
        o 'FUNCTION CALL( ArgList OptComma )CALL Block' -> (Fun $3, $6).named $1
        o 'GENERATOR CALL( ArgList OptComma )CALL Block'
        , -> (Fun $3, $6, false, false, false, true, false).named $1
        o 'ASYNC FUNCTION CALL( ArgList OptComma )CALL Block'
        , -> (Fun $4, $7, false, false, false, false, true).named $2

        # The full complement of `if` and `unless` expressions
        o 'IF Expression Block Else'      -> L 1 2 If $2, $3, $1 is 'unless' .add-else $4
        # and their postfix forms.
        o 'Expression POST_IF Expression' -> L 2 3 If $3, $1, $2 is 'unless'

        # In addition to the LoopHead-based forms in Chain, here are a few more loops:
        # postfix with a single expression,
        o 'DO Block WHILE Expression'
        , -> new While($4, $3 is 'until', true).add-body $2
        # with a guard
        o 'DO Block WHILE Expression CASE Expression'
        , -> new While($4, $3 is 'until', true).add-guard $6 .add-body $2

        # `return` or `throw`.
        o 'HURL Expression'                     -> Jump[$1] $2
        o 'HURL INDENT ArgList OptComma DEDENT' -> Jump[$1] Arr.maybe $3
        o 'HURL'                                -> Jump[$1]!

        # `break` or `continue`.
        o 'JUMP'     -> new Jump $1
        o 'JUMP ID' -> new Jump $1, $2

        o 'SWITCH Exprs Cases'               -> new Switch $1, $2, $3
        o 'SWITCH Exprs Cases DEFAULT Block' -> new Switch $1, $2, $3, $5
        o 'SWITCH Exprs Cases ELSE    Block' -> new Switch $1, $2, $3, $5
        o 'SWITCH       Cases'               -> new Switch $1, null $2
        o 'SWITCH       Cases DEFAULT Block' -> new Switch $1, null $2, $4
        o 'SWITCH       Cases ELSE    Block' -> new Switch $1, null $2, $4
        o 'SWITCH                     Block' -> new Switch $1, null [], $2

        o 'TRY Block'                               -> new Try $2
        o 'TRY Block CATCH Block'                   -> new Try $2, , (L 3 $4)
        o 'TRY Block CATCH Block     FINALLY Block' -> new Try $2, , (L 3 $4), (L 5 $6)
        o 'TRY Block CATCH Arg Block'               -> new Try $2, $4, (L 3 4 $5)
        o 'TRY Block CATCH Arg Block FINALLY Block' -> new Try $2, $4, (L 3 4 $5), (L 6 $7)
        o 'TRY Block                 FINALLY Block' -> new Try $2, , , (L 3 $4)

        o 'CLASS Chain OptExtends OptImplements Block'
        , -> new Class title: $2.unwrap!, sup: $3, mixins: $4, body: $5
        o 'CLASS       OptExtends OptImplements Block'
        , -> new Class                    sup: $2, mixins: $3, body: $4

        o 'Chain EXTENDS Expression' -> Util.Extends $1.unwrap!, $3

        o 'LABEL Expression' -> new Label $1, $2
        o 'LABEL Block'      ditto

        # `var`, `const`, `export`, or `import`
        o 'DECL INDENT ArgList OptComma DEDENT' -> Decl $1, $3, yylineno+1

    Exprs:
        o         'Expression' -> [$1]
        o 'Exprs , Expression' -> $1 ++ $3

    KeyColon:
        o 'ID :' -> Key $1
        o 'KeyLike :' -> $1

    # The various forms of property.
    Property:
        o 'KeyColon Expression'                     -> Prop $1, $2
        o 'KeyColon INDENT ArgList OptComma DEDENT' -> Prop $1, Arr.maybe($3)

        o 'Expression' -> Prop null $1
        o '... Expression' -> Prop Splat!, $2

        o 'COMMENT' -> JS $1, true true
    # Properties within an object literal can be separated by
    # commas, as in JavaScript, or simply by newlines.
    Properties:
        o ''                                     -> []
        o 'Property'                             -> [$1]
        o 'Properties , Property'                -> $1 ++ $3
        o 'Properties OptComma NEWLINE Property' -> $1 ++ $4
        o 'INDENT Properties OptComma DEDENT'    -> $2

    Parenthetical:
        o '( Body )' -> Parens $2.chomp!.unwrap!, false, $1 is '"', (L 1 {}), (L 3 {})
        ...

    Body:
        o 'Lines'
        o 'Block'
        o 'Block NEWLINE Lines' -> $1.add $3

    Else:
        o ''                              -> null
        o 'ELSE Block'                    -> $2
        o 'ELSE IF Expression Block Else' -> If $3, $4, $2 is 'unless' .add-else $5

    LoopHead:
        # The source of a `for`-loop is an array, object, or range.
        # Unless it's iterating over an object, you can choose to step through
        # in fixed-size increments.
        o 'FOR Chain IN Expression'
        , -> new For kind: $1, item: $2.unwrap!, index: $3, source: $4
        o 'FOR Chain IN Expression CASE Expression'
        , -> new For kind: $1, item: $2.unwrap!, index: $3, source: $4, guard: $6
        o 'FOR Chain IN Expression BY Expression'
        , -> new For kind: $1, item: $2.unwrap!, index: $3, source: $4, step: $6
        o 'FOR Chain IN Expression BY Expression CASE Expression'
        , -> new For kind: $1, item: $2.unwrap!, index: $3, source: $4, step: $6, guard: $8

        o 'FOR Expression'
        , -> new For kind: $1, source: $2, ref: true
        o 'FOR Expression CASE Expression'
        , -> new For kind: $1, source: $2, ref: true, guard: $4
        o 'FOR Expression BY Expression'
        , -> new For kind: $1, source: $2, ref: true, step: $4
        o 'FOR Expression BY Expression CASE Expression'
        , -> new For kind: $1, source: $2, ref: true, step: $4, guard: $6

        o 'FOR     ID         OF Expression'
        , -> new For {+object, kind: $1, index: $2,                   source: $4}
        o 'FOR     ID         OF Expression CASE Expression'
        , -> new For {+object, kind: $1, index: $2,                   source: $4, guard: $6}
        o 'FOR     ID , Chain OF Expression'
        , -> new For {+object, kind: $1, index: $2, item: $4.unwrap!, source: $6}
        o 'FOR     ID , Chain OF Expression CASE Expression'
        , -> new For {+object, kind: $1, index: $2, item: $4.unwrap!, source: $6, guard: $8}

        o 'FOR ID FROM Expression TO Expression'
        , -> new For kind: $1, index: $2, from: $4, op: $5, to: $6
        o 'FOR FROM Expression TO Expression'
        , -> new For kind: $1,            from: $3, op: $4, to: $5, ref: true
        o 'FOR ID FROM Expression TO Expression CASE Expression'
        , -> new For kind: $1, index: $2, from: $4, op: $5, to: $6, guard: $8
        o 'FOR FROM Expression TO Expression CASE Expression'
        , -> new For kind: $1,            from: $3, op: $4, to: $5, guard: $7, ref: true
        o 'FOR ID FROM Expression TO Expression BY Expression'
        , -> new For kind: $1, index: $2, from: $4, op: $5, to: $6, step: $8
        o 'FOR FROM Expression TO Expression BY Expression'
        , -> new For kind: $1,            from: $3, op: $4, to: $5, step: $7, ref: true
        o 'FOR ID FROM Expression TO Expression BY Expression CASE Expression'
        , -> new For kind: $1, index: $2, from: $4, op: $5, to: $6, step: $8, guard: $10
        o 'FOR FROM Expression TO Expression BY Expression CASE Expression'
        , -> new For kind: $1,            from: $3, op: $4, to: $5, step: $7, guard: $9, ref: true
        o 'FOR ID FROM Expression TO Expression CASE Expression BY Expression'
        , -> new For kind: $1, index: $2, from: $4, op: $5, to: $6, guard: $8, step: $10
        o 'FOR FROM Expression TO Expression CASE Expression BY Expression'
        , -> new For kind: $1,            from: $3, op: $4, to: $5, guard: $7, step: $9, ref: true

        o 'WHILE Expression'                 -> new While $2, $1 is 'until'
        o 'WHILE Expression CASE Expression' -> new While $2, $1 is 'until' .add-guard $4
        o 'WHILE Expression , Expression'    -> new While $2, $1 is 'until', $4
        o 'WHILE Expression , Expression CASE Expression'
        , -> new While $2, $1 is 'until', $4 .add-guard $6

    LoopHeads:
        o 'LoopHead'           -> [$1]
        o 'LoopHeads LoopHead' -> $1 ++ $2
        o 'LoopHeads NEWLINE LoopHead' -> $1 ++ $3
        o 'LoopHeads INDENT LoopHead'  -> $1 ++ $3

    Cases:
        o       'CASE Exprs Block' -> [L 1 2 new Case $2, $3]
        o 'Cases CASE Exprs Block' -> $1 ++ L 2 3 new Case $3, $4

    OptExtends:
        o 'EXTENDS Expression' -> $2
        o ''                   -> null

    OptImplements:
        o 'IMPLEMENTS Exprs' -> $2
        o ''                 -> null

# Precedence and Associativity
# ----------------------------
# Following these rules is what makes
# `a + b * c` parse as `a + (b * c)` (rather than `(a + b) * c`),
# and `x = y = z` `x = (y = z)` (not `(x = y) = z`).
operators =
    # Listed from lower precedence.
    <[ left     POST_IF      ]>
    <[ right    ASSIGN HURL  ]>
    <[ right    YIELD        ]>
    <[ right    BACKPIPE     ]>
    <[ left     PIPE         ]>
    <[ right    , FOR WHILE EXTENDS INDENT SWITCH CASE TO BY LABEL ]>
    <[ right    LOGIC        ]>
    <[ left     BITWISE      ]>
    <[ right    COMPARE      ]>
    <[ left     RELATION     ]>
    <[ right    CONCAT       ]>
    <[ left     SHIFT IMPORT CLONEPORT ]>
    <[ left     +-           ]>
    <[ left     MATH         ]>
    <[ right    UNARY        ]>
    <[ right    POWER        ]>
    <[ right    COMPOSE      ]>
    <[ nonassoc CREMENT      ]>
    <[ nonassoc ...          ]>
    <[ left     BACKTICK     ]>

# Wrapping Up
# -----------

# Process all of our rules and prepend resolutions, while recording all
# terminals (every symbol which does not appear as the name of a rule above)
# as `tokens`.
tokens = do
    for name, alts of bnf
        for alt in alts
            [token for token in alt.0 when token not of bnf]
.join ' '

bnf.Root = [[['Body'] 'return $$']]

# Finally, initialize the parser with the name of the root.
module.exports =
    new (require 'jison').Parser {bnf, operators, tokens, start-symbol: 'Root'}
