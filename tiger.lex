type pos = int
type lexresult = Tokens.token

val lineNum = ErrorMsg.lineNum
val linePos = ErrorMsg.linePos
fun err(p1,p2) = ErrorMsg.error p1

val nested_comments = ref 0

val current_text = ref ""
val text_start = ref 0

fun eof() = let val pos = hd(!linePos) 
            in
                if !nested_comments <> 0
                then (ErrorMsg.error pos "unclosed comment detected")
                else ();
                Tokens.EOF(pos,pos) 
            end

%%
alpha=[A-Za-z];
digit = [0-9];
ws = [\ \t];

%s COMMENT STRING;

%%
<INITIAL>type        => (Tokens.TYPE(yypos,yypos+4));
<INITIAL>var         => (Tokens.VAR(yypos,yypos+3));
<INITIAL>function    => (Tokens.FUNCTION(yypos,yypos+8));
<INITIAL>break       => (Tokens.BREAK(yypos, yypos+5));
<INITIAL>of          => (Tokens.OF(yypos, yypos+2));
<INITIAL>end         => (Tokens.END(yypos, yypos+3));
<INITIAL>in          => (Tokens.IN(yypos, yypos+2));
<INITIAL>nil         => (Tokens.NIL(yypos, yypos+3));
<INITIAL>let         => (Tokens.LET(yypos,yypos+3));
<INITIAL>do          => (Tokens.DO(yypos, yypos+2));
<INITIAL>to          => (Tokens.TO(yypos, yypos+2));
<INITIAL>for         => (Tokens.FOR(yypos, yypos+3));
<INITIAL>while       => (Tokens.WHILE(yypos, yypos+5));
<INITIAL>else        => (Tokens.ELSE(yypos, yypos+4));
<INITIAL>then        => (Tokens.THEN(yypos, yypos+4));
<INITIAL>if          => (Tokens.IF(yypos, yypos+2));
<INITIAL>array       => (Tokens.ARRAY(yypos, yypos+5));

<INITIAL>":="        => (Tokens.ASSIGN(yypos, yypos+2));

<INITIAL>"|"         => (Tokens.OR(yypos, yypos+1));
<INITIAL>"&"         => (Tokens.AND(yypos, yypos+1));

<INITIAL>">="        => (Tokens.GE(yypos, yypos+2));
<INITIAL>">"         => (Tokens.GT(yypos, yypos+1));
<INITIAL>"<="        => (Tokens.LE(yypos, yypos+2));
<INITIAL>"<"         => (Tokens.LT(yypos, yypos+1));
<INITIAL>"!="        => (Tokens.NEQ(yypos, yypos+2));
<INITIAL>"="         => (Tokens.EQ(yypos, yypos+1));

<INITIAL>"/"         => (Tokens.DIVIDE(yypos, yypos+1));
<INITIAL>"*"         => (Tokens.TIMES(yypos, yypos+1));
<INITIAL>"-"         => (Tokens.MINUS(yypos, yypos+1));
<INITIAL>"+"         => (Tokens.PLUS(yypos, yypos+1));

<INITIAL>"."         => (Tokens.DOT(yypos, yypos+1));
<INITIAL>"}"         => (Tokens.RBRACE(yypos, yypos+1));
<INITIAL>"{"         => (Tokens.LBRACE(yypos, yypos+1));
<INITIAL>"]"         => (Tokens.RBRACK(yypos, yypos+1));
<INITIAL>"["         => (Tokens.LBRACK(yypos, yypos+1));
<INITIAL>")"         => (Tokens.RPAREN(yypos, yypos+1));
<INITIAL>"("         => (Tokens.LPAREN(yypos, yypos+1));
<INITIAL>";"         => (Tokens.SEMICOLON(yypos, yypos+1));
<INITIAL>":"         => (Tokens.COLON(yypos, yypos+1));
<INITIAL>","         => (Tokens.COMMA(yypos, yypos+1));

<INITIAL>[a-zA-Z][a-zA-Z0-9_]*   => (Tokens.ID(yytext, yypos, yypos + (size yytext)));

<INITIAL>[0-9]+    => (Tokens.INT(yytext, yypos, yypos + (size yytext)));

<INITIAL,COMMENT>(\n)|(\r\n)      => (lineNum := !lineNum+1; linePos := yypos :: !linePos; continue());
<INITIAL>[\ \t]  => ( continue() );

<INITIAL>\"             => (YYBEGIN STRING; current_text := ""; text_start := yypos; continue());
<STRING>\\n             => (current_text := !current_text ^ "\n"; continue());
<STRING>\\t             => (current_text := !current_text ^ "\t"; continue());
<STRING>\\b             => (current_text := !current_text ^ "\b"; continue());
<STRING>\\f             => (current_text := !current_text ^ "\f"; continue());
<STRING>\\\"            => (current_text := !current_text ^ "\""; continue());
<STRING>\\\\            => (current_text := !current_text ^ "\\"; continue());
<STRING>\\              => (ErrorMsg.error yypos ("illegal character " ^ yytext); continue());
<STRING>\"              => (YYBEGIN INITIAL; 
                            Tokens.STRING(!current_text, !text_start, !text_start + (size (!current_text))));

<STRING>(\n)|(\r\n)     => (lineNum := !lineNum+1; 
                            linePos := yypos :: !linePos; 
                            ErrorMsg.error yypos ("Illegal new line inside of string"); 
                            YYBEGIN INITIAL; 
                            continue());

<STRING>.               => (current_text := !current_text ^ yytext; continue());

<INITIAL,COMMENT>"/*"           => (YYBEGIN COMMENT; nested_comments := !nested_comments+1; continue());
<COMMENT>"*/"           => (nested_comments := !nested_comments-1; 
                            if !nested_comments = 0 
                            then ( YYBEGIN INITIAL; continue() )
                            else ( continue() ));
<COMMENT>.      => (continue());

<INITIAL>.       => (ErrorMsg.error yypos ("illegal character " ^ yytext); continue());
