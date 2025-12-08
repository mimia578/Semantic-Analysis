%option noyywrap

%{

#include"symbol_info.h"

#define YYSTYPE symbol_info*

#include "y.tab.h"

extern YYSTYPE yylval;

void yyerror(char *);

extern int lines;
extern ofstream outlog;

%}

delim	 [ \t\v\r\f]
newline  \r?\n
ws		 {delim}+
letter_	 [A-Za-z_]
digit	 [0-9]
id		 {letter_}({letter_}|{digit})*
integers {digit}+
floats	 {digit}*(\.{digit}+)|{digit}*(\.{digit}+)?((E|e)[-]?{digit}+)

%%

{ws}		{ /* ignore whitespace */ }
{newline}	{ lines++; }

if          { 
                outlog << "Line no " << lines << ": Token <IF> Lexeme " << yytext << " found" << endl << endl;
                return IF; 
            }
else		{ 
                outlog << "Line no " << lines << ": Token <ELSE> Lexeme " << yytext << " found" << endl << endl;
                return ELSE; 
            }
for         { 
                outlog << "Line no " << lines << ": Token <FOR> Lexeme " << yytext << " found" << endl << endl;
                return FOR; 
            }
while       { 
                outlog << "Line no " << lines << ": Token <WHILE> Lexeme " << yytext << " found" << endl << endl;
                return WHILE; 
            }
do          { 
                outlog << "Line no " << lines << ": Token <DO> Lexeme " << yytext << " found" << endl << endl;
                return DO; 
            }
break       { 
                outlog << "Line no " << lines << ": Token <BREAK> Lexeme " << yytext << " found" << endl << endl;
                return BREAK; 
            }
continue    { 
                outlog << "Line no " << lines << ": Token <CONTINUE> Lexeme " << yytext << " found" << endl << endl;
                return CONTINUE; 
            }
return      { 
                outlog << "Line no " << lines << ": Token <RETURN> Lexeme " << yytext << " found" << endl << endl;
                return RETURN; 
            }
int         { 
                outlog << "Line no " << lines << ": Token <INT> Lexeme " << yytext << " found" << endl << endl;
                return INT; 
            }
float       { 
                outlog << "Line no " << lines << ": Token <FLOAT> Lexeme " << yytext << " found" << endl << endl;
                return FLOAT; 
            }
char        { 
                outlog << "Line no " << lines << ": Token <CHAR> Lexeme " << yytext << " found" << endl << endl;
                return CHAR; 
            }
void        { 
                outlog << "Line no " << lines << ": Token <VOID> Lexeme " << yytext << " found" << endl << endl;
                return VOID; 
            }
double      { 
                outlog << "Line no " << lines << ": Token <DOUBLE> Lexeme " << yytext << " found" << endl << endl;
                return DOUBLE; 
            }
switch      { 
                outlog << "Line no " << lines << ": Token <SWITCH> Lexeme " << yytext << " found" << endl << endl;
                return SWITCH; 
            }
case        { 
                outlog << "Line no " << lines << ": Token <CASE> Lexeme " << yytext << " found" << endl << endl;
                return CASE; 
            }
default     { 
                outlog << "Line no " << lines << ": Token <DEFAULT> Lexeme " << yytext << " found" << endl << endl;
                return DEFAULT; 
            }
printf      { 
                outlog << "Line no " << lines << ": Token <PRINTLN> Lexeme " << yytext << " found" << endl << endl;
                return PRINTLN; 
            }

"+"|"-"	    {
                outlog << "Line no " << lines << ": Token <ADDOP> Lexeme " << yytext << " found" << endl << endl;
                symbol_info *s = new symbol_info((string)yytext,"ADDOP");
                yylval = (YYSTYPE)s;
                return ADDOP;
		    }
"*"|"/"|"%"    {
                outlog << "Line no " << lines << ": Token <MULOP> Lexeme " << yytext << " found" << endl << endl;
                symbol_info *s = new symbol_info((string)yytext,"MULOP");
                yylval = (YYSTYPE)s;
                return MULOP;
            }
"++"        { 
                outlog << "Line no " << lines << ": Token <INCOP> Lexeme " << yytext << " found" << endl << endl;
                return INCOP; 
            }
"--"        { 
                outlog << "Line no " << lines << ": Token <DECOP> Lexeme " << yytext << " found" << endl << endl;
                return DECOP; 
            }
"<"|">"|"<="|">="|"=="|"!=" {
                outlog << "Line no " << lines << ": Token <RELOP> Lexeme " << yytext << " found" << endl << endl;
                symbol_info *s = new symbol_info((string)yytext,"RELOP");
                yylval = (YYSTYPE)s;
                return RELOP;
            }

"="         { 
                outlog << "Line no " << lines << ": Token <ASSIGNOP> Lexeme " << yytext << " found" << endl << endl;
                return ASSIGNOP; 
            }
"&&"|"||"   {
                outlog << "Line no " << lines << ": Token <LOGICOP> Lexeme " << yytext << " found" << endl << endl;
		   	    symbol_info *s = new symbol_info((string)yytext,"LOGICOP");
			    yylval = (YYSTYPE)s;
			    return LOGICOP;
		    }

"!"        { 
                outlog << "Line no " << lines << ": Token <NOT> Lexeme " << yytext << " found" << endl << endl;
                return NOT; 
            }
"("        { 
                outlog << "Line no " << lines << ": Token <LPAREN> Lexeme " << yytext << " found" << endl << endl;
                return LPAREN; 
            }
")"        { 
                outlog << "Line no " << lines << ": Token <RPAREN> Lexeme " << yytext << " found" << endl << endl;
                return RPAREN; 
            }
"{"        { 
                outlog << "Line no " << lines << ": Token <LCURL> Lexeme " << yytext << " found" << endl << endl;
                return LCURL; 
            }
"}"        { 
                outlog << "Line no " << lines << ": Token <RCURL> Lexeme " << yytext << " found" << endl << endl;
                return RCURL; 
            }
"["        { 
                outlog << "Line no " << lines << ": Token <LTHIRD> Lexeme " << yytext << " found" << endl << endl;
                return LTHIRD; 
            }
"]"        { 
                outlog << "Line no " << lines << ": Token <RTHIRD> Lexeme " << yytext << " found" << endl << endl;
                return RTHIRD; 
            }
";"        { 
                outlog << "Line no " << lines << ": Token <SEMICOLON> Lexeme " << yytext << " found" << endl << endl;
                return SEMICOLON; 
            }
","        { 
                outlog << "Line no " << lines << ": Token <COMMA> Lexeme " << yytext << " found" << endl << endl;
                return COMMA; 
            }

{id}       {
                outlog << "Line no " << lines << ": Token <ID> Lexeme " << yytext << " found" << endl << endl;
                symbol_info *s = new symbol_info((string)yytext,"ID");
                yylval = (YYSTYPE)s;
                return ID;
            }
{integers} {
                outlog << "Line no " << lines << ": Token <CONST_INT> Lexeme " << yytext << " found" << endl << endl;
                symbol_info *s = new symbol_info((string)yytext,"INT");
                yylval = (YYSTYPE)s;
                return CONST_INT;
            }
{floats}   {
                outlog << "Line no " << lines << ": Token <CONST_FLOAT> Lexeme " << yytext << " found" << endl << endl;
                symbol_info *s = new symbol_info((string)yytext,"FLOAT");
                yylval = (YYSTYPE)s;
                return CONST_FLOAT;
            }

%%