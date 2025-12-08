%{

#include "symbol_table.h"
#include <cstring>

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table *table;

string current_type;
string current_func_name;
vector<pair<string, string> > current_func_params;

int lines = 1;
ofstream outlog;
ofstream errlog;
int error_count = 0;

void yyerror(const char *s)
{
    outlog << "Error at line " << lines << ": " << s << endl << endl;
}

bool is_function_declared(string name) {
    symbol_info* temp = new symbol_info(name, "ID");
    symbol_info* found = table->lookup(temp);
    delete temp;
    return found != NULL && found->get_symbol_type() == "function";
}

bool is_variable_declared_current_scope(string name) {
    symbol_info* temp = new symbol_info(name, "ID");
    symbol_info* found = table->lookup(temp);
    delete temp;
    return found != NULL;
}

symbol_info* get_variable_info(string name) {
	symbol_info* temp = new symbol_info(name, "ID");
	symbol_info* found = table->lookup(temp);
	delete temp;
	return found;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog << "At line no: " << lines << " start : program " << endl << endl;
		table->print_all_scopes();
	}
	;

program : program unit
	{
		outlog << "At line no: " << lines << " program : program unit " << endl << endl;
		outlog << $1->getname() + "\n" + $2->getname() << endl << endl;
		$$ = new symbol_info($1->getname() + "\n" + $2->getname(), "program");
	}
	| unit
	{
		outlog << "At line no: " << lines << " program : unit " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "program");
	}
	;

unit : var_declaration
	 {
		outlog << "At line no: " << lines << " unit : var_declaration " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "unit");
	 }
     | func_definition
     {
		outlog << "At line no: " << lines << " unit : func_definition " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "unit");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {
			if(!is_function_declared($2->getname()) && !is_variable_declared_current_scope($2->getname())) {
				vector<pair<string, string> > params = current_func_params;
				current_func_name= $2->getname();
				symbol_info* func = new symbol_info($2->getname(), "ID");
				func->set_symbol_type("function");
				func->set_return_type($1->getname());
				func->set_data_type($1->getname());
				for(auto p : params) {
					func->add_parameter(p.first, p.second);
				}
				table->insert(func);
			}else{
				outlog << "At line no: " << lines << ": Multiple declaration of function " << $2->getname() << endl << endl;
				errlog << "At line no: " << lines << ": Multiple declaration of function " << $2->getname() << endl << endl;
				error_count++;
			}
		} compound_statement
		{	
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << "(" + $4->getname() + ")\n" << $7->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $4->getname() + ")\n" + $7->getname(), "func_def");	
			current_func_params.clear();
		}
		| type_specifier ID LPAREN RPAREN {
			if(!is_function_declared($2->getname())) {
				symbol_info* func = new symbol_info($2->getname(), "ID");
				func->set_symbol_type("function");
				func->set_return_type($1->getname());
				func->set_data_type($1->getname());
				table->insert(func);
			}
		} compound_statement
		{
			outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << "()\n" << $6->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + " " + $2->getname() + "()\n" + $6->getname(), "func_def");	
		}
		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
			outlog << $1->getname() << "," << $3->getname() << " " << $4->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
			pair<string, string> param($3->getname(), $4->getname());
			if(!current_func_params.empty()) {
				for(auto param : current_func_params) {
					if(param.second==$4->getname()) {
						outlog << "At line no: " << lines << ": Multiple declaration of parameter " << $4->getname() << " in a parameter of " << current_func_name <<endl << endl;
						errlog << "At line no: " << lines << ": Multiple declaration of parameter " << $4->getname() << " in a parameter of " << current_func_name <<endl << endl;
						error_count++;
					}
				}
			}
			current_func_params.push_back(param);
		}
		| parameter_list COMMA type_specifier
		{
			outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier " << endl << endl;
			outlog << $1->getname() << "," << $3->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + "," + $3->getname(), "param_list");
			pair<string, string> param($3->getname(), "");
			current_func_params.push_back(param);
		}
 		| type_specifier ID
 		{
			outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
			pair<string, string> param($1->getname(), $2->getname());
			current_func_params.push_back(param);
		}
		| type_specifier
		{
			outlog << "At line no: " << lines << " parameter_list : type_specifier " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "param_list");
			pair<string, string> param($1->getname(), "");
			current_func_params.push_back(param);
		}
 		;

compound_statement : LCURL {
		table->enter_scope();
		if(!current_func_params.empty()) {
			for(auto param : current_func_params) {
				if(!param.second.empty()) {
					symbol_info* param_symbol = new symbol_info(param.second, "ID");
					param_symbol->set_symbol_type("variable");
					param_symbol->set_data_type(param.first);
					table->insert(param_symbol);
				}
			}
		}
	} statements RCURL
	{ 
		outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
		outlog << "{\n" + $3->getname() + "\n}" << endl << endl;
		table->print_current_scope();
		table->exit_scope();
		$$ = new symbol_info("{\n" + $3->getname() + "\n}", "comp_stmnt");
	}
	| LCURL {
		table->enter_scope();
		if(!current_func_params.empty()) {
			for(auto param : current_func_params) {
				if(!param.second.empty()) {
					symbol_info* param_symbol = new symbol_info(param.second, "ID");
					param_symbol->set_symbol_type("variable");
					param_symbol->set_data_type(param.first);
					table->insert(param_symbol);
				}
			}
		}
	} RCURL
	{
		outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
		outlog << "{\n}" << endl << endl;
		table->print_current_scope();
		table->exit_scope();
		$$ = new symbol_info("{\n}", "comp_stmnt");
	}
	;

var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
			outlog << $1->getname() << " " << $2->getname() << ";" << endl << endl;
			$$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_decl");
		 }
		 ;

type_specifier	: INT
		{
			outlog << "At line no: " << lines << " type_specifier : INT " << endl << endl;
			outlog << "int" << endl << endl;
			$$ = new symbol_info("int", "type_spec");
			current_type = "int";
		}
 		| FLOAT
		{
			outlog << "At line no: " << lines << " type_specifier : FLOAT " << endl << endl;
			outlog << "float" << endl << endl;
			$$ = new symbol_info("float", "type_spec");
			current_type = "float";
		}
 		| VOID
		{
			outlog << "At line no: " << lines << " type_specifier : VOID " << endl << endl;
			outlog << "void" << endl << endl;
			$$ = new symbol_info("void", "type_spec");
			current_type = "void";
		}
 		;

declaration_list : declaration_list COMMA ID
		  {
				outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
				outlog << $1->getname() << "," << $3->getname() << endl << endl;
				$$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");
				string var_name = $3->getname();
				if(is_variable_declared_current_scope(var_name)) {
					outlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					errlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					error_count++;
				} else {
					symbol_info* var_symbol = new symbol_info(var_name, "ID");
					var_symbol->set_symbol_type("variable");
					var_symbol->set_data_type(current_type);
					table->insert(var_symbol);
				}
		  }
		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		  {
				outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
				outlog << $1->getname() << "," << $3->getname() << "[" << $5->getname() << "]" << endl << endl;
				$$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");
				string var_name = $3->getname();
				if(is_variable_declared_current_scope(var_name)) {
					outlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					errlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					error_count++;
				} else {
					symbol_info* var_symbol = new symbol_info(var_name, "ID");
					var_symbol->set_symbol_type("array");
					var_symbol->set_data_type(current_type);
					var_symbol->set_array_size(stoi($5->getname()));
					table->insert(var_symbol);
				}
		  }
		  | ID
		  {
				outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
				outlog << $1->getname() << endl << endl;
				$$ = new symbol_info($1->getname(), "decl_list");
				string var_name = $1->getname();
				if(is_variable_declared_current_scope(var_name)) {
					outlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					errlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					error_count++;
				} else {
					symbol_info* var_symbol = new symbol_info(var_name, "ID");
					var_symbol->set_symbol_type("variable");
					var_symbol->set_data_type(current_type);
					table->insert(var_symbol);
				}
		  }
		  | ID LTHIRD CONST_INT RTHIRD
		  {
				outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
				outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
				$$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");
				string var_name = $1->getname();
				if(is_variable_declared_current_scope(var_name)) {
					outlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					errlog << "At line no: " << lines << ": Multiple declaration of variable " << var_name << endl << endl;
					error_count++;
				} else {
					symbol_info* var_symbol = new symbol_info(var_name, "ID");
					var_symbol->set_symbol_type("array");
					var_symbol->set_data_type(current_type);
					var_symbol->set_array_size(stoi($3->getname()));
					table->insert(var_symbol);
				}
		  }
		  ;

statements : statement
	   {
			outlog << "At line no: " << lines << " statements : statement " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "stmnts");
	   }
	   | statements statement
	   {
			outlog << "At line no: " << lines << " statements : statements statement " << endl << endl;
			outlog << $1->getname() << "\n" << $2->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + "\n" + $2->getname(), "stmnts");
	   }
	   ;

statement : var_declaration
	  {
			outlog << "At line no: " << lines << " statement : var_declaration " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "stmnt");
	  }
	  | expression_statement
	  {
			outlog << "At line no: " << lines << " statement : expression_statement " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "stmnt");
	  }
	  | compound_statement
	  {
			outlog << "At line no: " << lines << " statement : compound_statement " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
			outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement " << endl << endl;
			outlog << "for(" << $3->getname() << $4->getname() << $5->getname() << ")" << $7->getname() << endl << endl;
			$$ = new symbol_info("for(" + $3->getname() + $4->getname() + $5->getname() + ")" + $7->getname(), "stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
			outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement " << endl << endl;
			outlog << "if(" << $3->getname() << ")" << $5->getname() << endl << endl;
			$$ = new symbol_info("if(" + $3->getname() + ")" + $5->getname(), "stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
			outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement " << endl << endl;
			outlog << "if(" << $3->getname() << ")" << $5->getname() << "else\n" << $7->getname() << endl << endl;
			$$ = new symbol_info("if(" + $3->getname() + ")" + $5->getname() + "else\n" + $7->getname(), "stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
			outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement " << endl << endl;
			outlog << "while(" << $3->getname() << ")" << $5->getname() << endl << endl;
			$$ = new symbol_info("while(" + $3->getname() + ")" + $5->getname(), "stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
			outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON " << endl << endl;
			outlog << "printf(" << $3->getname() << ");" << endl << endl;
			$$ = new symbol_info("printf(" + $3->getname() + ");", "stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
			outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON " << endl << endl;
			outlog << "return " << $2->getname() << ";" << endl << endl;
			$$ = new symbol_info("return " + $2->getname() + ";", "stmnt");
	  }
	  ;

expression_statement : SEMICOLON
			{
				outlog << "At line no: " << lines << " expression_statement : SEMICOLON " << endl << endl;
				outlog << ";" << endl << endl;
				$$ = new symbol_info(";", "expr_stmnt");
			}			
			| expression SEMICOLON 
			{
				outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON " << endl << endl;
				outlog << $1->getname() << ";" << endl << endl;
				$$ = new symbol_info($1->getname() + ";", "expr_stmnt");
			}
			;

variable : ID
	  {
		outlog << "At line no: " << lines << " variable : ID " << endl << endl;
		outlog << $1->getname() << endl << endl;
		symbol_info *var_info = get_variable_info($1->getname());
		if (var_info == NULL) {
			outlog << "At line no: " << lines << " Undeclared variable " << $1->getname() << endl << endl;
			errlog << "At line no: " << lines << " Undeclared variable " << $1->getname() << endl << endl;
			error_count++;
			$$ = new symbol_info($1->getname(), "varbl");
		}
		else{
			$$ = new symbol_info($1->getname(), "varbl");
			$$->set_data_type(var_info->get_data_type());
		}
		if (var_info!=NULL && var_info->get_symbol_type() == "array"){
			outlog << "At line no: " << lines << " Variable is of array type: " << $1->getname()<< endl << endl;
			errlog << "At line no: " << lines << " Variable is of array type: " << $1->getname()<< endl << endl;
			error_count++;
		}
	  }
	  | ID LTHIRD expression RTHIRD
	  {
		outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
		outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
		symbol_info *var_info = get_variable_info($1->getname());
		$$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "varbl");
		$$->set_data_type(var_info? var_info->get_data_type() : "int");
		if (!var_info || var_info->get_symbol_type() != "array"){
			outlog << "At line no: " << lines << " " <<$1->getname() << " is not an array" << endl << endl;
			errlog << "At line no: " << lines << " " <<$1->getname() << " is not an array" << endl << endl;
			error_count++;
		}
		if ($3->get_data_type() == "float") {
			outlog << "At line no: " << lines << " Array index not an integer" << endl << endl;
			errlog << "At line no: " << lines << " Array index not an integer" << endl << endl;
			error_count++;
		}
	  }
	  ;

expression : logic_expression
	   {
			outlog << "At line no: " << lines << " expression : logic_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "expr");
			$$->set_data_type($1->get_data_type());
	   }
	   | variable ASSIGNOP logic_expression 
	   {
			outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression " << endl << endl;
			outlog << $1->getname() << "=" << $3->getname() << endl << endl;
			symbol_info *var_info = get_variable_info($1->getname());
			if (var_info != NULL && var_info->get_symbol_type() == "array") {
				outlog << "At line no: " << lines << " Array assignment error" << endl << endl;
				errlog << "At line no: " << lines << " Array assignment error" << endl << endl;
				error_count++;
			}
			if (var_info && var_info->get_data_type() == "int" && $3->get_data_type() == "float") {
				outlog << "At line no: " << lines << " Warning: possible loss of data in assignment of FLOAT to INT" << endl << endl;
			}
			if (var_info && $3->get_symbol_type() == "function") {
				if ($1->get_data_type() != $3->get_return_type()) {
					outlog << "At line no: " << lines << " Type mismatch in assignment " << endl << endl;
					errlog << "At line no: " << lines << " Type mismatch in assignment " << endl << endl;
					error_count++;
				}
			} else if (var_info && $1->get_data_type() != $3->get_data_type()) {
				outlog << "At line no: " << lines << " Warning: Assignment of " << $3->get_data_type()<<" value into variable of "<<$1->get_data_type()<<" type" << endl << endl;
				errlog << "At line no: " << lines << " Warning: Assignment of " << $3->get_data_type()<<" value into variable of "<<$1->get_data_type()<<" type" << endl << endl;
				error_count++;
			}
			$$ = new symbol_info($1->getname() + "=" + $3->getname(), "expr");
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog << "At line no: " << lines << " logic_expression : rel_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "lgc_expr");
			$$->set_data_type($1->get_data_type());
			if ($1->get_symbol_type() == "function"){
				$$->set_symbol_type("function");
				$$->set_return_type($1->get_return_type());
	     	}
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "lgc_expr");
			$$->set_data_type("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog << "At line no: " << lines << " rel_expression : simple_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "rel_expr");
			$$->set_data_type($1->get_data_type());
			if ($1->get_symbol_type() == "function"){
				$$->set_symbol_type("function");
				$$->set_return_type($1->get_return_type());
			}
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expr");
			$$->set_data_type("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog << "At line no: " << lines << " simple_expression : term " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "simp_expr");
			$$->set_data_type($1->get_data_type());
			if ($1->get_symbol_type() == "function"){
				$$->set_symbol_type("function");
				$$->set_return_type($1->get_return_type());
			}
	      	}
		  | simple_expression ADDOP term 
		  {
	    	outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simp_expr");
	      }
		  ;
					
term :	unary_expression
     {
	    	outlog << "At line no: " << lines << " term : unary_expression " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "term");
			$$->set_data_type($1->get_data_type());
			if ($1->get_symbol_type() == "function"){
				$$->set_symbol_type("function");
				$$->set_return_type($1->get_return_type());
			}
	 }
     |  term MULOP unary_expression
     {
	    	outlog << "At line no: " << lines << " term : term MULOP unary_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "operation");
			if ($2->getname() == "/" || $2->getname() == "%"){
				if ($3->getname()=="0" && $2->getname()=="/" ){
					outlog << "At line no: " << lines << " Division by 0" << endl << endl;
					errlog << "At line no: " << lines << " Division by 0 " << endl << endl;
					error_count++;
				}
				if ($3->getname()=="0" && $2->getname()=="%" ){
					outlog << "At line no: " << lines << " Modulus by 0" << endl << endl;
					errlog << "At line no: " << lines << " Modulus by 0 " << endl << endl;
					error_count++;
				}
				if ($2->getname() == "%"){
				if ($1->get_data_type()!="int" || $3->get_data_type()!="int" ){
					outlog << "At line no: " << lines << " Modulus operator on non integer type" << endl << endl;
					errlog << "At line no: " << lines << " Modulus operator on non integer type" << endl << endl;
					error_count++;
				}}
			}
			if ($3->get_symbol_type() == "function" && $3->get_return_type()=="void"){
				outlog << "At line no: " << lines << " operation on "<< $3->get_return_type()<<" type" << endl << endl;
				errlog << "At line no: " << lines << " operation on "<< $3->get_return_type()<<" type" << endl << endl;
				error_count++;
			}
	 }
     ;

unary_expression : ADDOP unary_expression
		 {
	    	outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression " << endl << endl;
			outlog << $1->getname() << $2->getname() << endl << endl;
			$$ = new symbol_info($1->getname() + $2->getname(), "operation");
			if ($2->get_symbol_type() == "function" && $2->get_return_type()=="void"){
				outlog << "At line no: " << lines << " operation on "<< $2->get_return_type()<<" type" << endl << endl;
				errlog << "At line no: " << lines << " operation on "<< $2->get_return_type()<<" type" << endl << endl;
				error_count++;
			}
	     }
		 | NOT unary_expression 
		 {
	    	outlog << "At line no: " << lines << " unary_expression : NOT unary_expression " << endl << endl;
			outlog << "!" << $2->getname() << endl << endl;
			$$ = new symbol_info("!" + $2->getname(), "un_expr");
	     }
		 | factor 
		 {
	    	outlog << "At line no: " << lines << " unary_expression : factor " << endl << endl;
			outlog << $1->getname() << endl << endl;
			$$ = new symbol_info($1->getname(), "un_expr");
			$$->set_data_type($1->get_data_type());
			if ($1->get_symbol_type() == "function"){
				$$->set_symbol_type("function");
				$$->set_return_type($1->get_return_type());
	     	}
		 }
		 ;

	
factor	: variable
    {
	    outlog << "At line no: " << lines << " factor : variable " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "fctr");
		$$->set_data_type($1->get_data_type()); 
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
		outlog << $1->getname() << "(" << $3->getname() << ")" << endl << endl;
		symbol_info* var_info = get_variable_info($1->getname());
		$$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "fctr");
		if (var_info==NULL){ 
			outlog << "At line no: " << lines << " Undeclared function " << $1->getname() << endl << endl;
			errlog << "At line no: " << lines << " Undeclared function " << $1->getname() << endl << endl;
			error_count++;
		}else if (var_info!=NULL && var_info->get_symbol_type() == "function"){
			$$->set_symbol_type("function");
			$$->set_return_type(var_info->get_return_type());
			$$->set_data_type(var_info->get_return_type());
			if (current_func_params.size()!=var_info->get_parameters().size()){
				outlog << "At line no: " << lines << " Inconsistencies in number of arguments in function call : " <<  $1->getname() << endl << endl;
				errlog << "At line no: " << lines << " Inconsistencies in number of arguments in function call : " <<  $1->getname() << endl << endl;
				error_count++;
			}
			else if(current_func_params.size()==var_info->get_parameters().size()){
				for (int i=0; i<current_func_params.size(); i++){
					symbol_info* v_info = get_variable_info(current_func_params[i].first);
					if (v_info!= NULL && v_info->get_symbol_type() != "array" ){
						if (current_func_params[i].second!=var_info->get_parameters()[i].first){
							outlog << "At line no: " << lines << " argument "<< i+1 << " type mismatch in function call : " <<  $1->getname() << endl << endl;
							errlog << "At line no: " << lines << " argument "<< i+1 << " type mismatch in function call : " <<  $1->getname() << endl << endl;
							error_count++;
						}
					}else if (v_info==NULL){
						if (current_func_params[i].second!=var_info->get_parameters()[i].first && current_func_params[i].second!="array"){
							outlog << "At line no: " << lines << " argument "<< i+1 << " type mismatch in function call : " <<  $1->getname() << endl << endl;
							errlog << "At line no: " << lines << " argument "<< i+1 << " type mismatch in function call : " <<  $1->getname() << endl << endl;
							error_count++;
						}
					}
				}
			}	
		}
		current_func_params.clear();
	}
	| LPAREN expression RPAREN
	{
	   	outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
		outlog << "(" << $2->getname() << ")" << endl << endl;
		$$ = new symbol_info("(" + $2->getname() + ")", "fctr");
	}
	| CONST_INT 
	{
	    outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "fctr");
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
		outlog << $1->getname() << endl << endl;
		$$ = new symbol_info($1->getname(), "fctr");
		$$->set_data_type("float");
	}
	| variable INCOP 
	{
	    outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
		outlog << $1->getname() << "++" << endl << endl;
		$$ = new symbol_info($1->getname() + "++", "fctr");
	}
	| variable DECOP
	{
	    outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
		outlog << $1->getname() << "--" << endl << endl;
		$$ = new symbol_info($1->getname() + "--", "fctr");
	}
	;
	
argument_list : arguments
			  {
					outlog << "At line no: " << lines << " argument_list : arguments " << endl << endl;
					outlog << $1->getname() << endl << endl;
					$$ = new symbol_info($1->getname(), "arg_list");
			  }
			  |
			  {
					outlog << "At line no: " << lines << " argument_list :  " << endl << endl;
					outlog << "" << endl << endl;
					$$ = new symbol_info("", "arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression " << endl << endl;
				outlog << $1->getname() << "," << $3->getname() << endl << endl;
				pair<string, string> param($3->getname(), $3->get_data_type());
				current_func_params.push_back(param);
				$$ = new symbol_info($1->getname() + "," + $3->getname(), "arg");
		  }
	      | logic_expression
	      {
				outlog << "At line no: " << lines << " arguments : logic_expression " << endl << endl;
				outlog << $1->getname() << endl << endl;
				pair<string, string> param($1->getname(), $1->get_data_type());
				current_func_params.push_back(param);
				$$ = new symbol_info($1->getname(), "arg");
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout << "Please input file name" << endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("22101088_22101357_log.txt", ios::trunc);
	errlog.open("22101088_22101357_error.txt", ios::trunc);

	if(yyin == NULL)
	{
		cout << "Couldn't open file" << endl;
		return 0;
	}

	table = new symbol_table(10, &outlog);
	table->enter_scope();
	
	yyparse();
	
	table->print_all_scopes();
	
	delete table;
	
	outlog << endl << "Total lines: " << lines << endl;
	outlog << "Total errors: " << error_count << endl;

	errlog << "Total errors: " << error_count << endl;
	outlog.close();
	errlog.close();
	fclose(yyin);
	
	return 0;
}
